# Third-party notices

The repository is MIT licensed, except for the parts below. This is a practical
summary, not legal advice.

## Included in this repository

| Path | Comes from | License |
|---|---|---|
| `theme/MacTahoe-Dark/`, `gtk/` | [MacTahoe-gtk-theme](https://github.com/vinceliuice/MacTahoe-gtk-theme), as adjusted by [mactahoe-ubuntu](https://github.com/adfoxtheme/mactahoe-ubuntu) and here | MIT, see `theme/MacTahoe-Dark/COPYING` |
| `theme/MacTahoe-Dark/gnome-shell/gnome-shell.css` | Generated from GNOME Shell's stylesheet | Keeps its LGPL-2.1 header |
| `qt/Kvantum/` | Treated as derived from [MacTahoe-kde](https://github.com/vinceliuice/MacTahoe-kde) | LGPL-3.0, see `qt/LICENSE` |
| `patches/UbuntuTahoeDock.patch` | Changes to a fork of [Dash to Dock](https://github.com/micheleg/dash-to-dock) | GPL-2.0-or-later, see `patches/GPL-2.0.txt` |
| `patches/UbuntuTahoeSpotlight.patch` | Changes to a file marked GPL-3.0-or-later | GPL-3.0-or-later, see `patches/GPL-3.0.txt` |
| `patches/UbuntuTahoe.patch`, `patches/UbuntuTahoe-stylesheet.sed`, `patches/UbuntuTahoeClipboard.patch` | Changes to mactahoe-ubuntu | Not MIT, see below |

### Patches to mactahoe-ubuntu

[mactahoe-ubuntu](https://github.com/adfoxtheme/mactahoe-ubuntu) declares no
license for the repository. These patches are not offered under MIT, and they
grant no rights to the upstream code they touch. They hold the changes needed to
reproduce this theme, with as little upstream text as practical. `UbuntuTahoe`
also includes code that references [Blur My Shell](https://github.com/aunetx/blur-my-shell),
which is GPL-3.0.

Parts of `theme/MacTahoe-Dark/` also contain mactahoe-ubuntu's adjustments to the
MIT theme, such as `gnome-shell.css`.

If you are an author of this upstream work and would like anything changed or
removed, please open an issue.

## Downloaded by `install.sh`, not included here

| Component | Source | License |
|---|---|---|
| UbuntuTahoe, UbuntuTahoeDock, UbuntuTahoeClipboard, UbuntuTahoeSpotlight | [mactahoe-ubuntu](https://github.com/adfoxtheme/mactahoe-ubuntu) at a pinned commit | See above |
| MacTahoe icons and cursors | [MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme) at a pinned commit | GPL-3.0 |

## Not included

SF Pro and SF Mono belong to Apple and are not redistributed.

macOS and Tahoe are Apple's. This project is not affiliated with or endorsed by
Apple.
