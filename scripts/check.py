#!/usr/bin/env python3
"""Check real portability, repeat-install, backup and restoration behavior."""
import ast
import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import tomllib

root = Path(__file__).resolve().parent.parent
for source in list((root/'scripts').glob('*.py')) + list((root/'home/.local/bin').glob('macos-*')) + list((root/'home/.local/bin').glob('mac-os-*')) + list((root/'home/.local/lib').glob('*.py')):
    if source.suffix==".py" or "python" in source.read_text().splitlines()[0]:
        ast.parse(source.read_text())
for source in (root/'home').rglob('*.json*'):
    json.loads(source.read_text())
tomllib.loads((root/'home/.config/starship.toml').read_text())
for group in (root/'packages').glob('*.txt'):
    names = group.read_text().splitlines()
    assert len(names) == len(set(names)), f'Duplicate package in {group}'
    assert all(name and not any(c.isspace() for c in name) for name in names)
for source in (root/'home').rglob('*'):
    if source.is_file() and source.suffix not in ('.png', '.ttf', '.pyc'):
        text = source.read_text()
        assert '/home/ayush' not in text, source
        assert 'Welcome back, Ayush' not in text, source
        assert 'aurora' not in text.lower(), source

with tempfile.TemporaryDirectory(prefix='arch-rice-test-') as temporary:
    home = Path(temporary)/'different-user'
    home.mkdir()
    env = dict(os.environ, HOME=str(home))
    # An existing personal Bash setup, unrelated associations and a symlink
    # must survive the full apply/restore lifecycle byte-for-byte.
    bashrc = b'# personal configuration\nalias mine="echo preserve-me"\n'
    (home/'.bashrc').write_bytes(bashrc)
    mime = home/'.config/mimeapps.list'
    mime.parent.mkdir(parents=True)
    original_mime = b'[Default Applications]\nimage/png=my-viewer.desktop;\n'
    mime.write_bytes(original_mime)
    kitty = home/'.config/kitty/kitty.conf'
    kitty.parent.mkdir(parents=True)
    original = home/'original-kitty.conf'
    original.write_text('personal theme\n')
    kitty.symlink_to(original)
    before = sorted(str(p.relative_to(home)) for p in home.rglob('*'))
    plan = subprocess.check_output(['bash',str(root/'install.sh'),'--dry-run'],env=env,text=True)
    assert 'PLAN ONLY' in plan
    assert before == sorted(str(p.relative_to(home)) for p in home.rglob('*'))
    result = subprocess.run(['bash',str(root/'install.sh'),'--invalid-flag'],env=env,capture_output=True)
    assert result.returncode == 2
    def apply():
        return Path(subprocess.check_output(['python3',str(root/'scripts/apply.py'),str(root)],env=env,text=True).strip())
    first = apply()
    assert not kitty.is_symlink()
    assert original.read_text() == 'personal theme\n'
    assert 'image/png = my-viewer.desktop;' in mime.read_text()
    assert 'application/pdf = org.kde.okular.desktop;' in mime.read_text()
    assert 'alias mine=' in (home/'.bashrc').read_text()
    assert (home/'.bashrc').read_text().count('# >>> arch-hyprland-dotfiles >>>') == 1
    assert str(home) in (home/'.config/hypr/hyprpaper.conf').read_text()
    bar = json.loads((home/'.config/waybar/config.jsonc').read_text())
    assert 'hyprland/workspaces' not in bar['modules-left']
    assert 'custom/apple' in bar['modules-left']
    assert f'@import url("{home}/.local/share/themes/MacTahoe-Dark/gtk-4.0/gtk.css")' in (home/'.config/gtk-4.0/gtk.css').read_text()
    assert (home/'.local/lib/macos_launcher_session.py').exists()
    assert (home/'.local/bin/macos-dock').stat().st_mode & 0o111
    for source in (root/'home').rglob('*'):
        if source.is_file() and source.suffix not in ('.png', '.ttf', '.pyc'):
            target=home/source.relative_to(root/'home')
            assert '@HOME@' not in target.read_text(), target
    if shutil.which('desktop-file-validate'):
        for desktop in (home/'.local/share/applications').glob('*.desktop'):
            subprocess.run(['desktop-file-validate',str(desktop)],check=True)
    # A repeat apply must not duplicate Bash integration. Restore the second
    # backup to the first installation, then the first backup to originals.
    second = apply()
    assert first != second
    assert (home/'.bashrc').read_text().count('# >>> arch-hyprland-dotfiles >>>') == 1
    subprocess.run([str(home/'.local/bin/arch-rice-restore'),str(second)],env=env,check=True)
    subprocess.run([str(home/'.local/bin/arch-rice-restore'),str(first)],env=env,check=True)
    assert (home/'.bashrc').read_bytes() == bashrc
    assert mime.read_bytes() == original_mime
    assert kitty.is_symlink() and kitty.resolve() == original
    assert original.read_text() == 'personal theme\n'
    assert not (home/'.config/hypr/hyprland.lua').exists()
    assert not (home/'.local/bin/arch-rice-restore').exists()
print('Validated templates, no-op preview, portable paths, repeat installation, MIME merge and symlink-safe restoration.')
