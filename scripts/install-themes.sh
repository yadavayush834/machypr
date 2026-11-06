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
bash "$fetched/install.sh" -d "$HOME/.local/share/themes" -c dark -o normal
fetch WhiteSur-icon-theme 73d8040da51a9ed74e47c7366e7e9ff437601a5c
bash "$fetched/install.sh" -d "$HOME/.local/share/icons"
fetch WhiteSur-cursors e190baf618ed95ee217d2fd45589bd309b37672b
mkdir -p "$HOME/.local/share/icons/WhiteSur-cursors"
cp -a "$fetched/dist/." "$HOME/.local/share/icons/WhiteSur-cursors/"
echo 'WhiteSur GTK, icons and cursors installed at pinned upstream revisions.'
