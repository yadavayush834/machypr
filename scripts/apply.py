#!/usr/bin/env python3
"""Apply curated templates with a per-file backup; never copy an entire home."""
import datetime
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile


def atomic_write(path, data, mode):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix='.arch-rice-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def apply(root, home, desktop_only=False):
    # Templates embed paths in shell, Lua, JSON and desktop entries.
    # Refuse ambiguous paths rather than producing incorrectly quoted commands.
    import re
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', str(home)):
        raise ValueError('HOME must be an absolute path without spaces or shell metacharacters')
    state = home / '.local/state/arch-hyprland-dotfiles'
    backup = state / 'backups' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup.mkdir(parents=True)
    files = [(p.relative_to(root / 'home'), p.read_bytes(), p.stat().st_mode & 0o777)
             for p in sorted((root / 'home').rglob('*')) if p.is_file()]
    bashrc = home / '.bashrc'
    original = bashrc.read_text() if bashrc.exists() else ''
    fragment = (root / 'shell/bashrc.fragment').read_text()
    start, end = '# >>> arch-hyprland-dotfiles >>>', '# <<< arch-hyprland-dotfiles <<<'
    if start in original:
        before, remainder = original.split(start, 1)
        if end not in remainder:
            raise ValueError('Existing .bashrc has an incomplete managed block; fix it before installing')
        _, after = remainder.split(end, 1)
        content = before.rstrip() + '\n\n' + fragment + after.lstrip('\n')
    else:
        content = original.rstrip() + '\n\n' + fragment
    files.append((Path('.bashrc'), content.encode(), (bashrc.stat().st_mode & 0o777) if bashrc.exists() else 0o644))
    if not desktop_only:
        # Preserve unrelated file associations and include defaults in the backup.
        import configparser
        import io
        mime = home / '.config/mimeapps.list'
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        parser.optionxform = str
        if mime.exists():
            parser.read(mime)
        if not parser.has_section('Default Applications'):
            parser.add_section('Default Applications')
        for kind in ['text/html', 'x-scheme-handler/http', 'x-scheme-handler/https']:
            parser['Default Applications'][kind] = 'com.brave.Browser.desktop;'
        parser['Default Applications']['application/pdf'] = 'org.kde.okular.desktop;'
        buffer = io.StringIO()
        parser.write(buffer)
        files.append((Path('.config/mimeapps.list'), buffer.getvalue().encode(), 0o644))
    # Ship the documentation and offline restore utility with each installation.
    for name in ['README.md', 'LICENSE']:
        files.append((Path('.local/share/arch-setup') / name, (root/name).read_bytes(), 0o644))
    files.append((Path('.local/bin/arch-rice-restore'), (root/'scripts/restore.py').read_bytes(), 0o755))
    manifest = []
    for relative, _, _ in files:
        target = home / relative
        existed = target.exists() or target.is_symlink()
        if existed:
            if target.is_dir() and not target.is_symlink():
                raise ValueError(f'Expected file, found directory: {target}')
            saved = backup / 'files' / relative
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, saved, follow_symlinks=False)
        manifest.append({'path': str(relative), 'existed': existed})
    # Write manifest before any target changes, so even a partial apply is restorable.
    (backup/'manifest.json').write_text(json.dumps({'home':str(home),'files':manifest}, indent=2)+'\n')
    try:
        for relative, data, mode in files:
            # PNG is binary; text templates carry the explicit @HOME@ token.
            if relative.suffix not in ('.png', '.ttf'):
                data = data.replace(b'@HOME@', str(home).encode())
            atomic_write(home/relative, data, mode)
    except BaseException:
        import subprocess
        subprocess.run([sys.executable, str(root/'scripts/restore.py'), str(backup)], check=True)
        raise
    atomic_write(state/'latest-backup', (str(backup)+'\n').encode(), 0o600)
    print(backup)


if __name__ == '__main__':
    apply(Path(sys.argv[1]).resolve(), Path.home(), len(sys.argv) > 2 and sys.argv[2] == "desktop")
