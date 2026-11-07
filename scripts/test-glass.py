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
 assert "hl.plugin.load(library)" in config.read_text()
 assert "MACOS_DISABLE_PLUGINS" in config.read_text()
 assert "renderer and hl.plugin.hyprglass" in config.read_text()
 assert "refraction_strength=0.8" in config.read_text()
 assert "opacity=0.92" in config.read_text()
 assert "fullscreen=true" in config.read_text()
 assert m['renderer_status'](home,session=False)['renderer']=='frosted-fallback'
 m['apply'](False,home,session=False)
 assert not m['enabled'](home)
 assert 'hl.config' not in config.read_text()
 assert 'hl.layer_rule' not in config.read_text()
 (home/'.config/macos-desktop/glass.json').write_text('invalid')
 assert not m['enabled'](home)
print('Refractive glass configuration, guarded fallback, fullscreen exclusion and complete disable passed.')
