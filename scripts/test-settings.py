#!/usr/bin/env python3
"""Persistence, validation and backend error regression checks without changing the session."""
from pathlib import Path
import json
import runpy
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parent.parent
model=runpy.run_path(str(ROOT/'home/.local/bin/macos-settings-model'))
wallpapers=runpy.run_path(str(ROOT/'home/.local/bin/macos-wallpapers'))

class SettingsTests(unittest.TestCase):
 def test_options_merge_and_persist(self):
  with tempfile.TemporaryDirectory() as folder:
   home=Path(folder)
   model['set_option']('repeat_rate',37,home,False)
   model['set_option']('tap_to_click',False,home,False)
   self.assertEqual(json.loads((home/'.config/macos-desktop/settings.json').read_text()),{'repeat_rate':37,'tap_to_click':False})
   lua=(home/'.config/hypr/settings-overrides.lua').read_text()
   self.assertIn('repeat_rate=37',lua);self.assertIn('touchpad={tap_to_click=false}',lua)
 def test_invalid_options_do_not_write(self):
  with tempfile.TemporaryDirectory() as folder:
   home=Path(folder)
   for key,value in [('kb_layout','us"});os.execute("bad'),('repeat_rate',999),('animations','false'),('unknown',True)]:
    with self.assertRaises(ValueError):model['set_option'](key,value,home,False)
   self.assertFalse((home/'.config/macos-desktop/settings.json').exists())
 def test_timeout_preserves_other_listeners(self):
  with tempfile.TemporaryDirectory() as folder:
   home=Path(folder);p=home/'.config/hypr/hypridle.conf';p.parent.mkdir(parents=True)
   original='general {\n lock_cmd = hyprlock\n}\nlistener {\n timeout = 600\n on-timeout = loginctl lock-session\n}\nlistener {\n timeout = 1800\n on-timeout = systemctl suspend\n}\n'
   p.write_text(original);model['set_lock_timeout'](300,home,False)
   self.assertEqual(model['lock_timeout'](home),300)
   self.assertIn('timeout = 1800',p.read_text());self.assertEqual(p.with_suffix('.conf.before-settings').read_text(),original)
 def test_dock_preferences_merge(self):
  with tempfile.TemporaryDirectory() as folder:
   home=Path(folder)
   model['set_dock']('auto_hide',False,home)
   model['set_dock']('size',40,home)
   self.assertEqual(model['dock_preferences'](home),{'auto_hide':False,'magnification':True,'size':40})
   with self.assertRaises(ValueError):model['set_dock']('size',100,home)
 def test_command_errors_are_reported(self):
  with self.assertRaisesRegex(RuntimeError,'not installed'):model['command']('machypr-nonexistent-command')
 def test_catalog_uses_pinned_originals(self):
  entries=wallpapers['catalog'](Path('/nonexistent'))
  self.assertEqual(len(entries),22);self.assertEqual(len({e['id'] for e in entries}),22)
  for e in entries:
   self.assertIn('fae15d0c4fc58790bc93de33699e0adbb0ca987f',e['url']);self.assertFalse(e['installed'])
 def test_wallpaper_validation_and_persistence(self):
  from PIL import Image
  with tempfile.TemporaryDirectory() as folder:
   home=Path(folder);image=home/'custom.jpg';Image.new('RGB',(64,64),'blue').save(image)
   wallpapers['apply'](image,home,False)
   self.assertEqual(wallpapers['current'](home),str(image))
   with self.assertRaises(ValueError):wallpapers['apply'](home/'missing.jpg',home,False)

if __name__=='__main__':unittest.main()
