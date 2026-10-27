#!/usr/bin/env bash
# montage: .sh port of montage.ps1 (one deduplicated, shuffled contact sheet; images only). Needs ImageMagick.
# montage.sh --dir d | --list f [--out d] [--cols 8] [--cell 300] [--dist 10] [--max N] [--indexed] [--plugin p]
set -uo pipefail

dir=""; list=""; out=""; cols=8; cell=300; dist=10; max=0; indexed=0; plugin="imageverse"
while [ $# -gt 0 ]; do
  case "$1" in
    --dir) dir="${2:-}"; shift 2;; --list) list="${2:-}"; shift 2;; --out) out="${2:-}"; shift 2;;
    --cols) cols="${2:-8}"; shift 2;; --cell) cell="${2:-300}"; shift 2;; --dist) dist="${2:-10}"; shift 2;;
    --max) max="${2:-0}"; shift 2;; --indexed) indexed=1; shift;; --plugin) plugin="${2:-imageverse}"; shift 2;;
    *) shift;;
  esac
done
sd="$(cd "$(dirname "$0")" && pwd)"
iext='\.(jpg|jpeg|png|heic|heif|gif|bmp|tif|tiff|webp)$'
tmp="${TMPDIR:-/tmp}/runes/$plugin/_montwork_$$"; mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

# 1) gather images only
imglist="$tmp/imgs.txt"
if [ -n "$dir" ]; then find "$dir" -maxdepth 1 -type f 2>/dev/null | grep -iE "$iext" | sort > "$imglist"
elif [ -n "$list" ] && [ -f "$list" ]; then grep -iE "$iext" "$list" > "$imglist" || true
else echo "MONTAGE_ERROR=need --dir or --list"; exit 1; fi
total=$(grep -c . "$imglist" 2>/dev/null || echo 0)
if [ "$total" -eq 0 ]; then echo "MONTAGE_ERROR=no images found"; exit 1; fi
if [ -z "$out" ]; then nm="$(basename "${dir:-montage}" | sed 's/[^A-Za-z0-9]/_/g')"; out="${TMPDIR:-/tmp}/runes/$plugin/montages/$nm"; fi
mkdir -p "$out"

# 2) dedup via perceptual hash (one rep per distinct shot); fall back to all images
reps="$tmp/reps.txt"; : > "$reps"
bash "$sd/phash.sh" hash --list "$imglist" --out "$tmp/ph.tsv" >/dev/null 2>&1 || true
if [ -s "$tmp/ph.tsv" ]; then
  bash "$sd/phash.sh" group --in "$tmp/ph.tsv" --max-dist "$dist" 2>/dev/null \
    | awk -F'\t' '/^GROUP/{n=split($4,a,","); print a[1]}' > "$reps" || true
fi
[ -s "$reps" ] || cp "$imglist" "$reps"

# 3) random order
if command -v shuf >/dev/null 2>&1; then shuf "$reps" > "$tmp/shuf.txt"
else awk 'BEGIN{srand()}{print rand()"\t"$0}' "$reps" | sort | cut -f2- > "$tmp/shuf.txt"; fi
N=$(grep -c . "$tmp/shuf.txt")

# optional cap: even sample across the list
if [ "$max" -gt 0 ] && [ "$N" -gt "$max" ]; then
  awk -v n="$N" -v m="$max" '{a[NR]=$0} END{for(i=0;i<m;i++) print a[int(i*n/m)+1]}' "$tmp/shuf.txt" > "$tmp/cap.txt"
  mv "$tmp/cap.txt" "$tmp/shuf.txt"; N=$max
fi

# 4) ONE sheet, fixed cols, trim to full rows so there are NO blank cells
[ "$cols" -lt 1 ] && cols=1
[ "$cols" -gt "$N" ] && cols=$N
rows=$(( N / cols )); [ "$rows" -lt 1 ] && rows=1
keep=$(( cols * rows ))
head -n "$keep" "$tmp/shuf.txt" > "$tmp/tiles.txt"
cc=$(( 2400 / cols )); [ "$cc" -gt "$cell" ] && cc=$cell; [ "$cc" -lt 140 ] && cc=140

if [ "$indexed" = 1 ]; then
  bash "$sd/thumbs.sh" --list "$tmp/tiles.txt" --sheet "$keep" --cols "$cols" --sheet-cell "$cc" --out "$out" >/dev/null 2>&1 || true
else
  bash "$sd/thumbs.sh" --list "$tmp/tiles.txt" --sheet "$keep" --cols "$cols" --sheet-cell "$cc" --dense --out "$out" >/dev/null 2>&1 || true
fi

# 5) co-located list.txt: cell index -> source
awk '{printf "%03d\t%s\n", NR, $0}' "$tmp/tiles.txt" > "$out/list.txt"

sheets=$(find "$out" -maxdepth 1 -name 'sheet*.png' 2>/dev/null | wc -l | tr -d ' ')
echo "MONTAGE_DIR=$out"
echo "MONTAGE_SHEETS=$sheets"
echo "MONTAGE_CELLS=$keep shown of $total images ($cols cols; random order; videos excluded)"
find "$out" -maxdepth 1 -name 'sheet*.png' 2>/dev/null | sort
