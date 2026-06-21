#!/usr/bin/env bash
# journal - browse + revert the file-ops run history. macOS/Linux backend
# (see journal.ps1). Every apply writes a durable reverse-manifest journal to the
# runes app-data dir, per plugin: <data>/runes/<plugin>/journals/. This scans all.
#   list            (default) journals newest-first: [plugin] name, when, # moves, albums
#   show <name>     print a journal's contents
#   revert <name>   undo that run (re-applies the reverse manifest via file-ops)
# <name> matches the journal file name (or full path).
set -uo pipefail

ACTION="${1:-list}"; NAME="${2:-}"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dbase="${XDG_DATA_HOME:-$HOME/.local/share}"
[ "$(uname -s)" = "Darwin" ] && dbase="$HOME/Library/Application Support"
ROOT="$dbase/runes"

if [ ! -d "$ROOT" ]; then echo "JOURNAL_ROOT=$ROOT"; echo "JOURNAL_COUNT=0"; exit 0; fi

resolve() {
  [ -z "${1:-}" ] && return 1
  if [ -f "$1" ]; then echo "$1"; return 0; fi
  f="$(find "$ROOT" -path '*/journals/*.tsv' \( -name "$1" -o -name "$1.tsv" \) 2>/dev/null | head -1)"
  [ -n "$f" ] && { echo "$f"; return 0; }
  return 1
}

case "$ACTION" in
  show)
    f="$(resolve "$NAME")" || { echo "JOURNAL_ERROR=no such journal '$NAME'"; exit 1; }
    cat "$f" ;;
  revert)
    f="$(resolve "$NAME")" || { echo "JOURNAL_ERROR=no such journal '$NAME'"; exit 1; }
    echo "Reverting $(basename "$f") ..."
    # --restore: reverse moves + prune emptied folders; journaled so it can be redone.
    plugin="$(basename "$(dirname "$(dirname "$f")")")"
    bash "$SELF_DIR/file-ops.sh" --manifest "$f" --restore --plugin "$plugin" ;;
  *)
    echo "JOURNAL_ROOT=$ROOT"
    # newest first by mtime across all plugins
    list="$(find "$ROOT" -path '*/journals/*.tsv' -printf '%T@\t%p\n' 2>/dev/null | sort -rn | cut -f2-)"
    [ -z "$list" ] && list="$(find "$ROOT" -path '*/journals/*.tsv' 2>/dev/null)"
    echo "JOURNAL_COUNT=$(printf '%s\n' "$list" | grep -c .)"
    printf '%s\n' "$list" | grep . | while IFS= read -r f; do
      plugin="$(basename "$(dirname "$(dirname "$f")")")"
      moves="$(grep -c $'^move\t' "$f" 2>/dev/null || echo 0)"
      roots="$(awk -F'\t' '/^move\t/{n=split($2,a,"/"); print a[n-1]}' "$f" 2>/dev/null | sort -u | paste -sd, -)"
      when="$(date -r "$f" '+%Y-%m-%d %H:%M' 2>/dev/null || echo '?')"
      printf '  [%s] %s  %s  %s moves  -> %s\n' "$plugin" "$(basename "$f")" "$when" "$moves" "$roots"
    done ;;
esac
