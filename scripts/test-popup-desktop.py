#!/usr/bin/env python3
"""Optional live-session regression check: outside click closes a layer popup.

Run from a Hyprland session with the desktop helpers installed. This briefly
opens a calendar and delivers a GTK pointer-press event to its outside surface.
It does not inject a physical mouse click or alter the current workspace.
"""
from pathlib import Path
import runpy
import sys
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

original_main = Gtk.main
outcome = {}

def checked_main():
    def check():
        try:
            windows = {window.get_name(): window for window in Gtk.Window.list_toplevels()}
            backdrop = windows['macos-menu-dismiss']
            width, height = backdrop.get_allocated_width(), backdrop.get_allocated_height()
            assert width > 300 and height > 200
            event = Gdk.Event.new(Gdk.EventType.BUTTON_PRESS)
            event.button, event.x, event.y = 1, width / 2, height - 50
            outcome['handled'] = backdrop.emit('button-press-event', event)
        except Exception as error:
            outcome['error'] = repr(error)
            Gtk.main_quit()
        return False
    GLib.timeout_add(600, check)
    GLib.timeout_add(2500, lambda: (Gtk.main_quit(), False)[1])
    original_main()

Gtk.main = checked_main
sys.argv = ['macos-menu', 'calendar']
runpy.run_path(str(Path.home() / '.local/bin/macos-menu'), run_name='__main__')
assert outcome.get('handled'), outcome
print('Outside pointer press closed the popup without Escape.')
