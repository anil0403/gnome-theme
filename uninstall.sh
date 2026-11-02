#!/usr/bin/env bash
# Removes the theme and restores what install.sh replaced.
set -euo pipefail

STATE=${XDG_STATE_HOME:-$HOME/.local/state}/gnome-theme
[ -e "$STATE/backup-done" ] || { echo 'error: nothing to uninstall' >&2; exit 1; }

while read -r p; do
    rm -rf -- "$p"
    if [ -e "$STATE/backup$p" ] || [ -L "$STATE/backup$p" ]; then
        cp -a "$STATE/backup$p" "$p"
    fi
done < "$STATE/paths"

# Only the keys install.sh touched, so later changes to other settings survive.
while IFS=$'\t' read -r key value; do
    if [ -n "$value" ]; then dconf write "$key" "$value"; else dconf reset "$key"; fi
done < "$STATE/dconf-before.tsv"

rm -rf "$STATE"
echo 'Done. Log out and back in to finish.'
