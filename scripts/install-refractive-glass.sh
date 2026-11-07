#!/usr/bin/env bash
# Build a pinned HyprGlass revision against the installed Hyprland headers.
set -Eeuo pipefail
revision=dc00c628623e5e504b363e26dd489ee766d2fa12
version=$(pkg-config --modversion hyprland)
case "$version" in
 0.57.1) ;;
 *) echo "Refractive glass source supports Hyprland 0.57.1; found $version. Re-pin and rebuild for another version." >&2; exit 1;;
esac
for tool in git make g++ wayland-scanner; do
 command -v "$tool" >/dev/null || { echo "Missing build dependency: $tool" >&2; exit 1; }
done
pkg-config --exists hyprland pixman-1 libdrm wayland-server
build=$(mktemp -d)
trap 'python3 -c "import shutil,sys;shutil.rmtree(sys.argv[1])" "$build"' EXIT
git -C "$build" init -q
git -C "$build" remote add origin https://github.com/hyprnux/hyprglass.git
git -C "$build" fetch --depth=1 origin "$revision"
git -C "$build" checkout --detach FETCH_HEAD
make -C "$build" -j2
folder="$HOME/.local/lib/macos-desktop"
mkdir -p "$folder"
install -m755 "$build/hyprglass.so" "$folder/.hyprglass.so.new"
mv -f "$folder/.hyprglass.so.new" "$folder/hyprglass.so"
install -m644 "$build/LICENSE" "$folder/LICENSE-HyprGlass"
python3 - "$folder" "$revision" "$version" <<'PY'
import hashlib,json,sys
from pathlib import Path
folder=Path(sys.argv[1])
(folder/'hyprglass-build.json').write_text(json.dumps({'revision':sys.argv[2],'hyprland':sys.argv[3],'sha256':hashlib.sha256((folder/'hyprglass.so').read_bytes()).hexdigest()},indent=2)+'\n')
PY
echo 'Installed HyprGlass. Enable it with macos-glass on. Rebuild after Hyprland updates.'
