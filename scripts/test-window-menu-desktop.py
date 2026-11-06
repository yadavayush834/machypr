#!/usr/bin/env python3
"""Optional live-session check: clicking window-menu rows activates that window.

Creates two disposable GTK windows, exercises the actual menu button callbacks,
checks focus and minimized-window restoration, and closes only the test windows.
"""
import json
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import time
import gi

gi.require_version('Gtk','3.0')
from gi.repository import Gtk,GLib

def query(command):return json.loads(subprocess.check_output(['hyprctl',command,'-j']))
def dispatch(code):
    result=subprocess.check_output(['hyprctl','dispatch',code],text=True)
    assert result.strip()=='ok',result

original_workspace=query('activeworkspace')['name']
original_active=query('activewindow').get('address')
original_main=Gtk.main
names=['Window menu click Back','Window menu click Front']
windows=[]
with tempfile.TemporaryDirectory() as directory:
    sample=Path(directory)/'windows.py'
    sample.write_text('''import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk
app=Gtk.Application(application_id='org.example.WindowMenuCheck')
def activate(app):
 for title in ['Window menu click Back','Window menu click Front']:
  window=Gtk.ApplicationWindow(application=app,title=title)
  window.add(Gtk.Label(label=title));window.show_all()
app.connect('activate',activate)
app.run([])
''')
    process=subprocess.Popen(['/usr/bin/python',str(sample)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    try:
        for _ in range(50):
            windows=[w for w in query('clients') if w['title'] in names]
            if len(windows)==2:break
            time.sleep(.1)
        assert len(windows)==2,'Test windows did not open'
        by_title={w['title']:w for w in windows}
        for index,title in enumerate([names[0],names[1],names[0]]):
            selected=by_title[title]
            target=json.dumps('address:'+selected['address'])
            if index==2:
                dispatch('hl.dsp.window.move({window='+target+',workspace="special:minimized",follow=false})')
            outcome={}
            def checked_main():
                def click():
                    def descendants(widget):
                        yield widget
                        if isinstance(widget,Gtk.Container):
                            for child in widget.get_children():yield from descendants(child)
                    menu=next(w for w in Gtk.Window.list_toplevels() if w.get_name()=='macos-menu')
                    button=next(w for w in descendants(menu) if isinstance(w,Gtk.Button) and w.get_accessible().get_name()==title)
                    outcome['clicked']=True;button.emit('clicked');return False
                def attempt():
                    try:return click()
                    except Exception as error:
                        outcome['error']=repr(error);Gtk.main_quit();return False
                timer=GLib.timeout_add(2500,lambda:(Gtk.main_quit(),False)[1])
                GLib.timeout_add(350,attempt)
                original_main();GLib.source_remove(timer)
            Gtk.main=checked_main
            sys.argv=['macos-menu','window']
            runpy.run_path(str(Path.home()/'.local/bin/macos-menu'),run_name='__main__')
            time.sleep(.15)
            assert outcome.get('clicked'),outcome
            assert query('activewindow').get('address')==selected['address'],title
            assert query('activeworkspace')['name']==original_workspace
            assert not any(layer.get('namespace') in ('macos-menu','macos-menu-dismiss')
                           for monitor in query('layers').values() for layers in monitor['levels'].values() for layer in layers)
        print('Window-menu clicks activate overlapping and minimized windows, and release both overlays.')
    finally:
        Gtk.main=original_main
        for window in windows:
            dispatch('hl.dsp.window.close({window='+json.dumps('address:'+window['address'])+'})')
        if not windows:process.terminate()
        dispatch('hl.dsp.focus({workspace='+json.dumps(original_workspace)+'})')
        if original_active:
            dispatch('hl.dsp.focus({window='+json.dumps('address:'+original_active)+'})')
            dispatch('hl.dsp.window.bring_to_top()')
