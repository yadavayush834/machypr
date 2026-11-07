#!/usr/bin/env python3
"""Authenticated readback test of all profiles; always return to the initial selection."""
import json
import os
from pathlib import Path
import runpy
import time

if os.geteuid()!=0:raise SystemExit('Run with pkexec /usr/bin/python -I this-script.')
P=runpy.run_path('/usr/local/libexec/macos-power-profile')
original=P['load'](P['STATE']/'selected.json').get('profile','standard')
reports=[]
try:
    for profile in ('battery-saver','performance','standard'):
        P['set_profile'](profile)
        time.sleep(.5)
        status=P['snapshot']();config=P['PROFILES'][profile]
        assert status['selected']==profile,status
        assert all(p['governor']==config['governor'] and p['epp']==config['epp'] for p in status['policies']),status
        assert status['turbo']==config['turbo'],status
        assert status['dynamic_boost']==str(config['dynamic']),status
        reports.append({'profile':profile,'governor':status['policies'][0]['governor'],'epp':status['policies'][0]['epp'],
                        'turbo':status['turbo'],'dynamic_boost':status['dynamic_boost'],'cap':status['cpu_limit_percent'],
                        'temperature':status['temperature'],'gpu_ceiling_mhz':P['read'](Path('/sys/class/drm/card1/gt_max_freq_mhz'))})
finally:P['set_profile'](original)
print(json.dumps({'verified':reports,'returned_to':original},indent=2))
