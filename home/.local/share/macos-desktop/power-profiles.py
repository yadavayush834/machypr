#!/usr/bin/env python3
"""Three verifiable Intel power profiles, with reversible writes and thermal feedback."""
import argparse
import contextlib
import fcntl
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

STATE=Path('/var/lib/macos-power-profiles')
RUNTIME=Path('/run/macos-power-profiles')
HELPER=Path('/usr/local/libexec/macos-power-profile')
SERVICE=Path('/etc/systemd/system/macos-power-profiles.service')
PROFILES={
    'battery-saver':{'title':'Battery Saver','governor':'powersave','epp':'power','turbo':False,'ceiling':60,'target':80,'dynamic':0},
    'standard':{'title':'Standard (Balanced)','governor':'powersave','epp':'balance_performance','turbo':True,'ceiling':100,'target':None,'dynamic':0},
    'performance':{'title':'Performance','governor':'performance','epp':'performance','turbo':True,'ceiling':100,'target':96,'dynamic':1},
}


def read(path,default=None):
    try:return Path(path).read_text().strip()
    except OSError:return default


def load(path,default=None):
    try:return json.loads(Path(path).read_text())
    except (OSError,ValueError):return {} if default is None else default


def atomic(path,value,mode=0o644):
    path=Path(path);temporary=path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value,indent=2)+'\n');temporary.chmod(mode);temporary.replace(path)


def temperature(root=Path('/sys')):
    values=[]
    for zone in (root/'class/thermal').glob('thermal_zone*'):
        if 'pkg_temp' in read(zone/'type',''):
            try:values.append(int(read(zone/'temp'))/1000)
            except (ValueError,TypeError):pass
    return max(values) if values else None


def thermal_cap(profile,current,temp):
    config=PROFILES[profile];ceiling=config['ceiling'];current=min(current,ceiling)
    if profile=='standard':return ceiling
    if temp is None:return current
    emergency_floor=50 if profile=='performance' else 30
    floor=70 if profile=='performance' else 40
    if temp>=98:return max(emergency_floor,current-15)
    if temp>=config['target']:return max(min(floor,current),current-5)
    if temp<=config['target']-(3 if profile=='performance' else 6):return min(ceiling,current+5)
    return current


def controls(root=Path('/sys')):
    base=root/'devices/system/cpu';pstate=base/'intel_pstate'
    result=[]
    for name in ('no_turbo','min_perf_pct','max_perf_pct','hwp_dynamic_boost'):
        if (pstate/name).exists():result.append(pstate/name)
    for policy in sorted((base/'cpufreq').glob('policy*')):
        for name in ('scaling_governor','energy_performance_preference'):
            if (policy/name).exists():result.append(policy/name)
    for card in (root/'class/drm').glob('card[0-9]*'):
        for name in ('gt_max_freq_mhz','gt_boost_freq_mhz'):
            if (card/name).exists():result.append(card/name)
    return result


