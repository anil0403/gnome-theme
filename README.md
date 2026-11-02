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
- SF Pro for the interface and SF Mono for code, downloaded from Apple
- Larger 20px traffic-light buttons on the left of the title bar
- A bottom dock with hidden trash, where clicking a focused app minimizes it
- A global menu bar, Activities hidden, and a `3:45 PM  2 Nov Mon` style clock
- Blurred Overview and app folders
- Spotlight search on `Super+Alt+F`
- Clipboard history on `Super+Alt+Space`
- Screenshot UI on `Print` or `Shift+Super+S`
- `Alt` + drag to move windows, `Alt` + right-drag to resize, and middle-click a
  title bar to lower the window
- A dark Arch Linux wallpaper on the desktop and lock screen
- Matching Qt apps through `qt6ct` and Kvantum, with the same 20px title-bar
  buttons

## Install

You need `git`, `patch`, `python3` and the User Themes extension, which comes in
your distro's `gnome-shell-extensions` package.

```bash
curl -fsSL https://raw.githubusercontent.com/anil0403/tahoe-gnome/main/bootstrap.sh | bash
```

Log out and back in when it finishes. The script works per user. It installs the
latest release, and downloads the extensions and icons from their original
projects at pinned commits. See [THIRD_PARTY.md](THIRD_PARTY.md).

Prefer to read it first? Clone the repo and run `./install.sh`.

It disables the Dash to Dock, Ubuntu Dock, Blur My Shell, Just Perfection, Global
Menu and Kimpanel extensions, because they conflict with this theme. It sets the
wallpaper, and leaves your favourites alone.

### Qt apps

If `qt6ct` or Kvantum is missing, the installer installs them with your package
manager (pacman, apt or dnf), which asks for your password. This is the only step
that needs root. If it fails, Qt apps keep their own look.

The 20px title-bar buttons for Qt apps come from a prebuilt plugin. It only works
with the Qt version it was built for, listed in
`qt/wayland-decoration-client/BUILT_FOR`. On other Qt versions, Qt apps keep their
own title bars.

### Fonts

The theme uses SF Pro and SF Mono. Apple's license doesn't allow sharing them
here, so if you don't already have them, the installer downloads them from
[Apple](https://developer.apple.com/fonts/) (about 220 MB) into
`~/.local/share/fonts/tahoe-gnome`. This needs `7z` and `cpio`, and the fonts are
covered by Apple's license, not this repo's. If the download fails, your current
fonts are kept.

## Update

Run the install command again. It replaces the theme with the latest release and
keeps your original backup. Your installed version is in
`~/.local/state/tahoe-gnome/version`, and [VERSIONING.md](VERSIONING.md) explains
what each release number means.

## Uninstall

```bash
~/.local/state/tahoe-gnome/uninstall.sh
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
- The GDM login screen theme

## License

MIT, except for the parts listed in [THIRD_PARTY.md](THIRD_PARTY.md), which keep
their own terms.
