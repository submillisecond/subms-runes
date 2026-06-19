#!/usr/bin/env bash
# photo-scan.sh - macOS/Linux mirror of photo-scan.ps1.
#   --dir PATH (required)   --recurse   --hash
# Output: PHOTO_DIR=, PHOTO_COUNT=, then  <YYYY-MM-DD HH:MM:SS>\t<size>\t<sha1|>\t<path>
# Date = EXIF DateTimeOriginal via exiftool when available, else file mtime.
# NOTE: the Windows .ps1 is the verified backend; verify this on macOS/Linux.
# EXIF dates need `exiftool`; hashing needs sha1sum/shasum.
set -u
dir=""; recurse=0; hash=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dir) dir="${2:-}"; shift 2 ;;
        --recurse) recurse=1; shift ;;
        --hash) hash=1; shift ;;
        *) shift ;;
    esac
done
{ [ -n "$dir" ] && [ -d "$dir" ]; } || { echo "PHOTO_COUNT=0"; echo "PHOTO_NOTE=no such folder: $dir"; exit 0; }

have() { command -v "$1" >/dev/null 2>&1; }
hashcmd=""
if have sha1sum; then hashcmd="sha1sum"; elif have shasum; then hashcmd="shasum -a 1"; fi
if stat -c '%Y' . >/dev/null 2>&1; then mtime() { stat -c '%Y' "$1"; }; else mtime() { stat -f '%m' "$1"; }; fi
fmtdate() {
    if date -d @0 +%s >/dev/null 2>&1; then date -d "@$1" '+%Y-%m-%d %H:%M:%S'; else date -r "$1" '+%Y-%m-%d %H:%M:%S'; fi
}
exifdate() {
    have exiftool || return 0
    exiftool -s3 -DateTimeOriginal -d '%Y-%m-%d %H:%M:%S' "$1" 2>/dev/null
}

maxdepth=""; [ "$recurse" = 0 ] && maxdepth="-maxdepth 1"
files="$(find "$dir" $maxdepth -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' -o -iname '*.heif' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.webp' \) 2>/dev/null)"

echo "PHOTO_DIR=$dir"
echo "PHOTO_COUNT=$(printf '%s\n' "$files" | grep -c .)"
printf '%s\n' "$files" | grep . | while IFS= read -r f; do
    d="$(exifdate "$f")"
    [ -n "$d" ] || d="$(fmtdate "$(mtime "$f")")"
    size="$(wc -c < "$f" | tr -d ' ')"
    h=""
    if [ "$hash" = 1 ] && [ -n "$hashcmd" ]; then h="$($hashcmd "$f" 2>/dev/null | awk '{print toupper($1)}')"; fi
    printf '%s\t%s\t%s\t%s\n' "$d" "$size" "$h" "$f"
done
