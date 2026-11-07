#!/usr/bin/env python3
"""Reject personal machine configuration and common credentials before publication."""
from pathlib import Path
import re
import io
import tarfile
import subprocess
import sys

ROOT=Path(__file__).resolve().parent.parent
BLOCKED_PATHS=[
 r'^(?:local|private|reports)/',
 r'^examples/(?:laptop|codex)/',
 r'^system/etc/systemd/(?:logind|sleep)\.conf\.d/',
 r'^home/\.config/hypr/(?:disable-f\d+|settings-overrides|display-settings)\.lua$',
 r'^home/\.(?:codex|var)/',
 r'^home/\.config/(?:Codex|discord|spotify)/',
 r'^home/\.local/state/',
 r'(?:^|/)(?:\.env(?:\..*)?|auth\.json|credentials\.json)$',
 r'\.(?:key|pem|sqlite3?|db|log|pyc)$',
 r'\.backup(?:-|$)',
 r'^(?:home/\.local/bin/configure-fast-wake|scripts/(?:tune-system-performance|undo-performance-user)\.py)$',
]
SECRETS=[r'-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----',r'gh[pousr]_[A-Za-z0-9]{30,}',r'github_pat_[A-Za-z0-9_]{40,}',r'sk-[A-Za-z0-9_-]{40,}']
TEMPLATE_CONTENT=[r'/home/(?!@)[A-Za-z0-9_-]+/',r'cli_auth_credentials_store\s*=',r'switch:off:Lid Switch',r'(?i)faulty.{0,30}key',r'QT_SCALE_FACTOR\s*=\s*[0-9]',r'(?i)\b(?:UUID|PARTUUID)=[0-9a-f]{8}-[0-9a-f-]{8,}']


def violations(name,text=''):
    reasons=[]
    if any(re.search(pattern,name) for pattern in BLOCKED_PATHS):reasons.append('personal/runtime file path')
    if any(re.search(pattern,text) for pattern in SECRETS):reasons.append('credential pattern')
    if name.startswith('home/') and any(re.search(pattern,text) for pattern in TEMPLATE_CONTENT):reasons.append('machine-specific template content')
    return reasons


def main():
    if len(sys.argv)==3 and sys.argv[1]=='--revision':
        archive=subprocess.check_output(['git','archive',sys.argv[2]],cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as files:
            entries=[(entry.name,files.extractfile(entry).read()) for entry in files if entry.isfile()]
    else:
        names=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z'],cwd=ROOT).decode().split('\0')
        entries=[(name,(ROOT/name).read_bytes()) for name in sorted(set(names)) if name and (ROOT/name).is_file()]
    problems=[];count=0
    for name,raw in entries:
        count+=1
        text='' if b'\0' in raw else raw.decode('utf-8',errors='replace')
        for reason in violations(name,text):problems.append(f'{name}: {reason}')
    if problems:
        print('Publication guard rejected these files:\n'+'\n'.join(problems));return 1
    print(f'Publication guard passed ({count} source files checked).');return 0

if __name__=='__main__':sys.exit(main())
