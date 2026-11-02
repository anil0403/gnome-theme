#!/usr/bin/env bash
# Runs install.sh then uninstall.sh against a throwaway HOME and a private session
# bus, so the desktop running this test is not touched.
# Pass --compare on a machine running the theme to also diff against the live files.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REAL_HOME=$HOME
box=$(mktemp -d)
trap 'rm -rf "$box"' EXIT
mkdir -p "$box/home/.config/gtk-3.0" "$box/run"
chmod 700 "$box/run"
echo '/* mine */' > "$box/home/.config/gtk-3.0/gtk.css"
# The test must never install system packages, so sudo always fails here.
mkdir -p "$box/bin"
printf '#!/bin/sh\nexit 1\n' > "$box/bin/sudo"
chmod +x "$box/bin/sudo"
export PATH=$box/bin:$PATH

export HOME=$box/home XDG_RUNTIME_DIR=$box/run
# Without these, gvfs starts on the private bus and pins a FUSE mount inside the box.
export GIO_USE_VFS=local GVFS_DISABLE_FUSE=1
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME

dbus-run-session -- bash -s "$ROOT" "$REAL_HOME" "${1:-}" <<'CHECK'
set -euo pipefail
ROOT=$1 REAL_HOME=$2 MODE=$3
fail() { echo "FAIL: $1" >&2; exit 1; }
want() { [ "$(dconf read "$1")" = "$2" ] || fail "$1 = $(dconf read "$1"), wanted $2"; }

dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
dconf write /org/gnome/shell/enabled-extensions "['keep-me@example.com', 'dash-to-dock@micxgx.gmail.com']"
dconf write /org/gnome/shell/favorite-apps "['mine.desktop']"
dconf write /org/gnome/desktop/background/picture-uri "'file:///mine.png'"

"$ROOT/install.sh" </dev/null
# Fake a v1.0.x install, which kept its state under the old name and backed up
# and replaced the gtk3 user css.
STATE=$HOME/.local/state/tahoe-gnome
mv "$HOME/.local/state/gnome-theme" "$STATE"
mkdir -p "$STATE/backup$HOME/.config/gtk-3.0"
cp "$HOME/.config/gtk-3.0/gtk.css" "$STATE/backup$HOME/.config/gtk-3.0/"
echo "@import 'colors.css';" > "$HOME/.config/gtk-3.0/gtk.css"
touch "$HOME/.config/gtk-3.0/colors.css"
echo 1.0.1 > "$STATE/version"
"$ROOT/install.sh" </dev/null >/dev/null   # a re-run must not overwrite the backup
[ ! -e "$HOME/.config/gtk-3.0/colors.css" ] || fail 'v1.0 override left behind'
[ ! -e "$STATE" ] && [ -e "$HOME/.local/state/gnome-theme/backup-done" ] || fail 'old state not moved'

want /org/gnome/desktop/interface/gtk-theme "'MacTahoe-Dark'"
want /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'"
want /org/gnome/shell/favorite-apps "['mine.desktop']"
want /org/gnome/desktop/interface/monospace-font-name "'SF Mono 11'"
want /org/gnome/desktop/background/picture-uri "'file://$HOME/.local/share/backgrounds/gnome-theme.png'"
cmp -s "$ROOT/wallpaper/gnome-theme.png" "$HOME/.local/share/backgrounds/gnome-theme.png" ||
    fail 'wallpaper not installed'
if command -v qt6ct >/dev/null; then
    grep -q "^QT_PLUGIN_PATH=$HOME/.local/share/gnome-theme-qt6" "$HOME/.config/environment.d/tahoe-qt.conf" ||
        fail 'prebuilt Qt title-bar plugin not used (rerun qt/build-decoration.sh?)'
    [ -e "$HOME/.local/share/gnome-theme-qt6/wayland-decoration-client/libqwhitesurgtkdecorations.so" ] ||
        fail 'Qt title-bar plugin missing'
