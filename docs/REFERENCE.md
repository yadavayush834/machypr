# Installation and recovery guide

This repository applies a macOS-style desktop to an existing Arch Linux x86_64
installation. It does not partition disks, install a bootloader or GPU drivers,
choose a display manager, or replace the OS with macOS.

## Compatibility and installation

Use Hyprland **0.57+ with Lua configuration**. This snapshot was exercised on
0.57.1; rolling-release API changes may need future updates.

Review `install.sh`, `scripts/install-themes.sh` and the files under `home/`.
Run `./install.sh --desktop-only --dry-run`, then `./install.sh --desktop-only`.
The full installer without this option also provisions the packages listed in
`packages/apps.txt` and `packages/development.txt`, Brave through user Flatpak,
native VS Code, Rust components and optional React/Next.js example projects.
`--no-projects` skips examples. Existing projects and VS Code archives are kept.

Package installation performs `pacman -Syu` with the dependencies, avoiding an
Arch partial upgrade. Theme sources are downloaded at pinned commits.
`--config-only` skips packages and upstream theme setup: install WhiteSur GTK,
icons, cursors and Inter first. `--no-activate` defers daemon restarts and live
GSettings updates. In that case select WhiteSur-Dark, WhiteSur icons/cursor and
Inter in your appearance settings after logging in.

The theme installer adds resource directories under `~/.local/share/themes` and
`~/.local/share/icons`, and the upstream GTK appearance utility. It does not alter
GDM or system-wide files. GTK4 CSS/assets are included in the backed-up templates.

## Files

| Path | Purpose |
| --- | --- |
| `~/.config/hypr/hyprland.lua` | Floating windows, blur, bindings and startup |
| `~/.config/waybar/` | macOS-style menu bar |
| `~/.local/bin/macos-dock` | GTK layer-shell dock with launch/focus actions |
| `~/.local/bin/macos-menu` | Apple/shortcut/window/control menus |
| `~/.local/bin/macos-app-name` | Active app label for Waybar |
| `~/.local/bin/arch-start` | Session daemons and dock startup |
| `~/.config/gtk-3.0`, `~/.config/gtk-4.0` | WhiteSur application styling |
| `~/.config/kdeglobals` | Matching Qt palette, icons and fonts |
| `~/.config/environment.d/60-macos-desktop.conf` | Cursor and GTK CSD preferences |
| `~/.local/state/arch-hyprland-dotfiles/` | Install log, completion marker and backups |

No browser profiles, credentials, clipboard databases, personal documents or
machine-specific display rules are copied. The curated Code settings are project
configuration, not an export of your extensions or account data. Inspect the
managed Bash fragment if you already maintain a custom shell.

## Recovery

Before writing templates, `apply.py` creates a manifest and copies each replaced
file, preserving symlinks. To restore the latest backup:

```bash
~/.local/bin/arch-rice-restore
```

To restore an earlier backup:

```bash
~/.local/bin/arch-rice-restore ~/.local/state/arch-hyprland-dotfiles/backups/TIMESTAMP
```

Restore while logged into your desktop so saved GSettings can also be restored.
Then log out and back in to terminate the Mac dock and restart the previous
session components. Packages, added theme resources and example projects remain
installed. Empty directories created by the installer may remain.

On a configuration error during activation, the installer restores its backup.
It writes `INSTALL-COMPLETE` only on success. See `install.log` if setup stops.

## Behavior and limits

The top bar's File/Edit/View menus send common application shortcuts. They are
not a native macOS global app-menu implementation. Some actions vary by app.
Finder is Dolphin, Preview is Okular, and Launchpad is Wofi; the dock uses familiar
icons and names for those roles. Inter substitutes for San Francisco. Native
window buttons depend on the application toolkit; not every Linux app can display
identical macOS title bars. Existing windows may need reopening to pick up fonts,
icons and GTK styling.

The fixed Mac palette remains when selecting another wallpaper. Old bar-style
files may remain on an upgraded installation but are not part of the new profile.
The background is scaled to cover your display; automatic monitor scaling is the
default. Adjust it in the Lua configuration if needed.

Wi-Fi opens NetworkManager's `nmtui` when available, otherwise an iwd terminal.
Bluetooth uses Blueman. Services are not switched or enabled automatically.
Keep your existing network backend. On a systemd-networkd/iwd setup, services can
be enabled with `sudo systemctl enable --now iwd bluetooth` when appropriate.

## Validation

Run `bash scripts/check.sh`. CI checks shell syntax (and ShellCheck when
available), Python, JSON, TOML, desktop entries, portable path substitution,
no-op dry run, repeat installation, MIME preservation, symlink restoration and
rollback. These tests use a temporary home and do not install packages or alter
the active desktop. The full privileged install has not been tested on a second
clean Arch machine.

Licenses and upstream commit pins are listed in [THIRD-PARTY.md](THIRD-PARTY.md).

## Battery and menu-bar reference

The compact status group follows the Big Sur/Sonoma menu-bar layout. Original glyphs are bundled in MacDesktopSymbols.ttf to avoid image-loader issues in Waybar 0.15. Battery status is read from Linux power_supply: charging and fully charged on AC show a lightning badge, connected-but-not-charging shows a plug, and unplugged shows charge level. Percentage and power source appear in the live dropdown. The icon does not fake a repeating charge animation. Ethernet and Wi-Fi icons reflect the actual network link.

References: [Apple battery status](https://support.apple.com/en-au/guide/mac-help/mchl173fcc57/mac), [Apple Big Sur battery screenshot](https://support.apple.com/en-us/108376), and the [Sonoma screenshot library](https://512pixels.net/projects/aqua-screenshot-library/macos-14-sonoma/).
