#!/usr/bin/env python3
"""Verify mode persistence, schedules and actual file changes in an isolated home."""
from pathlib import Path
import configparser
import json
import runpy
import shutil
import tempfile
from unittest.mock import patch
root=Path(__file__).resolve().parent.parent
module=runpy.run_path(str(root/'home/.local/bin/macos-appearance'))
assert module['resolve']('auto',6)=='dark'
assert module['resolve']('auto',7)=='light'
assert module['resolve']('auto',18)=='light'
assert module['resolve']('auto',19)=='dark'

def contrast(a,b):
    def luminance(value):
        channels=[int(value[i:i+2],16)/255 for i in (1,3,5)]
        return sum(weight*(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4)
                   for weight,v in zip((.2126,.7152,.0722),channels))
    light,dark=sorted([luminance(a),luminance(b)],reverse=True)
    return (light+.05)/(dark+.05)

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
        colors=dict(line.split(maxsplit=1) for line in (home/'.config/kitty/wallpaper-colors.conf').read_text().splitlines())
        assert all('color'+str(i) in colors for i in range(16))
        assert colors['text_fg_override_threshold']=='4.5 ratio'
        assert colors['dim_opacity']=='1' and colors['background_opacity']=='1'
        for key in ['foreground','url_color',*[f'color{i}' for i in range(1,16)]]:
            assert contrast(colors[key],colors['background'])>=4.5,(mode,key)
        kde=configparser.ConfigParser();kde.read(home/'.config/kdeglobals')
        rgbhex=lambda text:'#'+''.join(f'{int(v):02x}' for v in text.split(','))
        for role in ('Window','View','Button','Tooltip','Selection'):
            section=kde['Colors:'+role]
            bg=rgbhex(section['BackgroundNormal'])
            for key in ('ForegroundNormal','ForegroundInactive','ForegroundLink'):
                assert contrast(rgbhex(section[key]),bg)>=4.5,(mode,role,key)
        assert kde['General']['font']=='Inter,11,-1,5,50,0,0,0,0,0'
    # Changing just hyprbars' config leaves old text textures cached. Rebuild
    # decorations through config-only reload on every appearance transition.
    with patch('subprocess.run') as run:
        module['apply']('dark',home,session=True)
        assert any(call.args[0]==('hyprctl','reload','config-only') for call in run.call_args_list)
print('Appearance switching, complete ANSI palettes, readable Qt roles and title refresh passed.')
