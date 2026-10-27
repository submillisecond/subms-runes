#!/usr/bin/env bash
# dg-debug: post a diagram to the worker's /debug and print why it fails or reads badly. Contract: ../contract/CONTRACTS.md.
# dg-debug.sh <file|-> [--json] [--review out.svg] [--no-optimise] [--tries N] [--host URL]
set -eu

HOST_URL="https://deltagraph.submillisecond.com"
FILE=""; FORMAT="text"; REVIEW=""; Q=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) FORMAT="json"; shift ;;
    --review) REVIEW="${2:-}"; shift 2 ;;
    --no-optimise) Q="$Q&optimise=false"; shift ;;
    --tries) Q="$Q&tries=${2:-}"; shift 2 ;;
    --host) HOST_URL="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
    -) FILE="-"; shift ;;
    -*) echo "ERROR=unknown flag $1" >&2; exit 2 ;;
    *) FILE="$1"; shift ;;
  esac
done
[ -n "$FILE" ] || { echo "ERROR=no source file (pass a path or - for stdin)" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "ERROR=dg-debug needs curl on PATH" >&2; exit 2; }

TMP="$(mktemp)"; OUT="$(mktemp)"
trap 'rm -f "$TMP" "$OUT"' EXIT
if [ "$FILE" = "-" ]; then tr -d '\r' > "$TMP"; else tr -d '\r' < "$FILE" > "$TMP"; fi

post() {
  curl -sS -m 30 -o "$OUT" -w '%{http_code}' -X POST -H 'content-type: text/plain; charset=utf-8' \
    --data-binary "@$TMP" "${HOST_URL%/}/debug?format=$1$Q" || { echo "ERROR=network: curl failed" >&2; exit 2; }
}

STATUS="$(post "$FORMAT")"
case "$STATUS" in 200|422) ;; *) echo "ERROR=worker answered $STATUS" >&2; exit 2 ;; esac
cat "$OUT"
[ -z "$(tail -c 1 "$OUT")" ] || printf '\n'

if [ -n "$REVIEW" ] && [ "$STATUS" = 200 ]; then
  if [ "$(post svg)" = 200 ]; then cp "$OUT" "$REVIEW"; echo "REVIEW=$REVIEW" >&2; fi
fi
[ "$STATUS" = 200 ]
