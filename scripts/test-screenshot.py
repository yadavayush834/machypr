#!/usr/bin/env python3
"""Exercise canceled selections and clipboard-only capture without desktop input."""
from pathlib import Path
import runpy
import subprocess
import tempfile
from unittest.mock import patch
module=runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-screenshot'))
with tempfile.TemporaryDirectory() as directory:
    destination=Path(directory)/'screenshots'
    with patch('subprocess.run',return_value=subprocess.CompletedProcess(['slurp'],1,stdout='',stderr='')) as call:
        assert module['capture']('region',directory=destination) is None
        assert not destination.exists()
        assert call.call_count==1
    with patch('subprocess.check_output',return_value=b'PNG fixture') as capture,patch('subprocess.run') as command,patch('shutil.which',return_value=None):
        result=module['capture']('screen',clipboard_only=True,directory=destination)
        assert result=='Copied to clipboard'
        assert not destination.exists()
        assert capture.call_args.args[0]==['grim','-']
        assert any(call.args[0]==['wl-copy','--type','image/png'] and call.kwargs['input']==b'PNG fixture' for call in command.call_args_list)
print('Screenshot cancellation and clipboard-only behavior passed.')
