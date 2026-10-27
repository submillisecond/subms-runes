#!/usr/bin/env bash
# contract-test - the executable spec for the deltagraph pack. Runs BOTH dg-url
# backends (.ps1 via powershell.exe where present, .sh in place) over one
# fixture that carries every character class the encoder has to get right, and
# asserts: identical plain output across backends; the URL decodes back to the
# fixture, plain or compressed; LENGTH is right; options land in the documented
# order and spelling; error paths exit 2 with ERROR= on stderr; every flag in
# CONTRACTS.md is real in both backends of both scripts; the MCP entry names
# the documented server; SKILL.md documents the options it relies on. No
# network, no viewer. Exits non-zero on drift.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/../scripts" && pwd)"
PACK="$(cd "$HERE/.." && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"
contract_isolate

FIX="$T/fix.dg"
# `&` `|` `#` `(` `)` `+` space, a trailing newline the trim must drop, and a
# multi-byte character (e-acute) so the UTF-8 byte walk is exercised.
printf 'direction: LR\n\n# Risk & PnL\nfeed((feed)) ==>|#hot decode| book[(book)] :::pulse\nbook -->|#read a+b (c)| strat{route?}\nnote[caf\303\251]\n\n' > "$FIX"
EXPECTED_SRC="$(printf 'direction: LR\n\n# Risk & PnL\nfeed((feed)) ==>|#hot decode| book[(book)] :::pulse\nbook -->|#read a+b (c)| strat{route?}\nnote[caf\303\251]')"

# Percent-decode a URL fragment value back to bytes (for the round-trip check).
pdecode() { printf '%b' "$(printf '%s' "$1" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')"; }
# Inflate a d1 value (raw DEFLATE, base64url) with whatever is on the box.
INFLATE=""
if command -v node >/dev/null 2>&1; then
  INFLATE="node"
  inflate() { node -e 'const s=process.argv[1].replace(/-/g,"+").replace(/_/g,"/");process.stdout.write(require("zlib").inflateRawSync(Buffer.from(s,"base64")))' "$1"; }
elif command -v python3 >/dev/null 2>&1; then
  INFLATE="python3"
  inflate() { python3 -c 'import sys,zlib,base64;s=sys.argv[1];s+="="*(-len(s)%4);sys.stdout.buffer.write(zlib.decompress(base64.urlsafe_b64decode(s),-15))' "$1"; }
fi

SH="bash $SCRIPTS/dg-url.sh"
DBG="bash $SCRIPTS/dg-debug.sh"
HAVE_PS=0
if command -v powershell.exe >/dev/null 2>&1; then
  HAVE_PS=1
  PSFIX="$FIX"; command -v cygpath >/dev/null 2>&1 && PSFIX="$(cygpath -w "$FIX")"
  PS="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $(cygpath -w "$SCRIPTS/dg-url.ps1" 2>/dev/null || echo "$SCRIPTS/dg-url.ps1")"
  PSDBG="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $(cygpath -w "$SCRIPTS/dg-debug.ps1" 2>/dev/null || echo "$SCRIPTS/dg-debug.ps1")"
fi

echo "== 1. output shape, both backends =="
OUT_SH="$($SH "$FIX")"
eq "sh: two lines" "$(printf '%s\n' "$OUT_SH" | wc -l | tr -d ' ')" "2"
has "sh: URL line" "$OUT_SH" '^URL=https://www\.submillisecond\.com/deltagraph#dsl='
has "sh: LENGTH line" "$OUT_SH" '^LENGTH=[0-9]+$'
URL_SH="$(printf '%s\n' "$OUT_SH" | sed -n 's/^URL=//p')"
eq "sh: LENGTH matches" "$(printf '%s\n' "$OUT_SH" | sed -n 's/^LENGTH=//p')" "${#URL_SH}"
if [ "$HAVE_PS" = 1 ]; then
  OUT_PS="$($PS "$PSFIX" | tr -d '\r')"
  eq "ps == sh (byte-identical)" "$OUT_PS" "$OUT_SH"
else
  echo "(powershell.exe not present: ps backend skipped)"
fi

