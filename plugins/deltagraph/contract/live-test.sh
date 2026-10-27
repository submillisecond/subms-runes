#!/usr/bin/env bash
# live-test: check the hosted engine still serves every tool the pack names, renders dg-url links and answers dg-debug.
# live-test.sh [--host URL]   (default: .mcp.json's URL without /mcp). Runs nightly in CI.
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
VIEWER="https://www.submillisecond.com/deltagraph"
echo "host: $HOST"

echo "== 1. every tool the pack names is served =="
LIST="$(curl -sS --max-time 30 -X POST "$HOST/mcp" -H 'content-type: application/json' \
  -H 'accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}')"
SERVED="$(printf '%s' "$LIST" | grep -oE '"name": *"deltagraph_[a-z_]+"' | grep -oE 'deltagraph_[a-z_]+' | sort -u)"
[ -n "$SERVED" ] && ok || bad "tools/list returned no deltagraph tools: $(printf '%s' "$LIST" | head -c 200)"
NAMED="$(cat "$PACK"/skills/*/SKILL.md "$HERE/CONTRACTS.md" | grep -oE 'deltagraph_[a-z_]+' | sort -u)"
for t in $NAMED; do
  if printf '%s\n' "$SERVED" | grep -qxF "$t"; then ok; else bad "the pack names $t and the server does not serve it"; fi
done
echo "  named: $(printf '%s ' $NAMED)"

init() { curl -sS --max-time 30 -X POST "$HOST/mcp" -H 'content-type: application/json' -H "X-Runes-Pack: $1" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'; }
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$PACK/.claude-plugin/plugin.json" | head -1)"
has "an outdated plugin is told to upgrade" "$(init deltagraph/0.0.1)" 'plugin marketplace update subms-runes'
if init "deltagraph/$VERSION" | grep -q '"instructions"'; then bad "this plugin ($VERSION) is below the server's minimum"; else ok; fi

echo "== 2. dg-url links render on the server =="
FIX="$T/fix.dg"; printf 'direction: left_right\nfeed[feed] --> book[(book)]\nbook --> risk{risk}\n' > "$FIX"
PLAIN="$(bash "$SCRIPTS/dg-url.sh" "$FIX" | sed -n 's/^URL=//p')"
PACKED="$(bash "$SCRIPTS/dg-url.sh" "$FIX" --compress | sed -n 's/^URL=//p')"
get() { curl -sS --max-time 30 -o /dev/null -w '%{http_code} %{content_type}' "$1"; }
has "svg from a #dsl= link" "$(get "$HOST/svg?${PLAIN#*#}")" '^200 image/svg\+xml'
has "png from a #d1= link" "$(get "$HOST/png?${PACKED#*#}")" '^200 image/png'
has "viewer is up" "$(get "$VIEWER")" '^200 text/html'
has "viewer skill.md names the debug tool" "$(curl -sS --max-time 30 "$VIEWER/skill.md")" 'deltagraph_debug'

echo "== 3. dg-debug against the live /debug =="
OUT="$(bash "$SCRIPTS/dg-debug.sh" "$FIX" --host "$HOST" --no-optimise)"; RC=$?
eq "clean source exits 0" "$RC" "0"
BAD="$T/bad.dg"; printf 'a[A] --> b[B] --> c[C]\n' > "$BAD"
OUT="$(bash "$SCRIPTS/dg-debug.sh" "$BAD" --host "$HOST")"; RC=$?
eq "broken source exits 1" "$RC" "1"
has "broken source names the rule" "$OUT" 'one-arrow-per-line'
SVG="$T/review.svg"
ERR="$(bash "$SCRIPTS/dg-debug.sh" "$FIX" --host "$HOST" --no-optimise --review "$SVG" 2>&1 >/dev/null)"
has "review path on stderr" "$ERR" '^REVIEW='
has "review file is an svg" "$(head -c 200 "$SVG" 2>/dev/null)" '<svg'

contract_result
