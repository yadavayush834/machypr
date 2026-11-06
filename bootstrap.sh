#!/usr/bin/env bash
# Download first, then run: sudo and interactive prompts retain the terminal.
set -Eeuo pipefail
command -v curl >/dev/null || { echo 'Install curl first: sudo pacman -Syu curl' >&2; exit 1; }
repo=yadavayush834/arch-hyprland-dotfiles
ref=${ARCH_RICE_REF:-main}
[[ $ref =~ ^[a-zA-Z0-9._-]+$ ]] || { echo 'Invalid ARCH_RICE_REF' >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
curl --fail --location --retry 3 "https://codeload.github.com/$repo/tar.gz/$ref" -o "$tmp/source.tar.gz"
mkdir "$tmp/source"
tar -xzf "$tmp/source.tar.gz" --strip-components=1 -C "$tmp/source"
bash "$tmp/source/install.sh" "$@"
