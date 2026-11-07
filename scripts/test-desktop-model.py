#!/usr/bin/env python3
"""Rename shortcuts and symlinks without changing installed apps or linked folders."""
from pathlib import Path
import configparser
import os
import runpy
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parent.parent
model=runpy.run_path(str(ROOT/'home/.local/bin/macos-desktop-model'))

class DesktopTests(unittest.TestCase):
 def test_rename_shortcut_preserves_launch_command(self):
  with tempfile.TemporaryDirectory() as folder:
   desktop=Path(folder);p=desktop/'Browser.desktop'
   p.write_text('[Desktop Entry]\nType=Application\nName=Browser\nName[fr]=Navigateur\nExec=/usr/bin/browser --new-window %U\nIcon=browser\n');p.chmod(0o755)
   name=model['rename_item'](desktop,p.name,'My Browser')
   self.assertEqual(name,'My Browser.desktop');data=configparser.ConfigParser(interpolation=None);data.read(desktop/name)
   self.assertEqual(data['Desktop Entry']['Name'],'My Browser');self.assertEqual(data['Desktop Entry']['Exec'],'/usr/bin/browser --new-window %U')
   self.assertFalse(p.exists());self.assertTrue(os.access(desktop/name,os.X_OK))
 def test_rename_symlink_preserves_target(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);desktop=root/'Desktop';desktop.mkdir();target=root/'Documents';target.mkdir();(target/'important.txt').write_text('keep')
   (desktop/'Documents').symlink_to(target,target_is_directory=True)
   model['rename_item'](desktop,'Documents','Files')
   self.assertEqual((desktop/'Files').resolve(),target);self.assertEqual((target/'important.txt').read_text(),'keep')
 def test_invalid_and_colliding_names(self):
  with tempfile.TemporaryDirectory() as folder:
   desktop=Path(folder);(desktop/'A').write_text('a');(desktop/'B').write_text('b')
   for label in ('','..','../escape','A\nB','B'):
    with self.assertRaises(ValueError):model['rename_item'](desktop,'A',label)
   self.assertEqual((desktop/'A').read_text(),'a');self.assertEqual((desktop/'B').read_text(),'b')
 def test_remove_link_moves_only_shortcut_to_trash(self):
  with tempfile.TemporaryDirectory(dir=Path.home(),prefix='.machypr-trash-test-') as folder:
   root=Path(folder);desktop=root/'Desktop';desktop.mkdir();target=root/'Actual Folder';target.mkdir();(target/'keep').write_text('safe')
   (desktop/'Link').symlink_to(target,target_is_directory=True)
   code='import runpy,sys; runpy.run_path(sys.argv[1])["remove_item"](sys.argv[2],"Link")'
   subprocess.run([sys.executable,'-c',code,str(ROOT/'home/.local/bin/macos-desktop-model'),str(desktop)],env=dict(os.environ,XDG_DATA_HOME=str(root/'data')),check=True)
   self.assertFalse((desktop/'Link').is_symlink());self.assertEqual((target/'keep').read_text(),'safe')
   self.assertTrue(any((root/'data/Trash/files').iterdir()))

if __name__=='__main__':unittest.main()
