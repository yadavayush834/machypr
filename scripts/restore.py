#!/usr/bin/env python3
"""Restore configuration files only. Keep applications and user projects."""
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


def restore(backup):
    home = Path.home()
    manifest = json.loads((backup/'manifest.json').read_text())
    if manifest['home'] != str(home):
        raise SystemExit('This backup belongs to a different home directory')
    # Validate the complete manifest before making changes.
    for entry in manifest['files']:
        path = Path(entry['path'])
        if path.is_absolute() or '..' in path.parts:
            raise SystemExit('Invalid backup manifest path')
        if entry['existed'] and not os.path.lexists(backup/'files'/path):
            raise SystemExit(f'Missing backup file: {path}')
    for entry in reversed(manifest['files']):
        target = home / entry['path']
        if entry['existed']:
            target.parent.mkdir(parents=True, exist_ok=True)
            fd, temporary = tempfile.mkstemp(prefix='.arch-restore-', dir=target.parent)
            os.close(fd)
            os.unlink(temporary)
            try:
                shutil.copy2(backup/'files'/entry['path'], temporary, follow_symlinks=False)
                os.replace(temporary, target)
            finally:
                if os.path.lexists(temporary):
                    os.unlink(temporary)
        elif target.exists() or target.is_symlink():
            target.unlink()
    settings = backup / 'gsettings.json'
    if settings.exists():
        import subprocess
        if shutil.which('gsettings') and os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
            for entry in json.loads(settings.read_text()):
                subprocess.run(['gsettings', 'set', entry['schema'], entry['key'], entry['value']], check=True)
        else:
            print('Restore GSettings from gsettings.json after logging into a desktop session.')
    print(f'Restored configuration from {backup}. Log out and back in to restore the desktop session.')


if __name__ == '__main__':
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] in ('-h', '--help')):
        print('Usage: arch-rice-restore [backup-directory]\nWithout an argument, restores the most recent installer backup.')
        sys.exit(0)
    latest = Path.home()/'.local/state/arch-hyprland-dotfiles/latest-backup'
    backup = Path(sys.argv[1]) if len(sys.argv) == 2 else Path(latest.read_text().strip())
    restore(backup)
