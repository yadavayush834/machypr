#!/usr/bin/env python3
"""Live proof of glass shader output, fullscreen exclusion and screen boundaries."""
from pathlib import Path
import json
import os
import subprocess
import sys
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,Gdk,GLib
from PIL import Image,ImageChops,ImageStat

output=Path(os.environ.get('MACHYPR_GLASS_CAPTURES','/tmp/machypr-glass-captures'));output.mkdir(parents=True,exist_ok=True)
def query(*args):return json.loads(subprocess.check_output(['hyprctl',*args,'-j']))
def dispatch(expression):
 raw=subprocess.check_output(['hyprctl','dispatch',expression],text=True).strip()
 assert raw=='ok',raw
status=query('hyprglass','status');assert status['active'] and status['shaders']=='ready',status
before=query('hyprglass','stats')
previous=query('activewindow').get('address')
background=Gtk.Window(title='Refraction test background');background.set_default_size(700,450)
canvas=Gtk.DrawingArea()
def grid(widget,cr):
 width,height=widget.get_allocated_width(),widget.get_allocated_height()
 cr.set_source_rgb(.92,.94,.98);cr.paint()
 for x in range(0,width,30):
  for y in range(0,height,30):
   if (x//30+y//30)%2==0:cr.set_source_rgb(.12,.38,.72)
   else:cr.set_source_rgb(.9,.38,.18)
   cr.rectangle(x,y,30,30);cr.fill()
 return False
canvas.connect('draw',grid);background.add(canvas);background.show_all()
pane=Gtk.Window(title='Refractive Glass • live shader test');pane.set_name('refraction-test');pane.set_app_paintable(True)
visual=pane.get_screen().get_rgba_visual()
if visual:pane.set_visual(visual)
body=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=14);body.set_border_width(26)
text=Gtk.Label(label='Refractive glass');text.set_xalign(0);body.add(text)
sub=Gtk.Label(label='Live desktop sampling · readable native text');sub.set_xalign(0);body.add(sub)
pane.add(body)
css=Gtk.CssProvider();css.load_from_data(b'window#refraction-test {background:rgba(25,32,45,.30);} #refraction-test label {color:#fff;font:16px Inter;}')
Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),css,Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION+100)
pane.show_all();errors=[];target=[None];monitor=[None]
def client():return next(w for w in query('clients') if w['address']==target[0])
def capture(name):
 window=client();x,y=window['at'];w,h=window['size']
 subprocess.run(['grim','-g',f'{x},{y} {w}x{h}',str(output/(name+'.png'))],check=True)
def tagged(tag):dispatch('hl.dsp.window.tag({window='+json.dumps('address:'+target[0])+',tag='+json.dumps(tag)+'})')
def finish():
 pane.destroy();background.destroy()
 if previous:dispatch('hl.dsp.focus({window='+json.dumps('address:'+previous)+'})')
 Gtk.main_quit();return False
def prepare():
 try:
  clients=[w for w in query('clients') if w['pid']==os.getpid()]
  top=next(w for w in clients if w['title'].startswith('Refractive Glass'));target[0]=top['address']
  monitor[0]=next(m for m in query('monitors') if m['id']==top['monitor'])
  dispatch('hl.dsp.window.resize({window='+json.dumps('address:'+target[0])+',x=480,y=260})')
  dispatch('hl.dsp.window.move({window='+json.dumps('address:'+target[0])+',x=350,y=220})')
  GLib.timeout_add(650,glass_capture)
 except Exception as e:errors.append(e);finish()
 return False
def glass_capture():
 try:capture('refraction-on');tagged('+hyprglass_disabled');GLib.timeout_add(500,plain_capture)
 except Exception as e:errors.append(e);finish()
 return False
def plain_capture():
 try:
  capture('refraction-off')
  a=Image.open(output/'refraction-on.png').convert('RGB');b=Image.open(output/'refraction-off.png').convert('RGB')
  assert a.size==b.size
  delta=sum(ImageStat.Stat(ImageChops.difference(a,b)).mean)/3
  assert delta>1,('No meaningful shader-output difference',delta)
  print('Refraction A/B pixel difference:',round(delta,2),flush=True)
  tagged('-hyprglass_disabled')
  dispatch('hl.dsp.window.fullscreen({window='+json.dumps('address:'+target[0])+',mode="fullscreen"})')
  GLib.timeout_add(500,fullscreen_check)
 except Exception as e:errors.append(e);finish()
 return False
def fullscreen_check():
 try:
  window=client();assert window['fullscreen']!=0
  assert any(t.removesuffix('*')=='hyprglass_disabled' for t in window['tags']),window['tags']
  dispatch('hl.dsp.window.fullscreen({window='+json.dumps('address:'+target[0])+',mode="fullscreen"})')
  GLib.timeout_add(500,complete)
 except Exception as e:errors.append(e);finish()
 return False
def complete():
 try:
  assert not any(t.removesuffix('*')=='hyprglass_disabled' for t in client()['tags'])
  after=query('hyprglass','stats')
  old=sum(m['windowGlassDraws'] for m in before['monitors']);new=sum(m['windowGlassDraws'] for m in after['monitors'])
  assert new>old
  print('GPU glass draws increased; fullscreen exclusion and restoration passed.',flush=True)
 except Exception as e:errors.append(e)
 return finish()
GLib.timeout_add(700,prepare);Gtk.main()
assert not errors,errors
