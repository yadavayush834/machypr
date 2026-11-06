#!/usr/bin/env python3
"""Verify workspace isolation, live moves and restoration of minimized dock windows."""
from pathlib import Path
import runpy

model=runpy.run_path(str(Path(__file__).resolve().parent.parent/'home/.local/bin/macos-dock-model'))
select=model['workspace_apps']
target=model['activation_target']

def window(address,classname,workspace,rank=1):
    return {'address':address,'class':classname,'mapped':True,'focusHistoryID':rank,
            'workspace':{'id':workspace,'name':str(workspace)}}

local=window('local','kitty',1)
remote=window('remote','kitty',2,0)
unknown=window('new-app','org.example.UnpinnedApp',1)
windows=[local,remote,unknown]
origins={}
groups=select(windows,1,origins)
assert set(groups)=={'kitty','org.example.UnpinnedApp'}
assert groups['kitty']==[local]  # Same app elsewhere must never win activation.
assert target(groups['kitty']) is local
assert select(windows,2,origins)=={'kitty':[remote]}

local['workspace']={'id':-99,'name':'special:minimized'}
assert select(windows,1,origins)['kitty']==[local]
assert select(windows,2,origins)['kitty']==[remote]
local['workspace']={'id':2,'name':'2'}
assert 'kitty' not in select(windows,1,origins)
assert target(select(windows,2,origins)['kitty']) is remote
assert target(select(windows,2,origins)['kitty'],'remote') is local
local['workspace']={'id':-99,'name':'special:minimized'}
assert 'kitty' not in select(windows,1,origins)
assert select(windows,2,origins)['kitty']==[local,remote]

unknown['mapped']=False
assert select(windows,1,origins)=={}
assert select([],1,origins)=={} and origins=={}
assert target([]) is None
print('Dock workspace filtering, unpinned apps, local activation, moves and minimized ownership passed.')

named=window('named','kitty',1)
named['workspace']={'address':'design','name':'design'}
origins={}
assert select([named],'design',origins)=={'kitty':[named]}
named['workspace']={'name':'special:minimized'}
assert select([named],'design',origins)=={'kitty':[named]}
assert select([named],'other',origins)=={}
print('Named desktops without numeric IDs preserve dock and minimized ownership.')
