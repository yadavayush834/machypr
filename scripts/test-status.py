#!/usr/bin/env python3
"""Exercise adapter transitions using an isolated sysfs fixture."""
from pathlib import Path
import runpy
import tempfile
import xml.etree.ElementTree as ET
module = runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-status'))
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    def set_file(path, value):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(str(value))
    set_file(root/'BAT0/type', 'Battery')
    set_file(root/'BAT0/capacity', 64)
    set_file(root/'AC/type', 'Mains')
    for status, online, expected in [('Charging',1,'charging'),('Full',1,'full'),('Not charging',1,'plugged'),('Discharging',0,'discharging')]:
        set_file(root/'BAT0/status', status)
        set_file(root/'AC/online', online)
        state = module['battery_state'](root)
        assert state['state'] == expected, state
        assert state['connected'] == bool(online)
        ET.fromstring(module['battery_icon'](state))
    set_file(root/'BAT0/capacity', 7)
    assert '#ff6159' in module['battery_icon'](module['battery_state'](root))
    set_file(root/'BAT0/capacity', 'unavailable')
    assert module['battery_state'](root)['capacity'] is None
    set_file(root/'BAT0/present', 0)
    assert not module['battery_state'](root)['available']
print('Battery charging, full, plugged, discharging, critical and absent states passed.')
