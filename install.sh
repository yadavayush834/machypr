#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_only=false
desktop_only=false
projects=true
activate=true
dry_run=false
usage() {
 cat <<'HELP'
MacHypr — macOS-inspired Arch Linux / Hyprland desktop installer
Usage: ./install.sh [options]
  --dry-run        Show package groups and target files; change nothing
  --config-only    Apply configuration only (dependencies already installed)
  --desktop-only   Install desktop dependencies and theme, skip apps/dev tools
  --no-projects    Skip generating React and Next.js example projects
  --no-activate    Apply files without explicitly restarting session daemons
  --help           Show this help
Default: install desktop, creative/office apps, Brave, native VS Code,
Node/Python/Rust development tools and example projects; apply the theme.
Run as your regular user. Sudo is used only for the official Arch packages.
HELP
}
for arg in "$@"; do
 case "$arg" in
 --dry-run) dry_run=true;;
 --config-only) config_only=true;;
 --desktop-only) desktop_only=true;;
 --no-projects) projects=false;;
 --no-activate) activate=false;;
 --help|-h) usage; exit 0;;
 *) echo "Unknown option: $arg" >&2; usage >&2; exit 2;;
 esac
done
mapfile -t packages < <(cat "$root/packages/desktop.txt")
if ! $desktop_only; then
 mapfile -t extra < <(cat "$root/packages/development.txt" "$root/packages/apps.txt")
 packages+=("${extra[@]}")
fi
if $dry_run; then
 echo 'PLAN ONLY — no changes'
 if $config_only; then echo 'Skip all package and tool installation.'; else printf 'Official Arch packages: %s\n' "${packages[*]}"; fi
 if ! $config_only && ! $desktop_only; then
  echo 'User installs: Brave (Flathub), native Microsoft VS Code, Rust stable components, Ruff, VS Code extensions.'
  $projects && echo 'Create ~/Projects/react-starter and ~/Projects/next-starter only if absent.'
 fi
 if ! $config_only; then echo 'Install pinned WhiteSur themes and compile matching Hyprland window controls.'; fi
 echo 'Back up overwritten configuration to ~/.local/state/arch-hyprland-dotfiles/backups/.'
 echo 'Apply templates below, plus a managed .bashrc block, documentation and restore utility:'
 (cd "$root/home" && find . -type f | sort)
 echo "Activate running Hyprland session: $activate"
 exit 0
fi
[[ $EUID -ne 0 ]] || { echo 'Run as your regular desktop user, not root.' >&2; exit 1; }
# The templates intentionally use the standard home-directory locations.
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share" XDG_STATE_HOME="$HOME/.local/state"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
. /etc/os-release
[[ ${ID:-} == arch ]] || { echo 'This installer targets Arch Linux. Other distributions are not supported.' >&2; exit 1; }
[[ $(uname -m) == x86_64 ]] || { echo 'The full setup currently supports x86_64 only.' >&2; exit 1; }
[[ $HOME =~ ^/[a-zA-Z0-9_./-]+$ ]] || { echo 'HOME must be absolute without spaces or shell metacharacters.' >&2; exit 1; }
state="$XDG_STATE_HOME/arch-hyprland-dotfiles"
mkdir -p "$state"
exec > >(tee -a "$state/install.log") 2>&1
trap 'echo "Installation stopped at line $LINENO. See $state/install.log. No completion marker was written." >&2' ERR
rm -f "$state/INSTALL-COMPLETE"
if ! $config_only; then
 command -v sudo >/dev/null || { echo 'Install and configure sudo first.' >&2; exit 1; }
 sudo -v
 # Always upgrade with installation: Arch does not support partial upgrades.
 sudo pacman -Syu --needed --noconfirm "${packages[@]}"
fi
command -v python >/dev/null || { echo 'Python is required to back up and apply the templates.' >&2; exit 1; }
version=$(Hyprland --version 2>/dev/null | head -n 1 || true)
# Hyprland 0.57 introduces the Lua configuration used by this snapshot.
python - "$version" <<'PY'
import re,sys
m=re.search(r'(\d+)\.(\d+)\.(\d+)',sys.argv[1])
if not m or tuple(map(int,m.groups())) < (0,57,0):
    sys.exit('Hyprland 0.57+ with Lua configuration support is required. Upgrade before applying.')
