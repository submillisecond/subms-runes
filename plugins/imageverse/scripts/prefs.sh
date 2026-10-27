#!/usr/bin/env bash
# prefs: .sh port of prefs.ps1 (remember the organize scheme per folder).
# prefs.sh get --dir d | set --dir d --albums a,b [--op move|copy] [--scheme s]. Contract: ../contract/CONTRACTS.md 2.9.
set -uo pipefail

ACTION="${1:-get}"; shift || true
DIR=""; ALBUMS=""; OP="move"; SCHEME="albums"; PLUGIN="imageverse"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --albums) ALBUMS="$2"; shift 2;;
    --op) OP="$2"; shift 2;;
    --scheme) SCHEME="$2"; shift 2;;
    --plugin) PLUGIN="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$DIR" ] || { echo "PREFS_ERROR=missing --dir"; exit 1; }

dbase="${XDG_DATA_HOME:-$HOME/.local/share}"
[ "$(uname -s)" = "Darwin" ] && dbase="$HOME/Library/Application Support"
file="$dbase/runes/$PLUGIN/prefs.tsv"
# normalize key: absolute path, no trailing slash, lowercased
key="$(cd "$DIR" 2>/dev/null && pwd || echo "$DIR")"; key="${key%/}"
key="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"

case "$ACTION" in
  set)
    mkdir -p "$(dirname "$file")"
    tmp="$(mktemp)"
    [ -f "$file" ] && awk -F'\t' -v k="$key" '$1!=k' "$file" > "$tmp"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$key" "$DIR" "$SCHEME" "$OP" "$ALBUMS" "$(date +%Y-%m-%dT%H:%M:%S)" >> "$tmp"
    mv "$tmp" "$file"
    echo "PREFS_SAVED=$DIR" ;;
  *)
    [ -f "$file" ] || { echo "PREFS_NONE=1"; exit 0; }
    line="$(awk -F'\t' -v k="$key" '$1==k{print; exit}' "$file")"
    [ -n "$line" ] || { echo "PREFS_NONE=1"; exit 0; }
    IFS=$'\t' read -r _k d sc op al up <<< "$line"
    echo "PREFS_DIR=$d"; echo "PREFS_SCHEME=$sc"; echo "PREFS_OP=$op"; echo "PREFS_ALBUMS=$al"; echo "PREFS_UPDATED=$up" ;;
esac
