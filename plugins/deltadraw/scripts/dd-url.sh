#!/usr/bin/env bash
# dd-url: print a deltadraw viewer link (URL=, LENGTH=) for a scene file. Contract: ../contract/CONTRACTS.md.
# dd-url.sh <file|-> [--title T] [--theme light|dark] [--replay] [--edit] [--compress] [--base URL]
set -eu

BASE="https://www.submillisecond.com/deltadraw"
FILE=""; TITLE=""; THEME=""; REPLAY=0; EDIT=0; COMPRESS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --theme) THEME="${2:-}"; shift 2 ;;
    --base)  BASE="${2:-}"; shift 2 ;;
    --replay) REPLAY=1; shift ;;
    --edit)  EDIT=1; shift ;;
    --compress) COMPRESS=1; shift ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    -) FILE="-"; shift ;;
    -*) echo "ERROR=unknown flag $1" >&2; exit 2 ;;
    *) FILE="$1"; shift ;;
  esac
done
[ -n "$FILE" ] || { echo "ERROR=no scene file (pass a path or - for stdin)" >&2; exit 2; }

if [ "$FILE" = "-" ]; then SRC="$(cat)"; else SRC="$(cat "$FILE")"; fi
SRC="$(printf '%s' "$SRC" | tr -d '\r' | sed -e '/./,$!d')"

# Percent-encode over the UTF-8 bytes, so both backends agree byte for byte.
enc() {
  printf '%s' "$1" | od -An -v -tu1 | tr -s ' ' '\n' | while IFS= read -r b; do
    [ -n "$b" ] || continue
    if { [ "$b" -ge 48 ] && [ "$b" -le 57 ]; } || { [ "$b" -ge 65 ] && [ "$b" -le 90 ]; } \
       || { [ "$b" -ge 97 ] && [ "$b" -le 122 ]; } \
       || [ "$b" -eq 45 ] || [ "$b" -eq 95 ] || [ "$b" -eq 46 ] || [ "$b" -eq 126 ]; then
      # shellcheck disable=SC2059
      printf "$(printf '\\%03o' "$b")"
    else
      printf '%%%02X' "$b"
    fi
  done
}

pack() {
  command -v gzip >/dev/null 2>&1 || { echo "ERROR=--compress needs gzip on PATH" >&2; exit 2; }
  tmp="$(mktemp)"
  printf '%s' "$1" | gzip -c -n -9 > "$tmp"
  n="$(wc -c < "$tmp" | tr -d ' ')"
  # A gzip member minus its 10-byte header and 8-byte trailer is raw DEFLATE.
  tail -c +11 "$tmp" | head -c "$((n - 18))" | base64 | tr -d '\n=' | tr '+/' '-_'
  rm -f "$tmp"
}

if [ "$COMPRESS" = 1 ]; then URL="$BASE#d1=$(pack "$SRC")"; else URL="$BASE#dsl=$(enc "$SRC")"; fi
[ -n "$TITLE" ] && URL="$URL&title=$(enc "$TITLE")"
case "$THEME" in
  light|white) URL="$URL&theme=light" ;;
  dark|night)  URL="$URL&theme=dark" ;;
  "") ;;
  *) echo "ERROR=theme must be light or dark" >&2; exit 2 ;;
esac
[ "$REPLAY" = 1 ] && URL="$URL&replay"
[ "$EDIT" = 1 ] && URL="$URL&edit"

printf 'URL=%s\n' "$URL"
printf 'LENGTH=%s\n' "${#URL}"
