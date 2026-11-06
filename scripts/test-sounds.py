#!/usr/bin/env python3
"""Check disabled playback and repeat suppression without playing audio."""
from pathlib import Path
import json
import os
import runpy
import tempfile
from unittest.mock import patch
module=runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-sound'))
with tempfile.TemporaryDirectory() as directory:
    home=Path(directory)
    module['play'].__globals__['HOME']=home
    configuration=home/'.config/macos-desktop/sounds.json';configuration.parent.mkdir(parents=True)
    sound=home/'.local/share/sounds/MacDesktop/stereo/notification.wav';sound.parent.mkdir(parents=True);sound.write_bytes(b'fixture')
    with patch.dict(os.environ,{'XDG_RUNTIME_DIR':str(home),'DUNST_SUMMARY':''}),patch('subprocess.Popen') as playback,patch('shutil.which',return_value='/usr/bin/pw-play'):
        configuration.write_text(json.dumps({'enabled':False,'volume':.35}));module['play']('notification');playback.assert_not_called()
        configuration.write_text(json.dumps({'enabled':True,'volume':.35}));module['play']('notification');assert playback.call_count==1
        module['play']('notification');assert playback.call_count==1
        assert playback.call_args.args[0][2]=='0.35'
print('Sound enable/disable, bounded effects volume and repeat suppression passed.')
