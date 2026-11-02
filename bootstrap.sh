#!/usr/bin/env bash
# One-command install and update: downloads the latest release and runs its installer.
set -euo pipefail

# Everything is inside main so a dropped connection can't run half of this script.
main() {
    url=https://github.com/anil0403/tahoe-gnome/releases/latest/download/tahoe-gnome.tar.gz
    for cmd in curl tar; do
        command -v "$cmd" >/dev/null || { echo "error: missing required command: $cmd" >&2; exit 1; }
    done
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" | tar -xz -C "$tmp"
    "$tmp/tahoe-gnome/install.sh" </dev/null
}

main
