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

"$ROOT/install.sh" </dev/null
"$ROOT/install.sh" </dev/null >/dev/null   # a re-run must not overwrite the backup

want /org/gnome/desktop/interface/gtk-theme "'MacTahoe-Dark'"
want /org/gnome/shell/extensions/user-theme/name "'MacTahoe-Dark'"
want /org/gnome/shell/favorite-apps "['mine.desktop']"
enabled=$(dconf read /org/gnome/shell/enabled-extensions)
[[ $enabled == *keep-me@example.com* ]] || fail 'dropped an existing extension'
[[ $enabled == *UbuntuTahoeDock@* ]] || fail 'dock not enabled'
[[ $enabled != *dash-to-dock* ]] || fail 'conflicting dock still enabled'
[ "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = gtk-Dark.css ] || fail 'gtk.css link'
for f in MacTahoe-blue-dark/index.theme MacTahoe-cursors/index.theme; do
    [ -e "$HOME/.local/share/icons/$f" ] || fail "missing $f"
done

if [ "$MODE" = --compare ]; then
    live=$REAL_HOME/.local/share/gnome-shell/extensions
    diff -r -x gschemas.compiled -x '*.bak' "$live" "$HOME/.local/share/gnome-shell/extensions" ||
        fail 'extensions differ from the live install'
    diff -r -x COPYING "$REAL_HOME/.themes/MacTahoe-Dark" "$HOME/.themes/MacTahoe-Dark" ||
        fail 'theme differs from the live install'
    diff "$REAL_HOME/.config/gtk-4.0/gtk-Dark.css" "$HOME/.config/gtk-4.0/gtk-Dark.css" ||
        fail 'gtk4 css differs from the live install'
    for icon in MacTahoe-blue-dark MacTahoe-cursors; do
        diff -rq -x icon-theme.cache "$REAL_HOME/.local/share/icons/$icon" "$HOME/.local/share/icons/$icon" ||
            fail "$icon differs from the live install"
    done
fi

[ "$(cat "$HOME/.local/state/tahoe-gnome/version")" = "$(cat "$ROOT/VERSION")" ] || fail 'version not recorded'
"$HOME/.local/state/tahoe-gnome/uninstall.sh" </dev/null

want /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
want /org/gnome/shell/favorite-apps "['mine.desktop']"
want /org/gnome/shell/enabled-extensions "['keep-me@example.com', 'dash-to-dock@micxgx.gmail.com']"
[ "$(cat "$HOME/.config/gtk-3.0/gtk.css")" = '/* mine */' ] || fail 'gtk.css not restored'
[ ! -e "$HOME/.themes/MacTahoe-Dark" ] || fail 'theme not removed'
[ ! -e "$HOME/.local/share/icons/MacTahoe-blue-dark" ] || fail 'icons not removed'
CHECK
echo 'PASS'
