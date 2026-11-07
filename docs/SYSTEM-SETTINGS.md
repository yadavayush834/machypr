# System Settings

Open **Apple menu → System Settings**, click its Dock icon, search for System Settings in Spotlight/Launchpad, or run `macos-settings`. A section can be opened directly, for example `macos-settings wallpaper` or `macos-settings keyboard`.

The native GTK application follows the sidebar, search, grouped rows and Light/Dark appearance of macOS System Settings. It controls Arch Linux and Hyprland; it does not emulate macOS or claim support for Apple services. Ctrl+F focuses search, Enter opens the first matching section, Alt+Left/Right navigates section history, and Refresh rereads the running system. Section changes, refresh and history navigation start at the top of the page. Device operations run outside GTK's event loop; failures appear in the window.

## Working controls

| Section | Backend and behavior |
| --- | --- |
| Wi-Fi | Reads NetworkManager or iwd, toggles adapter power, lists nearby networks and connects through an interactive terminal password prompt |
| Bluetooth | Reads BlueZ state, toggles power, connects/disconnects known devices; discovery and pairing open Blueman |
| Network | Live interface/IP addresses, network setup and NetworkManager connection editor when installed |
| Battery | Actual charge/power source; energy modes when Power Profiles Daemon is installed |
| General | Hardware/kernel/storage information; explicit package-update commands; system time/time zone, hostname, login items, user services and backup folders |
| Accessibility | Reduce Motion and GTK text scaling |
| Appearance | Light/Dark/Auto, compositor refraction through HyprGlass when installed, native frosted fallback, blur and corner radius |
| Menu Bar | Opens the existing Control Center and related settings |
| Desktop & Dock | Wallpaper, desktop folder, click/pointer focus; persistent Dock size, auto-hide and magnification |
| Displays | Brightness, advertised resolution/refresh modes and scale; mode changes revert after 15 seconds unless confirmed |
| Wallpaper | Original macOS wallpaper catalog, current preview, individual/all downloads and custom image selection |
| Notifications / Focus | Dunst notification pause, history, dismissal and Do Not Disturb |
| Sound | PipeWire output volume/mute, PulseAudio-compatible output-device selection, effects and advanced input/app controls through pavucontrol |
| Lock Screen / Screen Saver | Persistent automatic lock timing and immediate Hyprlock; this is a secure idle lock rather than Apple's aerial-video engine |
| Privacy & Security | Portal permission inspection, Flatseal when installed, lock/password actions |
| Touch ID & Password | Account password changes in an interactive terminal; fprintd enrollment when installed |
| Users & Groups | Actual account/group details, password action and optional user manager |
| Internet Accounts | Installed mail/calendar client or iCloud web |
| Keyboard | Persistent repeat rate, delay, input layout and desktop shortcuts |
| Mouse / Trackpad | Persistent pointer speed, scrolling speed/direction, tap-to-click and disable-while-typing |
| Printers & Scanners | System printer manager, local CUPS administration and scanner app when installed |
| Spotlight | Existing native app launcher and application shortcuts |

Unavailable optional tools are labeled and disabled. Privileged system changes use the system's own authentication. Update/password actions run in a terminal so prompts and results remain visible. Merely opening System Settings does not upgrade packages, change the network, record activity, or modify account credentials.

Apple Account, Family Sharing, Apple Intelligence/Siri, Game Center, Wallet/Apple Pay and native iCloud integration require Apple services or hardware and are explicitly identified as unavailable. iCloud and Apple Account web links remain usable. Screen Time shows actual machine uptime; per-app usage tracking and parental controls are not implemented. Healthy hardware without Linux fingerprint support cannot acquire Touch ID through this application.

## Persistence

Only settings explicitly changed by the user are recorded in `~/.config/macos-desktop/settings.json` and `~/.config/hypr/settings-overrides.lua`. Display settings use `displays.json` and `display-settings.lua`. The compositor loads both optional Lua files after the shipped configuration. Dock settings live in `~/.config/macos-desktop/dock.json` and are reread within two seconds. Existing appearance, sound and wallpaper helpers retain their existing configuration formats. Automatic lock changes preserve other idle listeners and save the original configuration as `hypridle.conf.before-settings`.

## Original wallpapers

The catalog contains 22 original Apple wallpapers: Tahoe Light/Dark/Day/Night, Sequoia Light/Dark, Sonoma Light/Dark, Ventura Light/Dark, Monterey Light/Dark, Big Sur Day/Night/Graphic, Catalina Day/Night, Mojave Day/Night, High Sierra, Yosemite and Mavericks. The installer downloads them locally; downloads can also be retried from the Wallpaper page or with `macos-wallpapers --install`. A single image is fetched on selection when absent. Downloads are validated as full-resolution images, written atomically and limited to 64 MiB each. Applying an image updates Hyprpaper and the persistent wallpaper configuration.

The catalog pins [LAYTAT/macOS-Wallpapers](https://github.com/LAYTAT/macOS-Wallpapers) at `fae15d0c4fc58790bc93de33699e0adbb0ca987f`. The images remain Apple's artwork; they are stored under `~/.local/share/wallpapers/macOS`, not redistributed in this repository. The full collection uses approximately 387 MiB on the development machine.

## Desktop context menu

Right-click an icon for **Open**, **Rename…**, and **Remove from Desktop** (shortcuts) or **Move to Trash** (regular files/folders). Removal uses the user's Trash and never uninstalls an application. Removing a symlink moves only the link, leaving its destination intact. Shortcut renaming updates its displayed name while preserving its launch command, icon and executable permissions. Existing names cannot be overwritten. Icon positions follow the new name. Removed shortcuts are not recreated by the one-time desktop seeder.

Right-click an empty part of the desktop for Wallpaper or System Settings, alongside the existing folder and refresh actions.

## Validation and references

`bash scripts/check.sh` includes isolated persistence, validation, wallpaper and desktop rename/trash regression checks. `python scripts/test-settings-desktop.py` additionally renders every page in a live Hyprland session, waits for asynchronous state, captures representative pages and checks search/history without changing settings. Live compositor apply/readback and wallpaper application were also checked during implementation.

Visual and behavior references: [Apple: Customize your Mac with System Settings](https://support.apple.com/en-by/guide/mac-help/mh15217/mac), [Apple: Find options in System Settings](https://support.apple.com/en-ie/guide/mac-help/mchl8d10839d/mac), and the [macOS Tahoe screenshot library](https://512pixels.net/projects/aqua-screenshot-library/macos-26-tahoe/). Wallpaper provenance: [512 Pixels default wallpaper archive](https://512pixels.net/projects/default-mac-wallpapers-in-5k/) and the pinned collection above.

Refractive rendering, its application-opacity policy and window containment are documented in [REFRACTIVE-GLASS.md](REFRACTIVE-GLASS.md).
