#!/bin/bash
# Read-only: list Obsidian vaults on this machine, to catch copies before a new
# vault duplicates one. Usage: find-local-vaults.sh [root ...] (default: $HOME).
# One line per vault: <path> kind=<project|plain> origin=<url|-> last=<date|nogit>.
# Also lists the vault paths Obsidian has registered.
[ $# -gt 0 ] || set -- "$HOME"
for f in "$HOME/.config/obsidian/obsidian.json" "$HOME/Library/Application Support/obsidian/obsidian.json"; do
  [ -f "$f" ] && python3 -c 'import json,sys
for v in json.load(open(sys.argv[1])).get("vaults", {}).values(): print("registered: " + v.get("path", "?"))' "$f"
done
for root in "$@"; do
  [ -d "$root" ] || continue
  find "$root" -maxdepth 5 \( -name node_modules -o -name Library -o -name .Trash -o -name .cache -o -name .git \) -prune \
    -o -type d -name .obsidian -print 2>/dev/null | while IFS= read -r o; do
    v=$(dirname "$o"); kind=plain
    [ -f "$v/AGENTS.md" ] && [ -f "$v/HOME.md" ] && [ -d "$v/bases" ] && kind=project
    origin=$(git -C "$v" remote get-url origin 2>/dev/null || echo -)
    last=$(git -C "$v" log -1 --format=%cs 2>/dev/null || echo nogit)
    echo "$v kind=$kind origin=$origin last=$last"
  done
done
