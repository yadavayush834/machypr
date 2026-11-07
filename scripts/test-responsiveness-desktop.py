#!/usr/bin/env python3
"""Live test: focusing disposable app scopes changes and restores their CPU weights."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

if len(sys.argv)>1 and sys.argv[1]=='--fixture':
 import gi
 gi.require_version('Gtk','3.0')
 from gi.repository import Gtk
 win=Gtk.Window(title='Disposable priority test '+sys.argv[2]);win.add(Gtk.Label(label='Testing foreground priority; closes automatically.'));win.connect('destroy',Gtk.main_quit);win.show_all();Gtk.main();raise SystemExit

def query():return json.loads(subprocess.check_output(['hyprctl','clients','-j']))
def weight(unit):
 raw=subprocess.check_output(['systemctl','--user','show',unit,'-p','CPUWeight','--value'],text=True).strip()
 return 100 if raw=='[not set]' else int(raw)
def wait_for(predicate,timeout=5):
 end=time.monotonic()+timeout
 while time.monotonic()<end:
  if predicate():return
  time.sleep(.1)
 raise AssertionError('Priority transition timed out.')
previous=json.loads(subprocess.check_output(['hyprctl','activewindow','-j'])).get('address')
units=[f'app-macos-focus-{os.getpid()}-{name}.scope' for name in ('a','b')];script=str(Path(__file__).resolve());windows=[]
try:
 for index,unit in enumerate(units):
  subprocess.Popen(['systemd-run','--user','--scope','--quiet','--collect','--slice=app.slice','--unit='+unit,sys.executable,script,'--fixture',str(index)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 wait_for(lambda:len([w for w in query() if w['title'].startswith('Disposable priority test')])==2)
 windows=sorted([w for w in query() if w['title'].startswith('Disposable priority test')],key=lambda w:w['title'])
 for index,window in enumerate(windows):
  code='hl.dsp.focus({window='+json.dumps('address:'+window['address'])+'})'
  assert subprocess.check_output(['hyprctl','dispatch',code],text=True).strip()=='ok'
  wait_for(lambda:weight(units[index])==300)
  if index:wait_for(lambda:weight(units[index-1])==100)
 subprocess.run(['systemctl','--user','stop','macos-responsiveness.service'],check=True)
 assert all(weight(unit)==100 for unit in units)
 print('Live focus changes, background restoration and stop-time restoration passed.')
finally:
 for unit in units:subprocess.run(['systemctl','--user','stop',unit],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 if previous:subprocess.run(['hyprctl','dispatch','hl.dsp.focus({window='+json.dumps('address:'+previous)+'})'],stdout=subprocess.DEVNULL)
 subprocess.run(['systemctl','--user','start','macos-responsiveness.service'],check=True)
