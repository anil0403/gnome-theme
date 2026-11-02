#!/usr/bin/env bash
# Rebuilds the prebuilt 20px Qt title-bar plugin shipped in releases.
# It uses Qt private API, so it only loads on the Qt minor version it was built
# against: rerun this whenever that changes. Needs cmake, a C++ compiler and the
# Qt 6 base, svg and wayland development files, including the private headers.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO=https://github.com/FengZhongShaoNian/QWhiteSurGtkDecorations
SHA=5f7fc7df30582974a1943bb445d0509f54510ea3 # tag 0.2.0
OUT=$ROOT/qt/wayland-decoration-client

core=$(ls /usr/lib*/libQt6Core.so.6.*.* /usr/lib/*/libQt6Core.so.6.*.* 2>/dev/null | head -1)
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

mkdir -p "$OUT"
cp "$(find "$tmp/build" -name libqwhitesurgtkdecorations.so)" "$OUT/"
strip "$OUT/libqwhitesurgtkdecorations.so"
cp "$tmp/src/LICENSE" "$OUT/LICENSE"
echo "${version%.*} $(uname -m)" > "$OUT/BUILT_FOR"
echo "Built for Qt $version ($(uname -m)) in $OUT"