def plan(profile,cap=None,root=Path('/sys')):
    config=PROFILES[profile];pstate=root/'devices/system/cpu/intel_pstate'
    if read(pstate/'status')!='active':raise RuntimeError('These hardware profiles require active intel_pstate; this CPU driver is not supported.')
    updates=[]
    def add(path,value):
        if path.exists():updates.append((path,str(value)))
    # Keep idle states available. Never change voltage, RAPL limits, fan control or RAM timings.
    minimum=int(read(pstate/'min_perf_pct','0'))
    cap=max(minimum,min(config['ceiling'],config['ceiling'] if cap is None else cap))
    add(pstate/'max_perf_pct',cap);add(pstate/'no_turbo',0 if config['turbo'] else 1)
    add(pstate/'hwp_dynamic_boost',config['dynamic'])
    policies=sorted((root/'devices/system/cpu/cpufreq').glob('policy*'))
    if not policies:raise RuntimeError('No CPU policies were found.')
    for policy in policies:
        if config['governor'] not in read(policy/'scaling_available_governors','').split():raise RuntimeError('The requested CPU governor is unavailable.')
        add(policy/'scaling_governor',config['governor'])
        epp=policy/'energy_performance_preference'
        if epp.exists():
            if config['epp'] not in read(policy/'energy_performance_available_preferences','').split():raise RuntimeError('The requested CPU energy preference is unavailable.')
            add(epp,config['epp'])
    for card in (root/'class/drm').glob('card[0-9]*'):
        maximum=read(card/'gt_RP0_freq_mhz');minimum=read(card/'gt_min_freq_mhz')
        if maximum and minimum:
            maximum=int(maximum)
            if profile=='battery-saver':maximum=max(int(minimum),maximum//2//50*50)
            add(card/'gt_max_freq_mhz',maximum);add(card/'gt_boost_freq_mhz',maximum)
    return updates


def restore_values(values):
    # Switch governors first so a non-performance EPP can be restored successfully.
    for name,value in sorted(values.items(),key=lambda pair:0 if pair[0].endswith('scaling_governor') else 1):
        path=Path(name)
        if path.exists() and read(path)!=value:path.write_text(value)


def apply(profile,cap=None,root=Path('/sys')):
    updates=plan(profile,cap,root);previous={str(path):read(path) for path in controls(root)};changed=[]
    try:
        for path,value in updates:
            if read(path)!=value:path.write_text(value);changed.append(str(path))
        for path,value in updates:
            if read(path)!=value:raise RuntimeError('Hardware did not accept '+str(path))
    except Exception:
        restore_values(previous);raise
    return changed


@contextlib.contextmanager
def locked():
    STATE.mkdir(parents=True,exist_ok=True)
    RUNTIME.mkdir(parents=True,exist_ok=True)
    with (RUNTIME/'lock').open('w') as stream:
        fcntl.flock(stream,fcntl.LOCK_EX);yield


def snapshot(root=Path('/sys')):
    selection=load(STATE/'selected.json');report=load(RUNTIME/'status.json')
    policies=[]
    for policy in sorted((root/'devices/system/cpu/cpufreq').glob('policy*')):
        policies.append({'name':policy.name,'governor':read(policy/'scaling_governor'),'epp':read(policy/'energy_performance_preference'),'frequency_khz':read(policy/'scaling_cur_freq')})
    pstate=root/'devices/system/cpu/intel_pstate'
    count=root/'devices/system/cpu/cpu0/thermal_throttle/package_throttle_count'
    return {'installed':HELPER.exists() and SERVICE.exists(),'selected':selection.get('profile'),
            'policies':policies,'cpu_limit_percent':read(pstate/'max_perf_pct'),'turbo':read(pstate/'no_turbo')=='0',
            'dynamic_boost':read(pstate/'hwp_dynamic_boost'),'temperature':temperature(root),
            'throttle_count':read(count),'controller':report,
            'supported':read(pstate/'status')=='active','profile_definitions':PROFILES}


def update(profile,cap):
    changed=apply(profile,cap)
    atomic(RUNTIME/'status.json',{'profile':profile,'cap':cap,'temperature':temperature(),'updated':time.time(),'changed':changed})


def set_profile(profile):
    with locked():
        if not (STATE/'baseline.json').exists():atomic(STATE/'baseline.json',{str(p):read(p) for p in controls()},0o600)
        cap=thermal_cap(profile,PROFILES[profile]['ceiling'],temperature())
        update(profile,cap);atomic(STATE/'selected.json',{'profile':profile})
    print(json.dumps(snapshot()))


def daemon():
    running=[True]
    for sig in (signal.SIGTERM,signal.SIGINT):signal.signal(sig,lambda *_:running.__setitem__(0,False))
    selected=None;cap=100
    while running[0]:
        try:
            with locked():
                profile=load(STATE/'selected.json').get('profile')
                if profile not in PROFILES:raise RuntimeError('No valid profile is selected.')
                status=load(RUNTIME/'status.json')
                if profile!=selected:cap=status.get('cap',PROFILES[profile]['ceiling']);selected=profile
                cap=thermal_cap(profile,cap,temperature());update(profile,cap)
        except Exception as error:
            print('Power profile controller:',error,flush=True)
            atomic(RUNTIME/'status.json',{'error':str(error),'updated':time.time()})
        for _ in range(6):
            if not running[0]:break
            time.sleep(.5)


def install():
    if read(Path('/sys/devices/system/cpu/intel_pstate/status'))!='active':raise RuntimeError('This hardware does not support these Intel power profiles.')
    if subprocess.run(['systemctl','is-active','--quiet','power-profiles-daemon.service']).returncode==0:raise RuntimeError('Power Profiles Daemon is already managing this CPU. Stop it before installing another controller.')
    HELPER.parent.mkdir(parents=True,exist_ok=True)
    source=Path(__file__).resolve()
    if source!=HELPER:shutil.copyfile(source,HELPER)
    HELPER.chmod(0o755)
    SERVICE.write_text('''[Unit]
Description=Verified power profiles with CPU thermal feedback
After=multi-user.target

[Service]
ExecStart=/usr/bin/python -I /usr/local/libexec/macos-power-profile --daemon
Restart=on-failure
RestartSec=3
UMask=0022
NoNewPrivileges=yes
PrivateTmp=yes
ProtectHome=yes
ProtectSystem=full

[Install]
WantedBy=multi-user.target
''')
    set_profile(load(STATE/'selected.json').get('profile','standard'))
    subprocess.run(['systemctl','daemon-reload'],check=True)
    subprocess.run(['systemctl','enable','--now','macos-power-profiles.service'],check=True)
    subprocess.run(['systemctl','restart','macos-power-profiles.service'],check=True)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group();group.add_argument('--status',action='store_true');group.add_argument('--plan',choices=PROFILES);group.add_argument('--set',choices=PROFILES);group.add_argument('--install',action='store_true');group.add_argument('--daemon',action='store_true');group.add_argument('--restore',action='store_true')
    args=parser.parse_args()
    if args.plan:print(json.dumps([(str(p),v) for p,v in plan(args.plan)],indent=2));return
    if not any((args.set,args.install,args.daemon,args.restore)):print(json.dumps(snapshot()));return
    if os.geteuid()!=0:raise SystemExit('Administrator authentication is required for CPU and GPU controls.')
    os.umask(0o022)
    if args.install:install()
    elif args.set:
        if not HELPER.exists():raise RuntimeError('Install power profiles from Settings first.')
        set_profile(args.set)
        subprocess.run(['systemctl','enable','--now','macos-power-profiles.service'],check=True)
    elif args.daemon:daemon()
    elif args.restore:
        subprocess.run(['systemctl','disable','--now','macos-power-profiles.service'],check=True)
        with locked():
            baseline=load(STATE/'baseline.json');allowed={str(p) for p in controls()}
            if not baseline or not set(baseline)<=allowed:raise RuntimeError('The saved hardware baseline is invalid.')
            restore_values(baseline)
            (STATE/'selected.json').unlink(missing_ok=True);(RUNTIME/'status.json').unlink(missing_ok=True)
        print('Original hardware settings restored; profile controller stopped.')


if __name__=='__main__':
    try:main()
    except Exception as error:raise SystemExit(str(error))
