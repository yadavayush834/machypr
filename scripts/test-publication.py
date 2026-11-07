#!/usr/bin/env python3
"""Ensure the publication policy rejects personal repairs and private data."""
from pathlib import Path
import runpy
import unittest
check=runpy.run_path(str(Path(__file__).with_name('check-publication.py')))['violations']
class PublicationTests(unittest.TestCase):
    def test_key_repairs_are_rejected(self):
        self.assertTrue(check('examples/laptop/disable-f11.lua'))
        self.assertTrue(check('home/.config/hypr/disable-f12.lua'))
    def test_runtime_and_auth_are_rejected(self):
        for name in ['home/.codex/auth.json','home/.local/state/usage.sqlite3','.env','private/notes.txt']:
            self.assertTrue(check(name),name)
    def test_portable_templates_are_allowed(self):
        self.assertFalse(check('home/.config/hypr/hyprland.lua','hl.monitor({scale="auto"})'))
        self.assertFalse(check('home/.local/share/applications/app.desktop','Exec=@HOME@/.local/bin/app'))
    def test_personal_scale_and_paths_are_rejected(self):
        self.assertTrue(check('home/test.conf','QT_SCALE_FACTOR=1.5'))
        self.assertTrue(check('home/test.conf','Exec=/home/example/.local/bin/app'))
    def test_credentials_are_rejected(self):
        self.assertTrue(check('notes.txt','ghp_'+'a'*36))
        self.assertTrue(check('notes.txt','-----BEGIN '+'OPENSSH PRIVATE KEY-----'))
if __name__=='__main__':unittest.main()
