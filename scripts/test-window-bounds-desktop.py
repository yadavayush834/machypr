#!/usr/bin/env python3
"""Live movement regression: floating windows must remain within their monitor."""
import gi,subprocess,json,os,time
gi.require_version('Gtk','3.0')
from gi.repository import Gtk,GLib
w=Gtk.Window(title='MacHypr screen-boundary test');w.set_default_size(5000,5000);w.show_all();errors=[]
def check():
 try:
  target=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==os.getpid())
  address='address:'+target['address']
  # An oversized client request is bounded by the global size/max_size rules.
  # Explicit resize dispatchers intentionally bypass size hints in Hyprland;
  # pointer resizing and client requests are the constraints under test.
  maximum=subprocess.check_output(['hyprctl','getprop',address,'max_size'],text=True).split()
  max_width,max_height=map(float,maximum)
  assert target['size'][0]<=max_width and target['size'][1]<=max_height
  for x,y in [(-500,-500),(5000,5000)]:
   code='hl.dsp.window.move({window='+json.dumps(address)+',x='+str(x)+',y='+str(y)+'})'
   print(subprocess.check_output(['hyprctl','dispatch',code]).decode().strip(),flush=True)
   time.sleep(.25)
   current=next(c for c in json.loads(subprocess.check_output(['hyprctl','clients','-j'])) if c['pid']==os.getpid())
   monitor=next(m for m in json.loads(subprocess.check_output(['hyprctl','monitors','-j'])) if m['id']==current['monitor'])
   scale=monitor['scale'];left,top=current['at'];width,height=current['size']
   print('requested',x,y,'actual',left,top,'size',width,height,flush=True)
   assert left>=monitor['x'] and top>=monitor['y']
   assert left+width<=monitor['x']+monitor['width']/scale+1
   assert top+height<=monitor['y']+monitor['height']/scale+1
  print('Live off-screen movement constraints passed.',flush=True)
 except Exception as error:errors.append(error)
 w.destroy();Gtk.main_quit();return False
GLib.timeout_add(800,check);Gtk.main()
assert not errors,errors
