#!/usr/bin/env bash
# file-ops - apply a batch of file operations from a manifest, collision-safe.
# macOS/Linux backend (mv/cp). The Windows backend is file-ops.ps1.
#   --manifest file   tab-separated: op<TAB>src<TAB>dest   (op = move | copy)
#   --apply           FORWARD migration (default is a DRY RUN)
#   --restore         REVERSE/undo run: same moves, then prune folders this run
#                     leaves EMPTY. Implies --prune. Used by `journal revert`.
#   --prune           with --apply, remove SOURCE folders this run leaves empty
#                     (re-organizing into a new scheme vacates old album dirs).
#                     Truly-empty dirs only.
#   --plugin name     calling plugin/pack; namespaces the journal dir (default misc)
#   --journal file    override the auto reverse-manifest journal path
# Both --apply and --restore write a fresh journal (apply is revertible, restore
# is redoable). Prints PLAN/DONE + OPS_* summary. Never overwrites (appends (2),...).
set -uo pipefail

MANIFEST=""; APPLY=0; RESTORE=0; PRUNE=0; JOURNAL=""; PLUGIN="misc"
while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="$2"; shift 2;;
    --apply) APPLY=1; shift;;
    --restore) RESTORE=1; shift;;
    --prune) PRUNE=1; shift;;
    --plugin) PLUGIN="$2"; shift 2;;
    --journal) JOURNAL="$2"; shift 2;;
    *) echo "OPS_ERROR=unknown arg $1"; exit 1;;
  esac
done
[ -n "$MANIFEST" ] && [ -f "$MANIFEST" ] || { echo "OPS_ERROR=missing or unreadable --manifest"; exit 1; }
RUN=0; { [ "$APPLY" = 1 ] || [ "$RESTORE" = 1 ]; } && RUN=1
DOPRUNE=0; { [ "$RESTORE" = 1 ] || [ "$PRUNE" = 1 ]; } && DOPRUNE=1

# Default the journal to a DURABLE, per-PLUGIN app-data location (never temp).
if [ "$RUN" = 1 ] && [ -z "$JOURNAL" ]; then
  dbase="${XDG_DATA_HOME:-$HOME/.local/share}"
  [ "$(uname -s)" = "Darwin" ] && dbase="$HOME/Library/Application Support"
  jtag=apply; [ "$RESTORE" = 1 ] && jtag=restore
  JOURNAL="$dbase/runes/$PLUGIN/journals/$jtag-$(date +%Y%m%d-%H%M%S)-$$.tsv"
fi

done_n=0; skip=0; errs=0
rev=()
rev+=('# runes journal (reverse manifest) - undo/redo this run with: journal revert "<this file name>"')

# Snapshot which dest dirs already exist (bash-3.2-safe via temp files, no assoc
# arrays). srctmp collects source dirs so --restore can prune the emptied ones.
dirstate="$(mktemp)"; addtmp="$(mktemp)"; srctmp="$(mktemp)"
awk -F'\t' '!/^#/ && NF>=3 { d=$3; sub(/\/[^\/]*$/,"",d); print d }' "$MANIFEST" | awk '!seen[$0]++' | while IFS= read -r d; do
  [ -n "$d" ] || continue
  if [ -d "$d" ]; then printf 'existing\t%s\n' "$d"; else printf 'new\t%s\n' "$d"; fi
done > "$dirstate"

while IFS=$'\t' read -r op src dest rest || [ -n "${op:-}" ]; do
  [ -z "${op:-}" ] && continue
  case "$op" in \#*) continue;; esac
  if [ -z "${dest:-}" ]; then errs=$((errs + 1)); echo "OPS_BAD=$op"; continue; fi
  if [ "$op" != move ] && [ "$op" != copy ]; then errs=$((errs + 1)); echo "OPS_BAD_OP=$op"; continue; fi
  if [ ! -e "$src" ]; then skip=$((skip + 1)); printf 'SKIP_MISSING\t%s\n' "$src"; continue; fi
  dir="$(dirname "$dest")"; stem="$(basename "${dest%.*}")"; ext=".${dest##*.}"
  final="$dest"; k=2
  while [ -e "$final" ]; do final="$dir/$stem ($k)$ext"; k=$((k + 1)); done
  printf '%s\n' "$dir" >> "$addtmp"
  printf '%s\n' "$(dirname "$src")" >> "$srctmp"
  if [ "$RUN" = 1 ]; then
    mkdir -p "$dir"
    if [ "$op" = move ]; then mv "$src" "$final" && { done_n=$((done_n + 1)); rev+=("$(printf 'move\t%s\t%s' "$final" "$src")"); } || errs=$((errs + 1)); fi
    if [ "$op" = copy ]; then cp "$src" "$final" && { done_n=$((done_n + 1)); rev+=("# copy - to undo, delete: $final"); } || errs=$((errs + 1)); fi
    printf 'DONE\t%s\t%s\t%s\n' "$op" "$src" "$final"
  else
    printf 'PLAN\t%s\t%s\t%s\n' "$op" "$src" "$final"; done_n=$((done_n + 1))
  fi
done < "$MANIFEST"
if [ "$RUN" = 1 ] && [ -n "$JOURNAL" ] && [ "$done_n" -gt 0 ]; then
  mkdir -p "$(dirname "$JOURNAL")"
  printf '%s\n' "${rev[@]}" > "$JOURNAL"
  echo "OPS_JOURNAL=$JOURNAL"
fi

# Prune ONLY the source dirs this run left truly empty (--restore or --prune).
pruned=0
if [ "$DOPRUNE" = 1 ]; then
  while IFS= read -r sd; do
    [ -n "$sd" ] && [ -d "$sd" ] || continue
    if [ -z "$(ls -A "$sd" 2>/dev/null)" ]; then rmdir "$sd" 2>/dev/null && { pruned=$((pruned + 1)); printf 'PRUNED\t%s\n' "$sd"; }; fi
  done < <(awk '!seen[$0]++' "$srctmp")
fi

# Per-dir summary: new/existing, files added this run, total files now, subfolders.
newd=0; exd=0
while IFS=$'\t' read -r tag d; do
  [ -n "$d" ] || continue
  [ "$tag" = new ] && newd=$((newd + 1)) || exd=$((exd + 1))
  add="$(grep -cxF "$d" "$addtmp" 2>/dev/null || echo 0)"
  if [ -d "$d" ]; then
    total="$(find "$d" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
    subs="$(find "$d" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  else total=0; subs=0; fi
  printf 'OPS_DIR\t%s\t%s\t%s\t%s\t%s\n' "$d" "$tag" "$add" "$total" "$subs"
done < "$dirstate"
rm -f "$dirstate" "$addtmp" "$srctmp"

if [ "$RESTORE" = 1 ]; then echo "OPS_MODE=restore"; elif [ "$APPLY" = 1 ]; then echo "OPS_MODE=apply"; else echo "OPS_MODE=dry-run"; fi
echo "OPS_DIRS_NEW=$newd OPS_DIRS_EXISTING=$exd OPS_PRUNED=$pruned"
echo "OPS_DONE=$done_n OPS_SKIP=$skip OPS_ERR=$errs"
