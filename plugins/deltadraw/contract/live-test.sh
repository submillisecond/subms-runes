#!/usr/bin/env bash
# live-test: check the hosted worker serves every tool the pack names, renders dd-url links and answers dd-png.
# live-test.sh [--host URL]   (default: .mcp.json's URL without /mcp).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PACK="$(cd "$HERE/.." && pwd)"
SCRIPTS="$PACK/scripts"
. "$HERE/../../../lib/test/contract-lib.sh"
contract_isolate

command -v curl >/dev/null 2>&1 || { echo "live-test: curl is required"; exit 2; }
MCP="$(sed -n 's/.*"url": *"\([^"]*\)".*/\1/p' "$PACK/.mcp.json" | head -1)"
HOST="${MCP%/mcp}"
[ "${1:-}" = "--host" ] && HOST="${2:-$HOST}"
VIEWER="https://www.submillisecond.com/deltadraw"
echo "host: $HOST"

echo "== 1. every tool the pack names is served =="
LIST="$(curl -sS --max-time 30 -X POST "$HOST/mcp" -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}')"
SERVED="$(printf '%s' "$LIST" | grep -oE '"name": *"deltadraw_[a-z_]+"' | grep -oE 'deltadraw_[a-z_]+' | sort -u)"
[ -n "$SERVED" ] && ok || bad "tools/list returned no deltadraw tools: $(printf '%s' "$LIST" | head -c 200)"
NAMED="$(cat "$PACK"/skills/*/SKILL.md "$HERE/CONTRACTS.md" | grep -oE 'deltadraw_[a-z_]+' | sort -u)"
for t in $NAMED; do
  if printf '%s\n' "$SERVED" | grep -qxF "$t"; then ok; else bad "the pack names $t and the server does not serve it"; fi
done

echo "== 2. dd-url links render on the worker =="
FIX="$T/fix.scene"; printf 'canvas 400x200 bg #0b0a22\ncircle 200,100 50 fill #ffe9a8 glow 30\nuse @fin at 300,170\n' > "$FIX"
PLAIN="$(bash "$SCRIPTS/dd-url.sh" "$FIX" | sed -n 's/^URL=//p')"
PACKED="$(bash "$SCRIPTS/dd-url.sh" "$FIX" --compress | sed -n 's/^URL=//p')"
get() { curl -sS --max-time 30 -o /dev/null -w '%{http_code} %{content_type}' "$1"; }
has "svg from a #dsl= link" "$(get "$HOST/svg?${PLAIN#*#}")" '^200 image/svg\+xml'
has "png from a #d1= link" "$(get "$HOST/png?${PACKED#*#}")" '^200 image/png'
has "viewer is up" "$(get "$VIEWER")" '^200 text/html'

echo "== 3. dd-png against the live /png =="
OUT="$(bash "$SCRIPTS/dd-png.sh" "$FIX" --out "$T/out.png" --width 400 --host "$HOST")"; RC=$?
eq "clean scene exits 0" "$RC" "0"
has "PNG= line" "$OUT" '^PNG='
BAD="$T/bad.scene"; printf 'canvas 10x10\n' > "$BAD"
bash "$SCRIPTS/dd-png.sh" "$BAD" --out "$T/bad.png" --host "$HOST" >/dev/null 2>&1; RC=$?
eq "a scene that draws nothing exits 1" "$RC" "1"

echo "== 4. animation: a page as PNG, the pages as a GIF =="
ANIM="$T/anim.scene"; printf 'canvas 400x200\ncircle 40,100 20 fill red id ball\ntween 3\npage\ncircle 360,100 20 fill blue id ball\n' > "$ANIM"
OUT="$(bash "$SCRIPTS/dd-png.sh" "$ANIM" --out "$T/p2.png" --width 200 --page 2 --host "$HOST")"; RC=$?
eq "a page of an animation exits 0" "$RC" "0"
OUT="$(bash "$SCRIPTS/dd-gif.sh" "$ANIM" --out "$T/a.gif" --width 200 --host "$HOST")"; RC=$?
eq "dd-gif exits 0" "$RC" "0"
has "GIF= line" "$OUT" '^GIF='
has "the file is a GIF" "$(head -c 6 "$T/a.gif")" '^GIF89a'

contract_result
