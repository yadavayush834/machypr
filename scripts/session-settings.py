#!/usr/bin/env python3
"""Back up and activate the desktop's small set of GSettings preferences."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

if not os.environ.get('DBUS_SESSION_BUS_ADDRESS') or not shutil.which('gsettings'):
    print('Session preferences deferred: log in and select WhiteSur-Dark in Appearance.')
    raise SystemExit(0)
backup = Path(sys.argv[1]) / 'gsettings.json'
interface = 'org.gnome.desktop.interface'
values = [('org.gnome.desktop.sound', 'theme-name', 'MacDesktop'),
          ('org.gnome.desktop.sound', 'event-sounds', 'true'),
          ('org.gnome.desktop.sound', 'input-feedback-sounds', 'false'), (interface, 'gtk-theme', 'WhiteSur-Dark'),
          (interface, 'icon-theme', 'WhiteSur'),
          (interface, 'cursor-theme', 'WhiteSur-cursors'),
          (interface, 'font-name', 'Inter 11'),
          (interface, 'color-scheme', 'prefer-dark'),
          ('org.gnome.desktop.wm.preferences', 'button-layout', 'close,minimize,maximize:')]
previous = [{'schema': schema, 'key': key,
             'value': subprocess.check_output(['gsettings', 'get', schema, key], text=True).strip()}
            for schema, key, _ in values]
backup.write_text(json.dumps(previous, indent=2) + '\n')
for schema, key, value in values:
    subprocess.run(['gsettings', 'set', schema, key, value], check=True)
