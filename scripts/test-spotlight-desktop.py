#!/usr/bin/env python3
"""Live Spotlight regression: matching, empty results, keyboard selection and exit."""
from pathlib import Path
import runpy
import subprocess
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,Gdk,GLib
original_main=Gtk.main
errors=[]
def checked_main():
 def check():
  try:
   win=next(w for w in Gtk.Window.list_toplevels() if w.get_name()=='spotlight')
   entry,results,hint=win.get_child().get_children()
   entry.set_text('terminal');entry.emit('search-changed')
   assert results.get_children(),'Terminal search returned no installed applications'
   event=Gdk.Event.new(Gdk.EventType.KEY_PRESS);event.keyval=Gdk.KEY_Down
   assert win.emit('key-press-event',event)
   assert results.get_selected_row() is not None
   while Gtk.events_pending():Gtk.main_iteration_do(False)
   entry.set_text('zzzz-no-such-application');entry.emit('search-changed')
   assert not results.get_children()
   assert hint.get_text()=='No applications found'
   entry.set_text('');entry.emit('search-changed')
   assert hint.get_text()=='Search applications'
   event.keyval=Gdk.KEY_Escape
   assert win.emit('key-press-event',event)
  except Exception as error:
   errors.append(error);Gtk.main_quit()
  return False
 GLib.timeout_add(600,check)
 original_main()
Gtk.main=checked_main
runpy.run_path(str(Path.home()/'.local/bin/macos-spotlight'),run_name='__main__')
assert not errors,errors
print('Spotlight matching, selection, empty state and Escape passed.')