fi
overrides=$HOME/.local/share/flatpak/overrides
if command -v flatpak >/dev/null; then
    grep -q 'xdg-config/gtk-4.0:ro' "$overrides/global" || fail 'Flatpak GTK override missing'
    if compgen -G "$ROOT/qt/wayland-decoration-client/flatpak-*" >/dev/null &&
        [[ $(flatpak list --app --columns=runtime) == *org.kde.Platform/* ]]; then
        grep -rq '^QT_PLUGIN_PATH=.*gnome-theme-qt6-flatpak' "$overrides" || fail 'Flatpak Qt override missing'
    fi
fi
enabled=$(dconf read /org/gnome/shell/enabled-extensions)
[[ $enabled == *keep-me@example.com* ]] || fail 'dropped an existing extension'
[[ $enabled == *UbuntuTahoeDock@* ]] || fail 'dock not enabled'
[[ $enabled != *dash-to-dock* ]] || fail 'conflicting dock still enabled'
[ "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "$HOME/.themes/MacTahoe-Dark/gtk-4.0/gtk.css" ] ||
    fail 'gtk4 gtk.css should link into the theme'
[ -e "$HOME/.config/gtk-4.0/assets/scalable" ] || fail 'gtk4 assets link'
[ "$(cat "$HOME/.config/gtk-3.0/gtk.css")" = '/* mine */' ] || fail 'touched the gtk3 user css'
for f in MacTahoe-blue-dark/index.theme MacTahoe-cursors/index.theme; do
    [ -e "$HOME/.local/share/icons/$f" ] || fail "missing $f"
done

if [ "$MODE" = --compare ]; then
    live=$REAL_HOME/.local/share/gnome-shell/extensions
    diff -r -x gschemas.compiled -x '*.bak' "$live" "$HOME/.local/share/gnome-shell/extensions" ||
        fail 'extensions differ from the live install'
    diff -r -x COPYING "$REAL_HOME/.themes/MacTahoe-Dark" "$HOME/.themes/MacTahoe-Dark" ||
        fail 'theme differs from the live install'
    for icon in MacTahoe-blue-dark MacTahoe-cursors; do
        diff -rq -x icon-theme.cache "$REAL_HOME/.local/share/icons/$icon" "$HOME/.local/share/icons/$icon" ||
            fail "$icon differs from the live install"
    done
fi

[ "$(cat "$HOME/.local/state/gnome-theme/version")" = "$(cat "$ROOT/VERSION")" ] || fail 'version not recorded'
"$HOME/.local/state/gnome-theme/uninstall.sh" </dev/null

want /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
want /org/gnome/shell/favorite-apps "['mine.desktop']"
want /org/gnome/desktop/background/picture-uri "'file:///mine.png'"
[ ! -e "$HOME/.local/share/backgrounds/gnome-theme.png" ] || fail 'wallpaper not removed'
want /org/gnome/shell/enabled-extensions "['keep-me@example.com', 'dash-to-dock@micxgx.gmail.com']"
[ "$(cat "$HOME/.config/gtk-3.0/gtk.css")" = '/* mine */' ] || fail 'gtk.css not restored'
[ ! -e "$HOME/.themes/MacTahoe-Dark" ] || fail 'theme not removed'
[ ! -e "$HOME/.local/share/icons/MacTahoe-blue-dark" ] || fail 'icons not removed'
[ ! -e "$HOME/.local/share/fonts/gnome-theme" ] || fail 'fonts not removed'
[ ! -e "$HOME/.local/share/gnome-theme-qt6" ] || fail 'Qt plugin not removed'
[ ! -e "$HOME/.config/environment.d/tahoe-qt.conf" ] || fail 'Qt environment not removed'
[ -z "$(ls -A "$overrides" 2>/dev/null)" ] || fail 'Flatpak overrides not removed'
[ ! -e "$HOME/.local/share/gnome-theme-qt6-flatpak" ] || fail 'Flatpak Qt plugin not removed'
CHECK
echo 'PASS'
