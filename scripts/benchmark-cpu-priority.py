#!/usr/bin/env python3
"""Brief contention test of real cgroup CPU allocation; uses only disposable user services."""
import json
import os
from pathlib import Path
import subprocess
import time

cpu=min(os.sched_getaffinity(0));names=[f'app-macos-qos-{os.getpid()}-{x}.service' for x in ('a','b')]
code='import time\nend=time.monotonic()+15\nx=1\nwhile time.monotonic()<end:\n for _ in range(5000):x=(x*17+3)%10000019\n'
def run(*args):return subprocess.check_output(args,text=True).strip()
def pid(unit):return int(run('systemctl','--user','show',unit,'-p','MainPID','--value'))
def ticks(pid):
 parts=(Path('/proc')/str(pid)/'stat').read_text().split(') ',1)[1].split();return int(parts[11])+int(parts[12])
def measure(pids):
 before=[ticks(p) for p in pids];time.sleep(2);after=[ticks(p) for p in pids];return [a-b for a,b in zip(after,before)]
try:
 for name in names:
  run('systemd-run','--user','--quiet','--collect','--unit='+name,'--slice=app.slice','--property=CPUWeight=100','taskset','-c',str(cpu),'/usr/bin/python','-c',code)
 time.sleep(.4);pids=[pid(name) for name in names];equal=measure(pids)
 run('systemctl','--user','set-property','--runtime',names[1],'CPUWeight=300');weighted=measure(pids)
 result={'cpu':cpu,'equal_weights_cpu_ticks':equal,'foreground_weight_300_cpu_ticks':weighted,'weighted_b_to_a_ratio':round(weighted[1]/max(1,weighted[0]),2)}
 print(json.dumps(result,indent=2))
 assert all(v>0 for v in equal+weighted)
 assert weighted[1]>weighted[0]*1.5, 'Relative CPU allocation did not respond as expected.'
finally:
 for name in names:subprocess.run(['systemctl','--user','stop',name],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
