# Third-party assets

The repository's MIT license covers its original configuration and helpers.
Upstream projects retain their licenses and trademarks.

| Project | Use | Revision / license |
| --- | --- | --- |
| [WhiteSur GTK](https://github.com/vinceliuice/WhiteSur-gtk-theme) | GTK styling, generated GTK4 CSS/assets and wallpaper | `d5782652d412137e26fb8ff55b55a5572e4c6995`, MIT; [included license](LICENSE-WhiteSur-GTK) |
| [WhiteSur icons](https://github.com/vinceliuice/WhiteSur-icon-theme) | Downloaded by the theme installer | `73d8040da51a9ed74e47c7366e7e9ff437601a5c`; see upstream COPYING |
| [WhiteSur cursors](https://github.com/vinceliuice/WhiteSur-cursors) | Downloaded by the theme installer | `e190baf618ed95ee217d2fd45589bd309b37672b`; see upstream LICENSE |
| [hyprbars](https://github.com/hyprwm/hyprland-plugins/tree/d2427d4d15b36df40468f5a58bbd67cdba19835d/hyprbars) | Desktop-wide traffic-light title bars, built locally | `d2427d4d15b36df40468f5a58bbd67cdba19835d`, BSD-3-Clause |
| [Inter](https://github.com/rsms/inter) | UI font, installed through Arch's `inter-font` package | SIL Open Font License 1.1 |
| [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) | Terminal font and status glyphs | Installed through Arch's `ttf-jetbrains-mono-nerd` package; upstream licenses |

The upstream theme installers and their license files are retained under
`~/.cache/arch-hyprland-dotfiles/themes`. San Francisco is not bundled.
Apple, macOS, Arch Linux and application names/logos belong to their owners.
This project is not affiliated with Apple or Arch Linux.

The older optional wallpapers retained in `home/.local/share/wallpapers` are
original generated artwork from the earlier desktop profile. The active profile
uses WhiteSur.png.

`MacDesktopSymbols.ttf` and its source drawings are original MIT-licensed artwork, not Apple SF Symbols. Rebuild with `uv run --with fonttools python scripts/build-status-font.py`.

## Optional local sound samples

`scripts/install-sounds.py` downloads notification (Glass), critical (Basso), volume feedback (Media_Keys) and screenshot (Screen_Capture) samples from [ThisIsNoahEvans/BigSurSounds](https://github.com/ThisIsNoahEvans/BigSurSounds), pinned at `20dab112698edc9523afe9f09b8e921f75da8a96`. The original macOS sound recordings belong to Apple; audio is stored only under the installing user’s sound directory and is not redistributed in this repository. The installer converts them to WAV with FFmpeg.

## November 7 additions

- [MacTahoe GTK theme](https://github.com/vinceliuice/MacTahoe-gtk-theme), revision `1e45e19f510edb8cde18fa84d6cd5319f60b086b`: upstream prebuilt Dark/Light archives, with COPYING retained during installation.
- [MacTahoe icons](https://github.com/vinceliuice/MacTahoe-icon-theme), revision `839848b9a8a38a92a6936e30c4abe35cc6f2546d`: upstream local icon installer retains COPYING and AUTHORS.
- `home/.local/bin/mac-os-checkupdates` derives from pacman-contrib checkupdates by Kyle Keen and other contributors, GPL-2.0-or-later. Its original notice is retained; see [license](LICENSE-checkupdates).
- [MacDashboard](https://github.com/wildfellhall/MacDashboard) informed the local notes/dashboard concept. The GTK implementation is original and has no AI service. Glass references informed rim lighting and translucent layering; no browser shader runtime or KDE component is embedded. [Exact reference revisions](visual-sources.json).
