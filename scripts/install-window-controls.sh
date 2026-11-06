#!/usr/bin/env bash
# Build the official decoration plugin against this machine's Hyprland ABI.
set -Eeuo pipefail
revision=d2427d4d15b36df40468f5a58bbd67cdba19835d
version=$(pkg-config --modversion hyprland)
case "$version" in
 0.57.*) ;;
 *) echo "Window controls source supports Hyprland 0.57.x; found $version. Update the plugin revision before rebuilding." >&2; exit 1;;
esac
for tool in git make g++; do
 command -v "$tool" >/dev/null || { echo "Missing build dependency: $tool" >&2; exit 1; }
done
pkg-config --exists hyprland pixman-1 pangocairo libdrm
build=$(mktemp -d)
trap 'python3 -c "import shutil,sys;shutil.rmtree(sys.argv[1])" "$build"' EXIT
git -C "$build" init -q
git -C "$build" remote add origin https://github.com/hyprwm/hyprland-plugins.git
git -C "$build" fetch --depth=1 origin "$revision"
git -C "$build" checkout --detach FETCH_HEAD
make -C "$build/hyprbars" -j2
destination="$HOME/.local/lib/macos-desktop"
mkdir -p "$destination"
install -m755 "$build/hyprbars/hyprbars.so" "$destination/.hyprbars.so.new"
mv -f "$destination/.hyprbars.so.new" "$destination/hyprbars.so"
echo 'Installed desktop-wide traffic lights. Reload Hyprland, or log in again after a Hyprland upgrade.'