echo "== 2. the URL decodes back to the trimmed fixture =="
ENC="${URL_SH#*#dsl=}"
has "no raw & in the fragment" "$ENC" '^[^&]*$'
has "no raw | in the fragment" "$ENC" '^[^|]*$'
has "only unreserved + %XX" "$ENC" '^[A-Za-z0-9._~%-]*$'
eq "round-trip" "$(pdecode "$ENC")" "$EXPECTED_SRC"
eq "stdin works" "$($SH - < "$FIX")" "$OUT_SH"
CRLF="$T/crlf.dg"; printf 'a[A] --> b[B]\r\nb --> c[C]\r\n' > "$CRLF"
eq "CRLF reads as LF" "$(pdecode "$($SH "$CRLF" | sed -n 's/^URL=.*#dsl=//p')")" "$(printf 'a[A] --> b[B]\nb --> c[C]')"

echo "== 3. compressed form: d1, base64url, inflates to the fixture =="
C_SH="$($SH "$FIX" --compress | sed -n 's/^URL=//p')"
has "sh: d1 key" "$C_SH" '^https://www\.submillisecond\.com/deltagraph#d1=[A-Za-z0-9_-]+$'
if [ -n "$INFLATE" ]; then
  eq "sh: d1 inflates to the fixture" "$(inflate "${C_SH#*#d1=}")" "$EXPECTED_SRC"
else
  echo "(no node or python3: inflate check skipped)"
fi
has "compressed is shorter" "$([ "${#C_SH}" -lt "${#URL_SH}" ] && echo yes || echo no)" '^yes$'
if [ "$HAVE_PS" = 1 ]; then
  C_PS="$($PS "$PSFIX" -Compress | tr -d '\r' | sed -n 's/^URL=//p')"
  has "ps: d1 key" "$C_PS" '#d1=[A-Za-z0-9_-]+$'
  [ -n "$INFLATE" ] && eq "ps: d1 inflates to the fixture" "$(inflate "${C_PS#*#d1=}")" "$EXPECTED_SRC"
fi

echo "== 4. options, in the documented order and spelling =="
OPT="$($SH "$FIX" --title 'Tick & trade' --theme white --bg '#ABC' --dir tb --debug --edit | sed -n 's/^URL=//p')"
has "options tail" "$OPT" '&title=Tick%20%26%20trade&theme=light&bg=aabbcc&dir=TD&debug=true&edit=true$'
for v in transparent black white auto; do
  has "bg $v" "$($SH "$FIX" --bg "$v" | sed -n 's/^URL=//p')" "&bg=$v\$"
done
has "bg 6-digit hex" "$($SH "$FIX" --bg 1A2B3C | sed -n 's/^URL=//p')" '&bg=1a2b3c$'
BASE="$($SH "$FIX" --base http://localhost:3030/deltagraph | sed -n 's/^URL=//p')"
has "base override" "$BASE" '^http://localhost:3030/deltagraph#dsl='
has "options ride the compressed form too" "$($SH "$FIX" --compress --title T --bg white | sed -n 's/^URL=//p')" '#d1=[A-Za-z0-9_-]+&title=T&bg=white$'
if [ "$HAVE_PS" = 1 ]; then
  OPT_PS="$($PS "$PSFIX" -Title 'Tick & trade' -Theme white -Bg '#ABC' -Dir tb -ShowDebug -Edit | tr -d '\r' | sed -n 's/^URL=//p')"
  eq "ps options == sh options" "$OPT_PS" "$OPT"
  eq "ps bg hex == sh bg hex" "$($PS "$PSFIX" -Bg 1A2B3C | tr -d '\r' | sed -n 's/^URL=//p')" "$($SH "$FIX" --bg 1A2B3C | sed -n 's/^URL=//p')"
fi

echo "== 5. error paths: exit 2, ERROR= on stderr, nothing on stdout =="
ERR="$($SH 2>&1 >/dev/null)"; RC=$?
eq "no file: rc" "$RC" "2"; has "no file: ERROR=" "$ERR" '^ERROR='
ERR="$($SH "$FIX" --theme sepia 2>&1 >/dev/null)"; RC=$?
eq "bad theme: rc" "$RC" "2"; has "bad theme: ERROR=" "$ERR" '^ERROR=theme'
ERR="$($SH "$FIX" --bg chartreuse 2>&1 >/dev/null)"; RC=$?
eq "bad bg: rc" "$RC" "2"; has "bad bg: ERROR=" "$ERR" '^ERROR=bg'
ERR="$($SH "$FIX" --dir diagonal 2>&1 >/dev/null)"; RC=$?
eq "bad dir: rc" "$RC" "2"; has "bad dir: ERROR=" "$ERR" '^ERROR=dir'
ERR="$($SH "$FIX" --nope 2>&1 >/dev/null)"; RC=$?
eq "unknown flag: rc" "$RC" "2"
ERR="$($DBG 2>&1 >/dev/null)"; RC=$?
eq "debug, no file: rc" "$RC" "2"; has "debug, no file: ERROR=" "$ERR" '^ERROR='
ERR="$($DBG "$FIX" --nope 2>&1 >/dev/null)"; RC=$?
eq "debug, unknown flag: rc" "$RC" "2"
if [ "$HAVE_PS" = 1 ]; then
  ERR="$($PS "$PSFIX" -Bg chartreuse 2>&1 >/dev/null | tr -d '\r')"
  has "ps bad bg: ERROR=" "$ERR" '^ERROR=bg'
  ERR="$($PSDBG 2>&1 >/dev/null | tr -d '\r')"
  has "ps debug, no file: ERROR=" "$ERR" '^ERROR='
fi

echo "== 6. the contract documents what the scripts accept (doc<->script drift) =="
# Patterns open with a bracket so grep never reads a leading dash as an option.
CONTRACT="$(cat "$HERE/CONTRACTS.md")"
for flag in title theme bg dir debug edit compress base; do
  has "CONTRACTS.md names --$flag" "$CONTRACT" "[-]-$flag"
  has "dg-url.sh handles --$flag" "$(cat "$SCRIPTS/dg-url.sh")" "[-]-$flag\\)"
done
for flag in Title Theme Bg Dir ShowDebug Edit Compress Base; do
  has "CONTRACTS.md names -$flag" "$CONTRACT" "[-]$flag"
  has "dg-url.ps1 declares -$flag" "$(cat "$SCRIPTS/dg-url.ps1")" "[\$]$flag\\b"
done
for flag in json review no-optimise tries host; do
  has "CONTRACTS.md names dg-debug --$flag" "$CONTRACT" "[-]-$flag"
  has "dg-debug.sh handles --$flag" "$(cat "$SCRIPTS/dg-debug.sh")" "[-]-$flag\\)"
done
for flag in Json Review NoOptimise Tries HostUrl; do
  has "CONTRACTS.md names dg-debug -$flag" "$CONTRACT" "[-]$flag"
  has "dg-debug.ps1 declares -$flag" "$(cat "$SCRIPTS/dg-debug.ps1")" "[\$]$flag\\b"
done

echo "== 7. the MCP entry and the skill agree with the contract =="
MCP="$(cat "$PACK/.mcp.json")"
has ".mcp.json registers deltagraph over http" "$MCP" '"type": "http"'
has ".mcp.json points at the documented endpoint" "$MCP" '"url": "https://deltagraph\.submillisecond\.com/mcp"'
has "CONTRACTS.md names the same endpoint" "$CONTRACT" 'https://deltagraph\.submillisecond\.com/mcp'
SKILL="$(cat "$PACK/skills/dg/SKILL.md")"
has "SKILL.md points at the contract, not a copy" "$SKILL" 'contract/CONTRACTS.md'
has "SKILL.md points at the generated spec" "$SKILL" '/deltagraph/spec.md'
for word in deltagraph_debug dg-debug '-Compress' '--compress' '-Bg' '--bg'; do
  has "SKILL.md documents $word" "$SKILL" "[$(printf '%s' "$word" | cut -c1)]$(printf '%s' "$word" | cut -c2-)"
done
VERSION="$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$PACK/.claude-plugin/plugin.json")"
has "SKILL.md version matches plugin.json ($VERSION)" "$SKILL" "^version: $VERSION\$"

contract_result
