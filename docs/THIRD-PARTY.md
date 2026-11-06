# Third-party assets

The repository's MIT license covers its original configuration and helpers.
Upstream projects retain their licenses and trademarks.

| Project | Use | Revision / license |
| --- | --- | --- |
| [WhiteSur GTK](https://github.com/vinceliuice/WhiteSur-gtk-theme) | GTK styling, generated GTK4 CSS/assets and wallpaper | `d5782652d412137e26fb8ff55b55a5572e4c6995`, MIT; [included license](LICENSE-WhiteSur-GTK) |
| [WhiteSur icons](https://github.com/vinceliuice/WhiteSur-icon-theme) | Downloaded by the theme installer | `73d8040da51a9ed74e47c7366e7e9ff437601a5c`; see upstream COPYING |
| [WhiteSur cursors](https://github.com/vinceliuice/WhiteSur-cursors) | Downloaded by the theme installer | `e190baf618ed95ee217d2fd45589bd309b37672b`; see upstream LICENSE |
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
