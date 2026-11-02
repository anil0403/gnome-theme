#!/usr/bin/env bash
# Builds the 20px Qt title-bar plugin for this machine's Qt into
# qt/wayland-decoration-client/<qt minor>-<arch>/. It uses Qt private API, so
# each build only loads on that Qt version. The release workflow runs this on
# several distros, and the tests need a local build. Needs cmake, a C++ compiler
# and the Qt 6 base, svg and wayland development files, including private headers.
# For Flatpak apps, run it in the KDE SDK their runtime matches:
#   flatpak run --share=network --filesystem="$PWD" --command=bash org.kde.Sdk//6.11 qt/build-decoration.sh
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO=https://github.com/FengZhongShaoNian/QWhiteSurGtkDecorations
SHA=5f7fc7df30582974a1943bb445d0509f54510ea3 # tag 0.2.0
OUT=$ROOT/qt/wayland-decoration-client

core=$(ls /usr/lib*/libQt6Core.so.6.*.* /usr/lib/*/libQt6Core.so.6.*.* 2>/dev/null | head -1) || true
[ -n "$core" ] || { echo 'error: Qt 6 not found' >&2; exit 1; }
version=${core##*.so.}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git init -q "$tmp/src"
git -C "$tmp/src" fetch -q --depth 1 "$REPO" "$SHA"
git -C "$tmp/src" checkout -q FETCH_HEAD
sed -i -f "$ROOT/patches/QWhiteSurGtkDecorations.sed" "$tmp/src/src/qwhitesurgtkdecorations.cpp"
cmake -S "$tmp/src" -B "$tmp/build" -DUSE_QT6=true -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$tmp/build" -j"$(nproc)" >/dev/null

# Run inside a KDE Flatpak SDK, it builds for apps on that runtime instead.
prefix=
if [ -e /.flatpak-info ]; then prefix=flatpak-; fi
dest=$OUT/$prefix${version%.*}-$(uname -m)
mkdir -p "$dest"
cp "$(find "$tmp/build" -name libqwhitesurgtkdecorations.so)" "$dest/"
strip "$dest/libqwhitesurgtkdecorations.so"
cp "$tmp/src/LICENSE" "$OUT/LICENSE"
echo "Built for Qt $version in $dest"
