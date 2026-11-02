#!/usr/bin/env bash
# Installs the theme for the current user. Safe to re-run.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/tahoe-gnome
EXT_DIR=$DATA/gnome-shell/extensions

# Pinned so the patches always apply. Bump a pin only after regenerating them.
EXTENSIONS_REPO=https://github.com/adfoxtheme/mactahoe-ubuntu
EXTENSIONS_SHA=e9b8f3a1fb57d16c70f484d47767b833e4f5ae71
ICONS_REPO=https://github.com/vinceliuice/MacTahoe-icon-theme
ICONS_SHA=839848b9a8a38a92a6936e30c4abe35cc6f2546d

TESTED_SHELL=51
EXTENSIONS=(UbuntuTahoe UbuntuTahoeDock UbuntuTahoeClipboard UbuntuTahoeSpotlight)
ENABLE=(user-theme@gnome-shell-extensions.gcampax.github.com
    appindicatorsupport@rgcjonas.gmail.com)
for name in "${EXTENSIONS[@]}"; do ENABLE+=("$name@adfoxtheme.github.io"); done
# These replace or fight with the extensions above.
DISABLE=(blur-my-shell@aunetx globalmenu@ShiroOSL.github.io
    just-perfection-desktop@just-perfection kimpanel@kde.org
    ubuntu-dock@ubuntu.com dash-to-dock@micxgx.gmail.com)

