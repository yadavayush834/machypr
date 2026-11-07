#!/usr/bin/env python3
"""Read-only native settings smoke test. Requires a running Hyprland desktop."""
from pathlib import Path
import json
import os
import runpy
import subprocess
import sys
import tempfile
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,GLib
ROOT=Path(__file__).resolve().parent.parent
namespace=runpy.run_path(str(ROOT/'home/.local/bin/macos-settings'))
app=namespace['Settings']();app.set_application_id('org.machypr.Settings.Test')
app.register(None);app.activate()
loop=GLib.MainLoop();errors=[];pages=iter(namespace['PAGES']);tested=[]
original=app.error
app.error=lambda error:(errors.append((app.current_page,str(error))),original(error))
captures=Path(os.environ.get('MACHYPR_SETTINGS_CAPTURES','/tmp/machypr-settings-captures'));captures.mkdir(parents=True,exist_ok=True)
def capture(page):
 try:
  clients=json.loads(subprocess.check_output(['hyprctl','clients','-j']))
  window=next(w for w in clients if w['pid']==os.getpid())
  x,y=window['at'];w,h=window['size']
  subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(captures/(page+'.png'))],check=True)
 except Exception as e:errors.append(('capture',str(e)))
 return False
def next_page():
 try:page=next(pages)[0]
 except StopIteration:
  # Search must find category keywords and report empty results.
  app.search.set_text('volume');app.search_changed();assert 'volume' in app.nav_rows['sound'].keywords
  app.first_result();assert app.current_page=='sound'
  app.search.set_text('no-such-settings-xyz');app.search_changed();assert app.no_results.get_visible()
  app.search.set_text('');app.search_changed();assert not app.no_results.get_visible()
  app.go(-1);assert app.history_index<len(app.history)-1
  print('Rendered all',len(tested),'settings pages; search and history passed.',flush=True)
  print('Page errors:',errors,flush=True)
  app.window.destroy();app.stop();loop.quit();return False
 app.open_page(page);tested.append(page)
 started=GLib.get_monotonic_time()
 def settled():
  pending=[f for g,f in app.jobs if g==app.generation and not f.done()]
  if pending and (GLib.get_monotonic_time()-started)<25_000_000:return True
  if pending:errors.append((page,'Settings did not finish loading within 25 seconds.'))
  assert app.scroller.get_vadjustment().get_value()==0,(page,'Page did not start at top')
  if page in ('appearance','wallpaper','keyboard','general','sound','wifi'):capture(page)
  GLib.timeout_add(250,next_page)
  return False
 GLib.timeout_add(200,settled)
 return False
GLib.timeout_add(200,next_page)
try:loop.run()
finally:
 app.stop()
assert not errors,errors
