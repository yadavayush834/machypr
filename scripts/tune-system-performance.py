#!/usr/bin/env python3
"""Apply reviewed HDD responsiveness and on-demand /boot configuration, with root backups."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess

RULE=Path('/etc/udev/rules.d/60-macos-interactive-disk.rules')
SYSCTL=Path('/etc/sysctl.d/60-macos-interactive-io.conf')


def boot_automount(text):
    result=[];changed=False
    for line in text.splitlines(keepends=True):
        if not line.strip() or line.lstrip().startswith('#'):result.append(line);continue
        parts=line.split()
        if len(parts)>=6 and parts[1]=='/boot' and parts[2]=='vfat':
            options=parts[3].split(',')
            if 'x-systemd.automount' not in options:
                options=[o for o in options if o!='auto']+['noauto','x-systemd.automount']
                parts[3]=','.join(dict.fromkeys(options));line='\t'.join(parts)+'\n';changed=True
        result.append(line)
    return ''.join(result),changed


def plan():
    return {'files':[str(RULE),str(SYSCTL),'/etc/fstab'],
            'disk':'BFQ and 512 KiB read-ahead on BFQ-capable rotational disks only',
            'writeback':'64 MiB background / 256 MiB synchronous dirty-page thresholds',
            'boot':'On-demand /boot mount; preserve current mounted filesystem; takes effect next boot',
            'unchanged':['CPU governor/turbo','zram','OOM policy','kernel/security options','network services','animations']}


def apply():
    if os.geteuid()!=0:raise SystemExit('Administrator authentication is required. Use pkexec /usr/bin/python -I this-script --apply.')
    backup=Path('/var/lib/macos-performance-backups')/datetime.datetime.now().strftime('%Y%m%d-%H%M%S');backup.mkdir(parents=True,mode=0o700)
    files={};runtime={}
    for path in (RULE,SYSCTL,Path('/etc/fstab')):
        files[str(path)]={'existed':path.exists()}
        if path.exists():
            saved=backup/path.relative_to('/');saved.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,saved)
    for key in ('dirty_background_bytes','dirty_bytes','dirty_background_ratio','dirty_ratio'):
        runtime['vm.'+key]=Path('/proc/sys/vm'/Path(key)).read_text().strip()
    disks=[]
    for disk in Path('/sys/block').iterdir():
        scheduler=disk/'queue/scheduler';read_ahead=disk/'queue/read_ahead_kb'
        try:
            if (disk/'queue/rotational').read_text().strip()!='1' or 'bfq' not in [v.strip('[]') for v in scheduler.read_text().split()]:continue
            old=next(w.strip('[]') for w in scheduler.read_text().split() if w.startswith('['))
            disks.append({'path':str(disk),'scheduler':old,'read_ahead_kb':read_ahead.read_text().strip()})
        except OSError:continue
    (backup/'manifest.json').write_text(json.dumps({'files':files,'runtime':runtime,'disks':disks},indent=2)+'\n')
    try:
        RULE.parent.mkdir(parents=True,exist_ok=True)
        RULE.write_text('# Favor interactive I/O on rotational disks; do not affect SSDs.\nACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}=="*bfq*", ATTR{queue/scheduler}="bfq", ATTR{queue/read_ahead_kb}="512"\n')
        SYSCTL.write_text('# Bound writeback bursts on a rotational desktop disk.\nvm.dirty_background_bytes = 67108864\nvm.dirty_bytes = 268435456\n')
        fstab=Path('/etc/fstab');new,changed=boot_automount(fstab.read_text())
        if changed:
            temporary=fstab.with_suffix('.macos-performance.tmp');temporary.write_text(new);temporary.chmod(0o644);temporary.replace(fstab)
        subprocess.run(['findmnt','--verify','--tab-file','/etc/fstab'],check=True)
        subprocess.run(['sysctl','-p',str(SYSCTL)],check=True)
        for disk in disks:
            path=Path(disk['path']);(path/'queue/scheduler').write_text('bfq');(path/'queue/read_ahead_kb').write_text('512')
        subprocess.run(['udevadm','control','--reload'],check=True)
        subprocess.run(['systemctl','daemon-reload'],check=True)
        # Do not unmount /boot or restart the desktop while the user is working.
    except Exception:
        undo(backup)
        raise
    print(json.dumps({'backup':str(backup),'changed_boot':changed,'disks':[d['path'] for d in disks],'plan':plan()},indent=2))


def undo(backup):
    if os.geteuid()!=0:raise SystemExit('Administrator authentication is required.')
    backup=Path(backup).resolve();root=Path('/var/lib/macos-performance-backups').resolve()
    if backup.parent!=root:raise SystemExit('Choose a backup directory directly under '+str(root))
    manifest=json.loads((backup/'manifest.json').read_text())
    for name,info in manifest['files'].items():
        path=Path(name)
        if path not in (RULE,SYSCTL,Path('/etc/fstab')):raise SystemExit('Unexpected backup path.')
        if info['existed']:shutil.copy2(backup/path.relative_to('/'),path)
        else:path.unlink(missing_ok=True)
    # Restore ratios last only when they were originally active.
    for key,value in manifest['runtime'].items():
        if key.endswith('_ratio') and value=='0':continue
        subprocess.run(['sysctl','-w',key+'='+value],check=True)
    for disk in manifest['disks']:
        path=Path(disk['path'])
        if path.parent!=Path('/sys/block'):raise SystemExit('Unexpected disk path.')
        (path/'queue/scheduler').write_text(disk['scheduler']);(path/'queue/read_ahead_kb').write_text(disk['read_ahead_kb'])
    subprocess.run(['udevadm','control','--reload'],check=True);subprocess.run(['systemctl','daemon-reload'],check=True)
    print('Restored system performance configuration from',backup)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--apply',action='store_true');parser.add_argument('--undo');args=parser.parse_args()
    if args.apply:apply()
    elif args.undo:undo(args.undo)
    else:print(json.dumps(plan(),indent=2))
