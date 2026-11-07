#!/usr/bin/env python3
"""Glass preference persistence and complete removal of compositor overrides."""
from pathlib import Path
import runpy
import tempfile
m=runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-glass'))
with tempfile.TemporaryDirectory() as directory:
 home=Path(directory)
 assert not m['enabled'](home)
 m['apply'](True,home,session=False)
 assert m['enabled'](home)
 config=home/'.config/hypr/macos-glass.lua'
 assert "bar_blur=true" in config.read_text()
 assert "active_opacity" not in config.read_text()
 m['apply'](False,home,session=False)
 assert not m['enabled'](home)
 assert 'hl.config' not in config.read_text()
 assert 'hl.layer_rule' not in config.read_text()
 (home/'.config/macos-desktop/glass.json').write_text('invalid')
 assert not m['enabled'](home)
print('Glass preference persistence, opaque application content and override removal passed.')
