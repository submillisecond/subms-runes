#!/usr/bin/env bash
# thumbs - batch-downscale images to thumbnails for cheap vision reads.
# macOS/Linux backend (sips built into macOS, else ImageMagick). The Windows
# backend is thumbs.ps1 (System.Drawing) - Windows has no guaranteed shell.
#   --path p          source image (repeatable)
#   --list file       OR a file of newline-separated source paths
#   --max N           longest-side px (default 1600: legible for screenshot text,
#                     still under the 2000px/side many-image cap so thumbs batch)
#   --plugin name     calling plugin/pack; namespaces the default temp (default misc)
#   --out dir         output dir (default $TMPDIR/runes/<plugin>/thumbs)
# Prints THUMB_DIR, THUMB_COUNT, then `<thumb>\t<source>` lines.
set -uo pipefail

MAX=1600; OUT=""; PLUGIN="misc"; SRCS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --path) SRCS+=("$2"); shift 2;;
    --list) while IFS= read -r l; do [ -n "$l" ] && SRCS+=("$l"); done < "$2"; shift 2;;
    --max) MAX="$2"; shift 2;;
    --plugin) PLUGIN="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    *) echo "THUMB_NOTE=unknown arg $1"; exit 1;;
  esac
done
[ -n "$OUT" ] || OUT="${TMPDIR:-/tmp}/runes/$PLUGIN/thumbs"
if [ ${#SRCS[@]} -eq 0 ]; then echo "THUMB_COUNT=0"; echo "THUMB_NOTE=no input (--path/--list)"; exit 0; fi
mkdir -p "$OUT"

MAGICK="$(command -v magick || command -v convert || true)"
SIPS="$(command -v sips || true)"
if [ -z "$MAGICK" ] && [ -z "$SIPS" ]; then
  echo "THUMB_COUNT=0"; echo "THUMB_NOTE=need sips (macOS) or ImageMagick (brew/apt install imagemagick)"; exit 1
fi

echo "THUMB_DIR=$OUT"
n=0; i=0; lines=(); t0="$(date +%s)"
for s in "${SRCS[@]}"; do
  i=$((i + 1)); [ -f "$s" ] || continue
  base="$(basename "${s%.*}")"
  idx="$(printf '%03d' "$i")"
  dest="$OUT/${idx}_${base}.png"
  if [ -n "$MAGICK" ]; then
    # Stamp the index badge top-left so the model maps each thumbnail to its source
    # by the VISIBLE number, not read order (kills the bulk-read off-by-one mislabel).
    "$MAGICK" "$s" -resize "${MAX}x${MAX}>" \
      -gravity NorthWest -fill yellow -undercolor '#000000c0' -pointsize 30 -annotate +2+2 " $idx " \
      "$dest" 2>/dev/null && { lines+=("$dest"$'\t'"$s"); n=$((n + 1)); }
  else
    # sips (macOS-only fallback) can resize but NOT draw text - no index stamp; on a
    # sips-only box read smaller batches so order stays trackable. Install ImageMagick for stamps.
    cp "$s" "$dest" && "$SIPS" -Z "$MAX" "$dest" >/dev/null 2>&1 && "$SIPS" -s format png "$dest" >/dev/null 2>&1 && { lines+=("$dest"$'\t'"$s"); n=$((n + 1)); }
  fi
done
echo "THUMB_COUNT=$n"
echo "THUMB_SECONDS=$(( $(date +%s) - t0 ))"
for l in "${lines[@]:-}"; do [ -n "$l" ] && printf '%s\n' "$l"; done
