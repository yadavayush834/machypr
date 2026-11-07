import json
from pathlib import Path
import runpy
import tempfile
from unittest.mock import patch
import subprocess

script=str(Path(__file__).resolve().parent.parent/'home/.local/bin/mac-os-session')
scenarios=[
 ('clean logout', [True], [0], False, 0),
 ('bad normal config', [False, True], [0], True, 0),
 ('compositor crash', [True, True], [-11, 0], True, 0),
 ('both configs invalid', [False, False], [], False, 1),
 ('recovery also crashes', [True, True], [-11, -11], True, 139),
]
for title, validations, exits, expect_recovery, expected in scenarios:
 with tempfile.TemporaryDirectory() as tmp:
  home=Path(tmp)
  (home/'.local/share/startup-tuning').mkdir(parents=True)
  (home/'.local/share/startup-tuning/plugin-baseline.json').write_text('{}')
  checks=iter(validations)
  results=iter(exits)
  launched=[]
  def verify(args,**kwargs):
   ok=next(checks)
   return subprocess.CompletedProcess(args,0 if ok else 1,b'config ok' if ok else b'parse error')
  class FakeChild:
   def __init__(self,args,**kwargs):
    launched.append(args)
    self.status=next(results)
   def wait(self): return self.status
   def poll(self): return self.status
  with patch('pathlib.Path.home',return_value=home), patch('subprocess.run',side_effect=verify), patch('subprocess.Popen',FakeChild), patch('signal.signal'), patch('sys.argv',[script]):
   try: runpy.run_path(script,run_name='__main__')
   except SystemExit as e: actual=e.code
  assert actual==expected,(title,actual,expected)
  recovery=any('mac-os-recovery.lua' in str(x) for x in launched)
  assert recovery==expect_recovery,(title,launched)
  assert len(launched)<=2,(title,'restart loop')
  print('PASS:',title)

for scenario in ['display ready', 'startup timeout']:
 with tempfile.TemporaryDirectory() as tmp:
  home=Path(tmp)
  (home/'.local/share/startup-tuning').mkdir(parents=True)
  (home/'.local/share/startup-tuning/plugin-baseline.json').write_text('{}')
  lock=home/'runtime/hypr/test'
  lock.mkdir(parents=True)
  (lock/'hyprland.lock').write_text('12345\nwayland-2\n')
  class RunningChild:
   pid=12345
   def __init__(self,*args,**kwargs): self.stopped=False
   def poll(self): return -15 if self.stopped else None
   def wait(self,timeout=None): return -15 if self.stopped else 0
   def terminate(self): self.stopped=True
   def kill(self): self.stopped=True
  class IPC:
   def __init__(self,*args): pass
   def __enter__(self): return self
   def __exit__(self,*args): pass
   def settimeout(self,*args): pass
   def connect(self,*args): pass
   def sendall(self,*args): pass
   def recv(self,*args): return b'[{}]' if scenario=='display ready' else b'[]'
  with patch('pathlib.Path.home',return_value=home), patch.dict('os.environ',{'XDG_RUNTIME_DIR':str(home/'runtime')}), patch('subprocess.run',return_value=subprocess.CompletedProcess([],0,b'config ok')), patch('subprocess.Popen',RunningChild), patch('signal.signal'), patch('socket.socket',IPC), patch('time.monotonic',side_effect=[0,46,0,46] if scenario=='startup timeout' else [0]), patch('sys.argv',[script]):
   try: runpy.run_path(script,run_name='__main__')
   except SystemExit as e: result=e.code
  assert result==(124 if scenario=='startup timeout' else 0),(scenario,result)
  events=(home/'.local/state/mac-os/last-session.json').read_text()
  assert ('Display ready.' in events) if scenario=='display ready' else ('45 seconds' in events)
  print('PASS:',scenario)
