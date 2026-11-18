#!/usr/bin/env bash
# orchard installer: themes (MacTahoe GTK/icons/cursors/Kvantum by vinceliuice),
# Tahoe wallpapers, then switches the desktop. User-level only, no sudo
# except for missing packages.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
pkgs=(hyprland quickshell qt6-5compat qt6-svg qt6-shadertools hyprlock hypridle hyprsunset hyprpicker foot
      kvantum qt6ct inter-font ttf-jetbrains-mono-nerd noto-fonts-emoji grim slurp swappy wl-clipboard cliphist
      brightnessctl playerctl jq fd python-pillow networkmanager nm-connection-editor bluez blueman pavucontrol
      power-profiles-daemon upower dolphin)
missing=(); for p in "${pkgs[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
((${#missing[@]})) && sudo pacman -S --needed "${missing[@]}"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for r in MacTahoe-gtk-theme MacTahoe-icon-theme MacTahoe-kde; do
  git clone -q --depth 1 "https://github.com/vinceliuice/$r" "$tmp/$r"
done
mkdir -p ~/.themes ~/.local/share/icons ~/.config/Kvantum/MacTahoe ~/.config/Kvantum/MacTahoeDark
for t in MacTahoe-Dark MacTahoe-Light; do tar -xf "$tmp/MacTahoe-gtk-theme/release/$t.tar.xz" -C ~/.themes; done
bash "$tmp/MacTahoe-icon-theme/install.sh" -d ~/.local/share/icons >/dev/null
cp -r "$tmp/MacTahoe-icon-theme/cursors/dist" ~/.local/share/icons/MacTahoe-cursors
cp "$tmp"/MacTahoe-kde/Kvantum/MacTahoe/MacTahoe.* ~/.config/Kvantum/MacTahoe/
cp "$tmp"/MacTahoe-kde/Kvantum/MacTahoe/MacTahoeDark.* ~/.config/Kvantum/MacTahoeDark/
cp "$tmp"/MacTahoe-gtk-theme/wallpaper/MacTahoe-{day,night}.jpeg "$here/config/orchard/wallpapers/"
"$here/orchard-switch" orchard
