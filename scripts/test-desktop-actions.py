#!/usr/bin/env python3
"""Live context menu, Rename dialog and reversible Trash operations on a disposable item."""
from pathlib import Path
import json
import os
import re
import runpy
import subprocess
import sys
import time
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,Gdk,GLib
home=Path.home();helper=home/'.local/bin/macos-desktop-icons'
subprocess.run(['pkill','-f','^(/usr/bin/)?python(3)? '+re.escape(str(helper))+'$']);time.sleep(.2)
name=f'MacHypr action test {time.time_ns()}.txt';renamed='Renamed '+name
fixture=home/'Desktop'/name;fixture.write_text('Disposable test item\n')
layout=home/'.local/state/macos-desktop/icon-positions.json';saved=layout.read_bytes() if layout.exists() else None
trash=home/'.local/share/Trash';trash_before={p.name for p in (trash/'files').iterdir()} if (trash/'files').exists() else set()
original=Gtk.main;result={}
def main():
 module=sys._getframe(1).f_globals
 def run():
  try:
   event=Gdk.Event.new(Gdk.EventType.BUTTON_PRESS);event.button=3;event.window=module['win'].get_window();event.time=Gdk.CURRENT_TIME
   event.set_device(Gdk.Display.get_default().get_default_seat().get_pointer())
   menu=module['item_menu'](module['items'][name],event,name)
   assert [x.get_label() for x in menu.get_children()]==['Open','Rename…','Move to Trash']
   menu.popdown();menu.destroy()
   def confirm():
    dialog=next(w for w in Gtk.Window.list_toplevels() if isinstance(w,Gtk.Dialog) and w.get_title()=='Rename')
    entry=next(c for c in dialog.get_content_area().get_children() if isinstance(c,Gtk.Entry))
    entry.set_text(renamed);dialog.response(Gtk.ResponseType.OK);return False
   GLib.timeout_add(100,confirm);module['rename_item'](name)
   assert not fixture.exists() and (home/'Desktop'/renamed).read_text()=='Disposable test item\n'
   assert renamed in module['positions']
   module['remove_item'](renamed)
   assert not (home/'Desktop'/renamed).exists()
   assert any(p.name.startswith(renamed) for p in (trash/'files').iterdir())
   result['passed']=True
  except Exception as error:result['error']=repr(error)
  Gtk.main_quit();return False
 GLib.timeout_add(800,run);original()
Gtk.main=main
try:
 runpy.run_path(str(helper),run_name='__main__');assert result.get('passed'),result
 print('Live context menu, Rename dialog, position tracking and Trash removal passed.')
finally:
 fixture.unlink(missing_ok=True);(home/'Desktop'/renamed).unlink(missing_ok=True)
 if saved is None:layout.unlink(missing_ok=True)
 else:layout.write_bytes(saved)
 if (trash/'files').exists():
  for p in (trash/'files').iterdir():
   if p.name not in trash_before and p.name.startswith(renamed):
    p.unlink();(trash/'info'/(p.name+'.trashinfo')).unlink(missing_ok=True)
 subprocess.Popen(['/usr/bin/python',str(helper)],stdout=open('/tmp/machypr-desktop-actions.log','w'),stderr=subprocess.STDOUT,start_new_session=True)