PY
if ! $config_only && ! $desktop_only; then
 rustup default stable
 rustup component add rustfmt clippy rust-analyzer
 uv tool install ruff
 flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
 flatpak install --user -y flathub com.brave.Browser
 # Keep a pre-existing native archive installation. Never run Electron as root.
 if [[ ! -x "$HOME/.local/opt/VSCode-linux-x64/bin/code" ]]; then
  temporary=$(mktemp -d)
  trap 'rm -rf -- "$temporary"' EXIT
  curl --fail --location --retry 3 'https://update.code.visualstudio.com/latest/linux-x64/stable' -o "$temporary/code.tar.gz"
  tar -xzf "$temporary/code.tar.gz" -C "$temporary"
  mkdir -p "$HOME/.local/opt"
  [[ ! -e "$HOME/.local/opt/VSCode-linux-x64" ]] || { echo 'Incomplete VS Code installation already exists; move it aside before retrying.' >&2; exit 1; }
  mv "$temporary/VSCode-linux-x64" "$HOME/.local/opt/"
  rm -rf -- "$temporary"
  trap - EXIT
 fi
 "$HOME/.local/opt/VSCode-linux-x64/bin/code" --install-extension dbaeumer.vscode-eslint --install-extension esbenp.prettier-vscode --install-extension ms-python.python --install-extension charliermarsh.ruff --install-extension rust-lang.rust-analyzer --install-extension bradlc.vscode-tailwindcss
 if $projects; then
  mkdir -p "$HOME/Projects"
  if [[ ! -e "$HOME/Projects/react-starter" ]]; then
   (cd "$HOME/Projects" && npm create --yes vite@latest react-starter -- --template react-ts --eslint --no-interactive)
   (cd "$HOME/Projects/react-starter" && npm install)
  fi
  if [[ ! -e "$HOME/Projects/next-starter" ]]; then
   (cd "$HOME/Projects" && npx --yes create-next-app@latest next-starter --ts --tailwind --eslint --app --src-dir --use-npm --import-alias '@/*' --yes)
  fi
 fi
fi
if ! $config_only; then
 bash "$root/scripts/install-themes.sh"
 bash "$root/scripts/install-window-controls.sh"
 python "$root/scripts/install-sounds.py"
 python "$root/home/.local/bin/macos-wallpapers" --install || echo "Some wallpapers could not download; retry from System Settings → Wallpaper."
fi
mode=full
$desktop_only && mode=desktop
backup=$(python "$root/scripts/apply.py" "$root" "$mode")
echo "Configuration backup: $backup"
command -v fc-cache >/dev/null && fc-cache -f "$HOME/.local/share/fonts"
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications"
if $activate && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
 hyprctl reload
 errors=$(hyprctl configerrors)
 if [[ -n ${errors//[[:space:]]/} ]]; then
  printf 'Hyprland rejected the configuration:\n%s\nRestoring previous files.\n' "$errors" >&2
  python "$root/scripts/restore.py" "$backup"
  hyprctl reload
  exit 1
 fi
 python "$root/scripts/session-settings.py" "$backup"
 "$HOME/.local/bin/macos-appearance" sync
 for daemon in waybar hyprpaper hypridle dunst; do pkill -u "$UID" -x "$daemon" || true; done
 pkill -u "$UID" -f "^/usr/bin/python $HOME/.local/bin/macos-dock$" || true
 pkill -u "$UID" -f "^/usr/bin/python $HOME/.local/bin/macos-menubar$" || true
 hyprctl dispatch 'hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/arch-start")'
fi
touch "$state/INSTALL-COMPLETE"
printf '\nInstalled. Super+Space opens applications; search Keyboard Shortcuts.\nRestore configuration: ~/.local/bin/arch-rice-restore\nLog out and back in for all shell, font and portal changes.\n'
