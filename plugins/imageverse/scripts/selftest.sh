#!/usr/bin/env bash
# selftest: .sh/.ps1 parity, bash -n, and thumbs.sh --sheet grid checks (grid needs ImageMagick, else skipped).
# Prints SELFTEST_PASS or SELFTEST_FAIL=<n>.
set -uo pipefail
sd="$(cd "$(dirname "$0")" && pwd)"
fails=0; note(){ echo "FAIL $*"; fails=$((fails+1)); }

# 1) parity
for f in "$sd"/*.ps1; do b="$(basename "$f" .ps1)"; [ "$b" = selftest ] && continue; [ -f "$sd/$b.sh" ] || note "PARITY: $b.ps1 has no .sh"; done
for f in "$sd"/*.sh; do b="$(basename "$f" .sh)"; [ "$b" = selftest ] && continue; [ -f "$sd/$b.ps1" ] || note "PARITY: $b.sh has no .ps1"; done
echo "CHECK parity"

# 2) parse every .sh
for f in "$sd"/*.sh; do bash -n "$f" 2>/dev/null || note "PARSE: $(basename "$f")"; done
echo "CHECK parse"

# 3) grid no-blank (needs ImageMagick)
MAGICK="$(command -v magick || command -v convert || true)"
if [ -n "$MAGICK" ] && { command -v magick >/dev/null 2>&1 || command -v montage >/dev/null 2>&1; }; then
  t="$(mktemp -d)"; : > "$t/list.txt"
  for i in $(seq 0 19); do "$MAGICK" -size 400x300 "xc:rgb($((60+9*i)),90,$((200-7*i)))" "$t/img_$i.png" 2>/dev/null; echo "$t/img_$i.png" >> "$t/list.txt"; done
  bash "$sd/thumbs.sh" --list "$t/list.txt" --sheet 20 --cols 7 --sheet-cell 120 --dense --out "$t/out" >/dev/null 2>&1 || true
  if [ -f "$t/out/sheet001.png" ]; then
    # sample 20 cell centres; count those equal to the clear colour (20,20,20)
    blank=$("$MAGICK" "$t/out/sheet001.png" -resize 7x3! txt:- 2>/dev/null | awk -F'[(),]' '/srgb|gray/{r=$2;g=$3;b=$4; if(r<24&&g<24&&b<24)n++} END{print n+0}')
    [ "${blank:-0}" -gt 0 ] && note "GRID: $blank blank cell(s) - row math regressed"
    echo "CHECK grid: blank=${blank:-0}"
  else note "GRID: thumbs.sh produced no sheet"; fi
  rm -rf "$t"
else echo "CHECK grid: SKIPPED (ImageMagick not installed)"; fi

if [ "$fails" -eq 0 ]; then echo "SELFTEST_PASS"; else echo "SELFTEST_FAIL=$fails"; fi
