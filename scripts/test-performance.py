#!/usr/bin/env python3
"""Verify priority restoration, stale-state recovery and background-work deferral."""
from pathlib import Path
import json
import os
import runpy
import tempfile
import unittest
ROOT=Path(__file__).resolve().parent.parent
m=runpy.run_path(str(ROOT/'home/.local/bin/macos-responsiveness'))
cache=runpy.run_path(str(ROOT/'home/.local/bin/macos-app-cache'))
class Fake:
 def __init__(self):self.weights={'app.slice':100,'app-test.scope':100,'app-other.scope':200}
 def get(self,unit):return self.weights[unit]
 def set(self,unit,weight):self.weights[unit]=weight
class TestPerformance(unittest.TestCase):
 def test_restore_on_focus_and_stop(self):
  with tempfile.TemporaryDirectory() as directory:
   b=Fake();p=m['Policy'](b,Path(directory)/'weights.json')
   p.focus({'app.slice','app-test.scope'});self.assertEqual(b.weights['app-test.scope'],300)
   p.focus({'app-other.scope'});self.assertEqual(b.weights['app-test.scope'],100);self.assertEqual(b.weights['app.slice'],100)
   p.close();self.assertEqual(b.weights['app-other.scope'],200)
 def test_stale_restore(self):
  with tempfile.TemporaryDirectory() as directory:
   path=Path(directory)/'weights.json';path.write_text(json.dumps({'app-test.scope':100}))
   b=Fake();b.weights['app-test.scope']=300;p=m['Policy'](b,path);self.assertEqual(b.weights['app-test.scope'],100);p.close()
 def test_preserve_higher_existing_weight(self):
  with tempfile.TemporaryDirectory() as directory:
   b=Fake();b.weights['app-test.scope']=800;p=m['Policy'](b,Path(directory)/'weights.json');p.focus({'app-test.scope'});self.assertEqual(b.weights['app-test.scope'],800);p.close()
 def test_profile_priority_is_reversible(self):
  with tempfile.TemporaryDirectory() as directory:
   b=Fake();p=m['Policy'](b,Path(directory)/'weights.json',1000);p.focus({'app-test.scope'})
   self.assertEqual(b.weights['app-test.scope'],1000);p.close();self.assertEqual(b.weights['app-test.scope'],100)
 def test_skip_user_manager_and_compositor(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);p=root/'42';p.mkdir();base=f'0::/user.slice/user-{os.getuid()}.slice/user@{os.getuid()}.service'
   (p/'cgroup').write_text(base+'\n');self.assertIsNone(m['cgroup_unit'](42,root))
   (p/'cgroup').write_text(base+'/session.slice/wayland-wm@hyprland.desktop.service\n');self.assertIsNone(m['cgroup_unit'](42,root))
   (p/'cgroup').write_text(base+'/app.slice/app-one.scope\n');self.assertEqual(m['cgroup_unit'](42,root)[0],'app-one.scope')
 def test_warmup_defers_under_pressure(self):
  with tempfile.TemporaryDirectory() as directory:
   root=Path(directory);proc=root/'proc';(proc/'pressure').mkdir(parents=True);thermal=root/'thermal';thermal.mkdir()
   for name in ('cpu','io','memory'):(proc/'pressure'/name).write_text('some avg10=0.00 avg60=0 total=0\nfull avg10=0.00 avg60=0 total=0\n')
   self.assertIsNone(cache['pressure_reason'](proc,thermal))
   (proc/'pressure/io').write_text('full avg10=8.00 avg60=1 total=0\n')
   self.assertEqual(cache['pressure_reason'](proc,thermal),'io pressure')
   (proc/'pressure/io').write_text('full avg10=0.00 avg60=0 total=0\n')
   zone=thermal/'thermal_zone0';zone.mkdir();(zone/'type').write_text('x86_pkg_temp');(zone/'temp').write_text('95000')
   self.assertEqual(cache['pressure_reason'](proc,thermal),'CPU temperature')
 def test_related_flatpak_process_groups(self):
  self.assertEqual(m['related_units']('app-flatpak-com.brave.Browser-1.scope',{'app-flatpak-com.brave.Browser-2.scope','app-other.scope'}),{'app-flatpak-com.brave.Browser-1.scope','app-flatpak-com.brave.Browser-2.scope'})
if __name__=='__main__':unittest.main()
