# Tahoe GNOME

A dark, macOS Tahoe-style desktop theme for GNOME: colours, window controls,
icons, cursors, dock, menu bar and behaviour. It only themes your desktop and
installs no apps.

Tested on Arch Linux with GNOME Shell 51 on Wayland. The extensions declare
support for GNOME 45 to 51, but the shell styling targets 51, so older versions
may look different.

## What you get

- `MacTahoe-Dark` for GTK 3, GTK 4 and libadwaita, GNOME Shell and window frames
- `MacTahoe-blue-dark` icons, `MacTahoe-cursors` cursors and blue accents
- Larger 20px traffic-light buttons on the left of the title bar
- A bottom dock with hidden trash, where clicking a focused app minimizes it
- A global menu bar, Activities hidden, and a `3:45 PM  2 Nov Mon` style clock
- Blurred Overview and app folders
- Spotlight search on `Super+Alt+F`
- Clipboard history on `Super+Alt+Space`
- Screenshot UI on `Print` or `Shift+Super+S`
- `Alt` + drag to move windows, `Alt` + right-drag to resize, and middle-click a
  title bar to lower the window
- Matching Qt theme, if `qt6ct` and Kvantum are installed

## Install

You need `git`, `patch`, `python3` and the User Themes extension, which comes in
your distro's `gnome-shell-extensions` package.

```bash
git clone https://github.com/anil0403/tahoe-gnome.git
cd tahoe-gnome
./install.sh
```

Log out and back in when it finishes. The script works per user and never needs
root. It downloads the extensions and icons from their original projects, at
pinned commits. See [THIRD_PARTY.md](THIRD_PARTY.md).

It disables the Dash to Dock, Ubuntu Dock, Blur My Shell, Just Perfection, Global
Menu and Kimpanel extensions, because they conflict with this theme. Your
favourites and wallpaper are left alone.

### Fonts

The theme is designed for SF Pro and SF Mono, but Apple's license doesn't allow
sharing them here. Get them from [Apple](https://developer.apple.com/fonts/),
where its terms allow your use, and install them before running `install.sh`.
Without them, your current fonts are kept.

## Uninstall

```bash
./uninstall.sh
```

This removes what was installed and restores the files and settings it replaced.
Other settings you changed since then are kept.

## Test

```bash
tests/sandbox.sh
```

This runs a full install and uninstall in a throwaway home directory on a private
session bus. Your desktop isn't touched.

## Not included

- Apps and app configs, including terminal, editor and browser themes
- Fonts and wallpapers
- The GDM login screen theme

## License

MIT, except for the parts listed in [THIRD_PARTY.md](THIRD_PARTY.md), which keep
their own terms.
