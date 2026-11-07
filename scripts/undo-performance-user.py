#!/usr/bin/env python3
"""Restore user performance files from a recorded backup and stop focus weighting."""
import json
from pathlib import Path
import shutil
import subprocess
import sys
home=Path.home()
backup=Path(sys.argv[1]).resolve()
if backup.parent!=(home/'.local/state/macos-performance/user-backup').resolve():raise SystemExit('Choose a backup directly under ~/.local/state/macos-performance/user-backup.')
manifest=json.loads((backup/'manifest.json').read_text())
subprocess.run(['systemctl','--user','disable','--now','macos-responsiveness.service'],check=False)
for relative,existed in manifest['files'].items():
 path=Path(relative)
 if path.is_absolute() or '..' in path.parts:raise SystemExit('Invalid backup path.')
 target=home/path
 if existed:target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(backup/path,target)
 else:target.unlink(missing_ok=True)
subprocess.run(['systemctl','--user','daemon-reload'],check=True)
subprocess.run(['systemctl','--user','set-property','--runtime','background.slice','CPUWeight='+str(manifest['background_cpu_weight'])],check=True)
print('Restored user performance settings. System disk/boot settings have their separate root rollback.')
