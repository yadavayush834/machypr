#!/usr/bin/env python3
"""Live regression for desktop monitoring, free dragging and saved positions."""
from pathlib import Path
import json
import runpy
import subprocess
import sys
import time
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,Gdk,GLib
home=Path.home();helper=home/'.local/bin/macos-desktop-icons'
subprocess.run(['pkill','-f','^/usr/bin/python '+str(helper)+'$']);time.sleep(.25)
original=Gtk.main;outcome={};fixture=home/'Desktop'/'Desktop live test.txt'
layout=home/'.local/state/macos-desktop/icon-positions.json';previous=layout.read_bytes() if layout.exists() else None
assert not fixture.exists()
def main():
 module=sys._getframe(1).f_globals
 def create():fixture.write_text('Desktop refresh check\n');return False
 def verify():
  try:
   items=module['items'];assert fixture.name in items
   assert 'Finder.desktop' in items and 'Downloads' in items
   tile=items[fixture.name];origin=module['positions'][fixture.name][:]
   press=Gdk.Event.new(Gdk.EventType.BUTTON_PRESS);press.button=1;press.x_root=100;press.y_root=100
   tile.emit('button-press-event',press)
   move=Gdk.Event.new(Gdk.EventType.MOTION_NOTIFY);move.state=Gdk.ModifierType.BUTTON1_MASK
   move.x_root=100+213-origin[0];move.y_root=100+179-origin[1]
   assert tile.emit('motion-notify-event',move)
   release=Gdk.Event.new(Gdk.EventType.BUTTON_RELEASE);release.button=1
   assert tile.emit('button-release-event',release)
   assert module['positions'][fixture.name]==[213,179]
   assert json.loads(layout.read_text())[fixture.name]==[213,179]
   module['refresh']();tile=module['items'][fixture.name]
   assert module['canvas'].child_get_property(tile,'x')==213
   assert module['canvas'].child_get_property(tile,'y')==179
   outcome['passed']=True
  except Exception as error:outcome['error']=repr(error)
  Gtk.main_quit();return False
 GLib.timeout_add(200,create);GLib.timeout_add(850,verify);original()
Gtk.main=main
try:
 runpy.run_path(str(helper),run_name='__main__')
 assert outcome.get('passed'),outcome
 print('Live Desktop monitoring, unsnapped dragging and saved position restoration passed.')
finally:
 fixture.unlink(missing_ok=True)
 if previous is None:layout.unlink(missing_ok=True)
 else:layout.write_bytes(previous)
 subprocess.Popen(['bash','-c','sleep 1; exec /usr/bin/python "$1"','desktop-restart',str(helper)],stdout=open('/tmp/macos-desktop-icons-refined.log','w'),stderr=subprocess.STDOUT,start_new_session=True)
