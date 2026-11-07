#!/usr/bin/env bash
# Add upstream theme resources; settings themselves are managed by apply.py.
set -Eeuo pipefail
cache="${XDG_CACHE_HOME:-$HOME/.cache}/arch-hyprland-dotfiles/themes"
mkdir -p "$cache"
fetch() {
 local name=$1 revision=$2
 local target="$cache/$name-$revision"
 if [[ ! -d "$target" ]]; then
  local tmp
  tmp=$(mktemp -d "$cache/.download-XXXXXX")
  curl --fail --location --retry 3 "https://codeload.github.com/vinceliuice/$name/tar.gz/$revision" -o "$tmp/source.tar.gz"
  mkdir "$tmp/source"
  tar -xzf "$tmp/source.tar.gz" --strip-components=1 -C "$tmp/source"
  mv "$tmp/source" "$target"
  rm -rf -- "$tmp"
 fi
 fetched="$target"
}
for dependency in sassc glib-compile-resources xmllint gtk-update-icon-cache; do
 command -v "$dependency" >/dev/null || { echo "Missing theme dependency: $dependency" >&2; exit 1; }
done
fetch WhiteSur-gtk-theme d5782652d412137e26fb8ff55b55a5572e4c6995
bash "$fetched/install.sh" -d "$HOME/.local/share/themes" -c dark -c light -o normal
fetch WhiteSur-icon-theme 73d8040da51a9ed74e47c7366e7e9ff437601a5c
bash "$fetched/install.sh" -d "$HOME/.local/share/icons"
fetch WhiteSur-cursors e190baf618ed95ee217d2fd45589bd309b37672b
mkdir -p "$HOME/.local/share/icons/WhiteSur-cursors"
cp -a "$fetched/dist/." "$HOME/.local/share/icons/WhiteSur-cursors/"
fetch MacTahoe-gtk-theme 1e45e19f510edb8cde18fa84d6cd5319f60b086b
for variant in Dark Light; do
 tar -xJf "$fetched/release/MacTahoe-$variant.tar.xz" -C "$HOME/.local/share/themes"
 cp "$fetched/COPYING" "$HOME/.local/share/themes/MacTahoe-$variant/COPYING"
done
fetch MacTahoe-icon-theme 839848b9a8a38a92a6936e30c4abe35cc6f2546d
bash "$fetched/install.sh" -d "$HOME/.local/share/icons"
python3 - "$HOME/.local/share/icons" <<'PY'
from pathlib import Path
import sys
for theme in Path(sys.argv[1]).glob('MacTahoe*/index.theme'):
    lines = theme.read_text().splitlines()
    for i, line in enumerate(lines):
        if line.startswith('Inherits=') and 'WhiteSur' not in line.split('=', 1)[1].split(','):
            lines[i] = line.rstrip(',') + ',WhiteSur'
    theme.write_text('\n'.join(lines) + '\n')
PY
echo 'MacTahoe and WhiteSur GTK, icons and cursors installed at pinned upstream revisions.'
