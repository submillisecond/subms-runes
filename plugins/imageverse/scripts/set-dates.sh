#!/usr/bin/env bash
# set-dates - set each file's modified-time to its CAPTURE date, read from the
# organised filename (`...-YYYY-MM-DD-HHMMSS...`). WhatsApp/messenger images lose
# EXIF, so after organizing they carry the DOWNLOAD date and sort wrong in
# Finder/file managers - this rewrites the timestamp to the real/inferred capture
# date the organiser put in the name. Touches timestamps only, never content.
# (set-dates.ps1 is the Windows backend.)
#   --dir folder (default .)   --no-recurse (top level only)
# Prints DATES_SET=<n> DATES_SKIPPED=<n>.
set -uo pipefail
dir="."; recurse=1
while [ $# -gt 0 ]; do
  case "$1" in --dir) dir="${2:-.}"; shift 2;; --no-recurse) recurse=0; shift;; *) shift;; esac
done
[ -d "$dir" ] || { echo "DATES_ERROR=no such dir: $dir"; exit 1; }
# GNU date supports `touch -d "Y-M-D H:M:S"`; BSD/macOS needs `touch -t CCYYMMDDhhmm.ss`
gnu=0; date -d @0 +%s >/dev/null 2>&1 && gnu=1
maxdepth=""; [ "$recurse" = 0 ] && maxdepth="-maxdepth 1"
set_count=0; skip=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  b="$(basename "$f")"
  ds="$(printf '%s' "$b" | sed -n -E 's/.*([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2}).*/\1-\2-\3 \4:\5:\6/p')"
  if [ -n "$ds" ]; then
    if [ "$gnu" = 1 ]; then touch -d "$ds" "$f" 2>/dev/null && set_count=$((set_count+1)) || skip=$((skip+1))
    else
      # build CCYYMMDDhhmm.ss for BSD touch
      t="$(printf '%s' "$b" | sed -n -E 's/.*([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2}).*/\1\2\3\4\5.\6/p')"
      touch -t "$t" "$f" 2>/dev/null && set_count=$((set_count+1)) || skip=$((skip+1))
    fi
  else skip=$((skip+1)); fi
done <<EOF
$(find "$dir" $maxdepth -type f 2>/dev/null)
EOF
echo "DATES_SET=$set_count DATES_SKIPPED=$skip"