die() { printf 'error: %s\n' "$1" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$1" >&2; }

fetch() { # url sha dest [sparse path]
    git init -q "$3"
    git -C "$3" remote add origin "$1"
    [ -z "${4:-}" ] || git -C "$3" sparse-checkout set "$4"
    git -C "$3" fetch -q --depth 1 --filter=blob:none origin "$2"
    git -C "$3" checkout -q FETCH_HEAD
}

[ "$(id -u)" -ne 0 ] || die 'run this as your normal user, not root'
for cmd in dconf gsettings git glib-compile-schemas gnome-shell patch python3; do
    command -v "$cmd" >/dev/null || die "missing required command: $cmd"
done
shell_major=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
[ "$shell_major" -ge 45 ] && [ "$shell_major" -le 51 ] ||
    die "GNOME Shell $shell_major is unsupported: the extensions declare 45 to 51"
[ "$shell_major" -eq "$TESTED_SHELL" ] ||
    warn "tested on GNOME Shell $TESTED_SHELL only; expect shell styling differences on $shell_major"

qt=false
if command -v qt6ct >/dev/null && command -v kvantummanager >/dev/null; then qt=true; fi

GTK4_LINKS=(gtk.css gtk-dark.css assets windows-assets)
paths=("$HOME/.themes/MacTahoe-Dark")
for f in "${GTK4_LINKS[@]}"; do paths+=("$CONFIG/gtk-4.0/$f"); done
for name in "${EXTENSIONS[@]}"; do paths+=("$EXT_DIR/$name@adfoxtheme.github.io"); done
for icon in MacTahoe MacTahoe-light MacTahoe-dark MacTahoe-blue MacTahoe-blue-light \
    MacTahoe-blue-dark MacTahoe-cursors MacTahoe-dark-cursors; do
    paths+=("$DATA/icons/$icon")
done
if "$qt"; then
    paths+=("$CONFIG/Kvantum/TahoeGlassDark" "$CONFIG/Kvantum/kvantum.kvconfig"
        "$CONFIG/qt6ct/qt6ct.conf" "$CONFIG/environment.d/tahoe-qt.conf"
        "$CONFIG/kdeglobals" "$DATA/color-schemes/TahoeGlassDark.colors")
fi

# Snapshot once, before anything changes, so a re-run never backs up our own files.
if [ ! -e "$STATE/backup-done" ]; then
    mkdir -p "$STATE/backup"
    for p in "${paths[@]}"; do
        if [ -e "$p" ] || [ -L "$p" ]; then
            mkdir -p "$STATE/backup$(dirname "$p")"
            cp -a "$p" "$STATE/backup$p"
        fi
    done
    {
        awk -F= '/^\[/ { s = substr($0, 2, length($0) - 2); next }
                 /=/  { print "/" s "/" $1 }' "$ROOT"/dconf/*.ini
        printf '%s\n' /org/gnome/shell/enabled-extensions /org/gnome/shell/disabled-extensions \
            /org/gnome/shell/disable-user-extensions
    } | while read -r key; do printf '%s\t%s\n' "$key" "$(dconf read "$key")"; done \
        > "$STATE/dconf-before.tsv"
    printf '%s\n' "${paths[@]}" > "$STATE/paths"
    touch "$STATE/backup-done"
fi

# Kept here because the one-command install runs from a temp folder.
cp "$ROOT/uninstall.sh" "$STATE/uninstall.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo 'Fetching and patching the extensions...'
fetch "$EXTENSIONS_REPO" "$EXTENSIONS_SHA" "$tmp/extensions" vendor/gnome-extensions
for name in "${EXTENSIONS[@]}"; do
    src=$tmp/extensions/vendor/gnome-extensions/$name@adfoxtheme.github.io
    patch -s -d "$src" -p1 --no-backup-if-mismatch < "$ROOT/patches/$name.patch"
    glib-compile-schemas "$src/schemas"
done
sed -i -f "$ROOT/patches/UbuntuTahoe-stylesheet.sed" \
    "$tmp/extensions/vendor/gnome-extensions/UbuntuTahoe@adfoxtheme.github.io/stylesheet.css"

echo 'Fetching icons and cursors...'
fetch "$ICONS_REPO" "$ICONS_SHA" "$tmp/icons"
mkdir -p "$DATA/icons"
(cd "$tmp/icons" && ./install.sh -d "$DATA/icons" -t blue >/dev/null)
for pair in dist:MacTahoe-cursors dist-dark:MacTahoe-dark-cursors; do
    rm -rf "${DATA:?}/icons/${pair#*:}"
    cp -a "$tmp/icons/cursors/${pair%:*}" "$DATA/icons/${pair#*:}"
done

echo 'Installing the theme...'
mkdir -p "$HOME/.themes" "$EXT_DIR" "$CONFIG/gtk-4.0"
rm -rf "$HOME/.themes/MacTahoe-Dark"
cp -a "$ROOT/theme/MacTahoe-Dark" "$HOME/.themes/"
# v1.0.x copied override files into ~/.config; put back what they replaced.
if [[ $(cat "$STATE/version" 2>/dev/null) == 1.0.* ]]; then
    for f in gtk-3.0/gtk.css gtk-3.0/colors.css gtk-3.0/settings.ini \
        gtk-4.0/gtk-Dark.css gtk-4.0/colors.css gtk-4.0/settings.ini; do
        rm -rf "${CONFIG:?}/$f"
        [ ! -e "$STATE/backup$CONFIG/$f" ] || cp -a "$STATE/backup$CONFIG/$f" "$CONFIG/$f"
    done
fi
# libadwaita ignores the gtk-theme setting and only reads ~/.config/gtk-4.0,
# so point that at the theme rather than keeping a second copy.
for f in "${GTK4_LINKS[@]}"; do
    rm -rf "${CONFIG:?}/gtk-4.0/$f"
    ln -s "$HOME/.themes/MacTahoe-Dark/gtk-4.0/$f" "$CONFIG/gtk-4.0/$f"
done
for name in "${EXTENSIONS[@]}"; do
    rm -rf "$EXT_DIR/$name@adfoxtheme.github.io"
    cp -a "$tmp/extensions/vendor/gnome-extensions/$name@adfoxtheme.github.io" "$EXT_DIR/"
done

if "$qt"; then
    mkdir -p "$CONFIG/Kvantum" "$CONFIG/qt6ct" "$CONFIG/environment.d" "$DATA/color-schemes"
    rm -rf "$CONFIG/Kvantum/TahoeGlassDark"
    cp -r "$ROOT/qt/Kvantum/TahoeGlassDark" "$CONFIG/Kvantum/"
    printf '[General]\ntheme=TahoeGlassDark\n' > "$CONFIG/Kvantum/kvantum.kvconfig"
    cp "$ROOT/qt/qt6ct.conf" "$CONFIG/qt6ct/"
    cp "$ROOT/qt/TahoeGlassDark.colors" "$DATA/color-schemes/"
    [ -e "$CONFIG/kdeglobals" ] || cp "$ROOT/qt/TahoeGlassDark.colors" "$CONFIG/kdeglobals"
    if command -v kwriteconfig6 >/dev/null; then
        kwriteconfig6 --file "$CONFIG/kdeglobals" --group General --key ColorScheme TahoeGlassDark
        kwriteconfig6 --file "$CONFIG/kdeglobals" --group UiSettings --key ColorScheme TahoeGlassDark
    fi
    echo 'QT_QPA_PLATFORMTHEME=qt6ct' > "$CONFIG/environment.d/tahoe-qt.conf"
    # Optional plugin: only name it when installed, or Qt falls back with a warning.
    if compgen -G '/usr/lib*/qt6/plugins/wayland-decoration-client/*whitesur*' >/dev/null ||
        compgen -G '/usr/lib*/*/qt6/plugins/wayland-decoration-client/*whitesur*' >/dev/null; then
        echo 'QT_WAYLAND_DECORATION=whitesur-gtk' >> "$CONFIG/environment.d/tahoe-qt.conf"
    fi
fi

echo 'Applying settings...'
dconf load / < "$ROOT/dconf/settings.ini"
if command -v fc-list >/dev/null && fc-list | grep -q 'SF Pro'; then
    dconf load / < "$ROOT/dconf/fonts.ini"
else
    warn 'SF Pro is not installed, so your current fonts were kept (see README)'
fi

# New extensions only load after the next login, so these lists are edited directly.
python3 - "${#ENABLE[@]}" "${ENABLE[@]}" "${DISABLE[@]}" <<'PY'
import ast, subprocess, sys

count = int(sys.argv[1])
enable, disable = sys.argv[2:2 + count], sys.argv[2 + count:]

def read(key):
    value = subprocess.check_output(['gsettings', 'get', 'org.gnome.shell', key], text=True)
    return ast.literal_eval(value.replace('@as ', '').strip())

def write(key, value):
    subprocess.check_call(['gsettings', 'set', 'org.gnome.shell', key, repr(value)])

def merged(current, add, remove):
    return [u for u in current if u not in remove] + [u for u in add if u not in current]

write('enabled-extensions', merged(read('enabled-extensions'), enable, disable))
write('disabled-extensions', merged(read('disabled-extensions'), disable, enable))
PY
gsettings set org.gnome.shell disable-user-extensions false

user_theme=false
for dir in /usr/share/gnome-shell/extensions "$EXT_DIR"; do
    if [ -d "$dir/user-theme@gnome-shell-extensions.gcampax.github.com" ]; then user_theme=true; fi
done
"$user_theme" ||
    warn 'the User Themes extension is missing: install your distro gnome-shell-extensions package'
"$qt" || warn 'qt6ct or Kvantum is missing, so Qt apps were left unthemed'

cp "$ROOT/VERSION" "$STATE/version"
echo "Done: Tahoe GNOME $(cat "$ROOT/VERSION"). Log out and back in to load the extensions."
