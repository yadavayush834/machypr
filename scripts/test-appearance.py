#!/usr/bin/env python3
"""Verify mode persistence, schedules and actual file changes in an isolated home."""
from pathlib import Path
import json
import runpy
import shutil
import tempfile
root=Path(__file__).resolve().parent.parent
module=runpy.run_path(str(root/'home/.local/bin/macos-appearance'))
assert module['resolve']('auto',6)=='dark'
assert module['resolve']('auto',7)=='light'
assert module['resolve']('auto',18)=='light'
assert module['resolve']('auto',19)=='dark'
with tempfile.TemporaryDirectory() as directory:
    home=Path(directory)
    for rel in ['.config/gtk-3.0/settings.ini','.config/gtk-4.0/settings.ini','.config/gtk-4.0/gtk-Light.css','.config/gtk-4.0/gtk-Dark.css','.config/wofi/style.css','.config/kdeglobals','.config/Code/User/settings.json']:
        dest=home/rel;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/'home'/rel,dest)
    for mode in ['light','dark','light']:
        module['apply'](mode,home,session=False)
        assert module['preference'](home)['mode']==mode
        assert module['current'](home)==mode
        assert (home/'.config/gtk-4.0/gtk.css').resolve().name==('gtk-Dark.css' if mode=='dark' else 'gtk-Light.css')
        assert ('gtk-application-prefer-dark-theme='+str(int(mode=='dark'))) in (home/'.config/gtk-3.0/settings.ini').read_text()
        assert (home/'.config/wofi/style.css').read_text().count('/* appearance override */')==1
        assert json.loads((home/'.config/Code/User/settings.json').read_text())['workbench.colorTheme']==('Dark Modern' if mode=='dark' else 'Light Modern')
print('Appearance schedule, persistence, GTK switching, editor palette and repeat switching passed.')
