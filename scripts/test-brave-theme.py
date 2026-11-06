#!/usr/bin/env python3
"""Protect browser data while selecting native GTK window controls."""
from pathlib import Path
import json
import os
import subprocess
import runpy
import tempfile
module=runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-brave-theme'))
with tempfile.TemporaryDirectory() as directory:
    home=Path(directory)
    root=home/'.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser'
    prefs=root/'Default/Preferences';prefs.parent.mkdir(parents=True)
    original={'profile':{'name':'test-user'},'browser':{'other_setting':True}}
    prefs.write_text(json.dumps(original));before=prefs.read_bytes()
    (root/'SingletonLock').symlink_to('test-running-browser')
    assert module['configure'](home) is False
    assert prefs.read_bytes()==before
    (root/'SingletonLock').unlink()
    assert module['configure'](home) is True
    data=json.loads(prefs.read_text())
    assert data['extensions']['theme']['system_theme']==1
    assert data['browser']['custom_chrome_frame'] is True
    assert data['profile']==original['profile'] and data['browser']['other_setting'] is True
    backup=next((home/'.local/state/macos-desktop/browser-backups').glob('*.json'))
    assert backup.read_bytes()==before
    module['configure'](home)
    assert len(list(backup.parent.glob('*.json')))==1
# A desktop mode change must not be pinned by a launch-time GTK_THEME.
with tempfile.TemporaryDirectory() as directory:
    home=Path(directory)
    executables=home/'.local/bin';executables.mkdir(parents=True)
    for name,body in {
        'macos-brave-theme':'#!/bin/sh\nexit 0\n',
        'flatpak':'#!/usr/bin/env python3\nimport json,sys\nprint(json.dumps(sys.argv[1:]))\n',
    }.items():
        command=executables/name;command.write_text(body);command.chmod(0o755)
    launcher=Path(__file__).resolve().parent.parent/'home/.local/bin/brave'
    args=json.loads(subprocess.check_output(
        ['bash',str(launcher),'--new-window','about:blank'],
        env={**os.environ,'HOME':str(home),'PATH':str(executables)+':'+os.environ['PATH'],
             'GTK_THEME':'WhiteSur-Light'},text=True))
    assert '--unset-env=GTK_THEME' in args
    assert '--env=GTK_USE_PORTAL=1' in args
    assert '--gtk-version=3' in args
    assert args[-2:]==['--new-window','about:blank']
print('Brave profile protection, preference preservation, backup and live-theme launcher passed.')
