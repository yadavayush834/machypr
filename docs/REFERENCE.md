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
| `~/.local/bin/macos-menubar` | Native GTK/Cairo macOS-style menu bar (Waybar config remains as fallback) |
| `~/.local/bin/macos-dock` | GTK layer-shell dock for current-workspace apps |
| `~/.local/bin/macos-menu` | Apple/shortcut/window/control menus |
| `~/.local/bin/macos-app-name` | Active app label for Waybar |
| `~/.local/bin/arch-start` | Session daemons, native menu bar and dock startup |
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
Finder is Dolphin, Preview is Okular, and Launchpad is the application grid; the dock uses familiar
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

The frosted light bar and compact status group follow the Big Sur/Monterey layout. The default bar draws icons directly with Cairo, avoiding Waybar image-loader issues. The previous Waybar configuration remains a fallback. Battery status is read from Linux power_supply: charging and fully charged on AC show a lightning badge; active charging uses green fill, connected-but-not-charging shows a plug, and unplugged shows charge level. Percentage and power source appear in the live dropdown. The icon does not fake a repeating charge animation. Ethernet and Wi-Fi icons reflect the actual network link.

References: [Apple battery status](https://support.apple.com/en-au/guide/mac-help/mchl173fcc57/mac), [Apple Big Sur battery screenshot](https://support.apple.com/en-us/108376), and the [Sonoma screenshot library](https://512pixels.net/projects/aqua-screenshot-library/macos-14-sonoma/).

## Dock rendering

The dock loads WhiteSur SVG artwork at 256px and draws it at logical size with Cairo, avoiding low-resolution Gtk.Image upscaling on fractional-scale screens. The shelf and shadow are drawn separately; compositor layer blur is disabled for this dock so it cannot soften the icons. Hover magnification eases between 52 and 65 logical pixels and affects nearby icons. Labels appear above icons, with dark running indicators below. Move to the bottom edge to reveal the dock, or use Super+Alt+D. The dock hides after the pointer leaves.

Application icons come from windows on the focused desktop, including applications outside the original launcher list. Launchpad and Trash remain available as utility shortcuts. Windows belonging to the same app share an icon; clicking it focuses a local window, with repeated clicks cycling local windows. Apps on other desktops do not appear or intercept clicks. Hyprland workspace/open/close/move events update the dock immediately; a polling fallback reconnects if the event socket disappears. The shelf grows or shrinks with its app list and reduces icon spacing when needed to fit the display.

Minimized windows remain associated with their last regular desktop and can be restored from that desktop’s dock. The address-to-desktop mapping is cached locally in `~/.cache/macos-desktop/dock-workspaces.json`, scoped to the current compositor session, and closed-window entries are removed.

## Appearance

Use Apple menu → Appearance or Control Center → Appearance. `macos-appearance light`, `macos-appearance dark`, and `macos-appearance auto` also work from a terminal. Auto follows a local-time 07:00–19:00 schedule; it does not calculate sunrise or sunset. The menu bar keeps the schedule active while running. Preferences are stored in `~/.config/macos-desktop/appearance.json`. Native surfaces refresh within two seconds; some GTK/Qt applications need reopening. Wallpaper and icon artwork remain unchanged. Both WhiteSur GTK variants are installed by the theme installer.

## Menu-bar interactions

The active menu is highlighted. Click it again to close; while a menu is open, move across the left-hand menu titles to switch. Only one bar-owned popup is kept open. Terminal uses Shell and Finder exposes Go; other apps retain File/Edit/View shortcuts. Click the date for the calendar. Popups fit their actual width inside the display bounds, and long app names are ellipsized.

Popups use a transparent outside-click surface below the menu. Clicking outside dismisses the popup; its input region excludes the menu bar so toggling and switching remain available. `python scripts/test-popup-desktop.py` runs an optional live-session pointer-dismiss regression check (requires installed desktop helpers).

Menu rows align selection marks and shortcut hints. Up/Down and Home/End navigate the popup; Enter activates the focused item and Escape dismisses it. The network icon now opens a connection-status menu instead of immediately launching a terminal.

## Screenshots

Super+Shift+3 captures the whole desktop, Super+Shift+4 selects a rectangle, and Super+Shift+5 opens screenshot options. Add Ctrl to 3/4 for clipboard-only capture. Print retains area capture. The options menu also offers active-window capture, a five-second delay, and the screenshots folder. Successful captures play the screenshot effect and notify; cancellation saves nothing. Regular captures are saved under Pictures/Screenshots and copied to the clipboard. Window-move bindings for workspaces 3–5 use Super+Alt+Shift+3/4/5 to avoid conflicts.

## Brave window controls

The Brave launcher exposes the local theme directory read-only to Flatpak and selects GTK 3 integration. Before starting a closed browser profile, `macos-brave-theme` backs up Preferences and enables Chromium’s GTK system theme so WhiteSur renders native red/yellow/green controls. It skips profiles while their singleton lock is present, preserves other preferences, and does not change password-storage settings. Browser preference backups remain local under `~/.local/state/macos-desktop/browser-backups`. Brave uses the desktop settings portal for live Light/Dark GTK changes. The launcher explicitly clears `GTK_THEME`, since that environment override pins the toolbar to its startup variant, and enables `GTK_USE_PORTAL`. Older browser processes launched with the override need one restart.

## Desktop-wide window controls

`macos-window-bars.lua` loads the official [hyprbars plugin](https://github.com/hyprwm/hyprland-plugins/tree/d2427d4d15b36df40468f5a58bbd67cdba19835d/hyprbars) and supplies a centered title with left-aligned traffic lights to normal application windows. Red closes, yellow moves the window to the minimized workspace (restore through the Dock), and green toggles maximization. Double-clicking the title also toggles maximization. Hover reveals the button symbols; inactive windows show gray controls. Fullscreen applications hide the title bar.

The installer builds the BSD-licensed official source against installed Hyprland headers, preserving Hyprland's ABI check. Binaries are local and not committed. `scripts/install-window-controls.sh` pins source for Hyprland 0.57.x; rebuild after a compositor upgrade and log in again. A future major/minor version requires a matching source revision. Config-only installation assumes this plugin has already been built. If the binary is absent or incompatible, the configuration continues without the extra bars.

VS Code uses `window.titleBarStyle: native` to avoid duplicate controls. Qt Wayland client decorations are disabled for new processes; existing applications may need reopening. Brave is excluded from the compositor bar because its GTK tab strip already contains the WhiteSur controls. Applications that deliberately draw their own controls may still require their native-title-bar setting.

## Appearance contrast

Light and Dark replace all sixteen terminal ANSI colors, including secondary gray text, rather than changing the background alone. Kitty uses an opaque background, undimmed text and `text_fg_override_threshold 4.5 ratio` to keep application-supplied truecolor text readable against both light and dark cells. This also protects an already-running terminal application that retains its original colors. Applications can still draw their own input-panel backgrounds. Qt palettes include normal, secondary, link and status text for windows, views, buttons, tooltips and selections; applications that cache their palette may need reopening.

Appearance changes use `hyprctl reload config-only` because hyprbars caches rendered title text. Updating its background and text settings without rebuilding those textures can leave white text on a light bar. The reload refreshes title textures without reconfiguring monitors.

`Alt + Tab` and `Alt + Shift + Tab` send Ctrl+Tab and Ctrl+Shift+Tab to the focused window for forward/backward tab switching. Kitty maps those shortcuts to terminal tabs. Other applications use their own tab-switching behavior (VS Code uses its recent-editor list); applications without tabs may ignore them. `Super + Tab` opens the desktop window switcher.

Window-switcher row actions run after both the menu and its outside-click overlay have been unmapped and synchronized with the compositor. Selecting a window focuses and raises it above other floating windows; selecting a minimized window restores it first. `python scripts/test-window-menu-desktop.py` optionally checks the live GTK button callbacks using two disposable windows, without changing existing application contents.

## Refractive material and window containment

The optional glass mode now uses a pinned HyprGlass compositor plugin when available, including actual background sampling and edge refraction. It applies a 0.92 opacity rule to normal app windows; fullscreen remains opaque and is excluded from glass. This supersedes the earlier all-opaque-client glass policy described above. See [renderer installation, fallback and verification](REFRACTIVE-GLASS.md).

Floating windows use `misc.float_force_onscreen=2`. Initial dimensions adapt to monitor size, with monitor-relative maximum dimensions to keep normal client requests and pointer resizing usable. The expression syntax is `monitor_w*0.95` / `monitor_h*0.85`. Explicit low-level resize dispatchers can bypass Hyprland size hints; the rules target normal desktop operations.
