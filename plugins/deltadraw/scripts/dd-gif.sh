#!/usr/bin/env bash
# dd-gif: post a scene to the worker's /gif and save the animation (pages as frames, or the drawing being made). Contract: ../contract/CONTRACTS.md. Port of dd-gif.ps1.
# dd-gif.sh <file|-> --out out.gif [--mode pages|replay] [--width N] [--host URL]
set -eu

HOST_URL="https://deltadraw.submillisecond.com"
FILE=""; OUTFILE=""; WIDTH="720"; MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUTFILE="${2:-}"; shift 2 ;;
    --width) WIDTH="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --host) HOST_URL="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    -) FILE="-"; shift ;;
    -*) echo "ERROR=unknown flag $1" >&2; exit 2 ;;
    *) FILE="$1"; shift ;;
  esac
done
[ -n "$FILE" ] || { echo "ERROR=no scene file (pass a path or - for stdin)" >&2; exit 2; }
[ -n "$OUTFILE" ] || { echo "ERROR=--out is required" >&2; exit 2; }
printf '%s' "$WIDTH" | grep -Eq '^[0-9]+$' || { echo "ERROR=width must be a whole number" >&2; exit 2; }
case "$MODE" in ""|pages|replay) ;; *) echo "ERROR=mode must be pages or replay" >&2; exit 2 ;; esac
command -v curl >/dev/null 2>&1 || { echo "ERROR=dd-gif needs curl on PATH" >&2; exit 2; }

TMP="$(mktemp)"; BODY="$(mktemp)"
trap 'rm -f "$TMP" "$BODY"' EXIT
if [ "$FILE" = "-" ]; then tr -d '\r' > "$TMP"; else tr -d '\r' < "$FILE" > "$TMP"; fi

Q="width=$WIDTH"; [ -n "$MODE" ] && Q="$Q&mode=$MODE"
STATUS="$(curl -sS -m 120 -o "$BODY" -w '%{http_code}' -X POST -H 'content-type: text/plain; charset=utf-8' \
  --data-binary "@$TMP" "${HOST_URL%/}/gif?$Q")" || { echo "ERROR=network: curl failed" >&2; exit 2; }
case "$STATUS" in
  200) cp "$BODY" "$OUTFILE"; echo "GIF=$OUTFILE"; echo "BYTES=$(wc -c < "$OUTFILE" | tr -d ' ')" ;;
  422) cat "$BODY" >&2; echo >&2; exit 1 ;;
  *) echo "ERROR=worker answered $STATUS" >&2; exit 2 ;;
esac
