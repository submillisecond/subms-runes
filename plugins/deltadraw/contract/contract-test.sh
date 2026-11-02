#!/usr/bin/env bash
# contract-test: offline checks that both dd-url backends agree, links decode, errors exit 2, and that CONTRACTS.md,
# SKILL.md and .mcp.json match the scripts. live-test.sh covers the hosted engine.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/../scripts" && pwd)"
PACK="$(cd "$HERE/.." && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"
contract_isolate

FIX="$T/fix.scene"
# `#` (colours), `&`, `+`, `(` `)`, `"`, space, a trailing newline the trim must
# drop, and a multi-byte character (e-acute) for the UTF-8 byte walk.
printf '\ncanvas 400x200 bg #0b0a22\nrepeat 3 as k: circle k*40+20,rand(0,100) 6 fill #fff\ntext "Caf\303\251 & co" at 10,10\n\n' > "$FIX"
EXPECTED_SRC="$(printf 'canvas 400x200 bg #0b0a22\nrepeat 3 as k: circle k*40+20,rand(0,100) 6 fill #fff\ntext "Caf\303\251 & co" at 10,10')"

pdecode() { printf '%b' "$(printf '%s' "$1" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')"; }
INFLATE=""
if command -v node >/dev/null 2>&1; then
  INFLATE="node"
  inflate() { node -e 'const s=process.argv[1].replace(/-/g,"+").replace(/_/g,"/");process.stdout.write(require("zlib").inflateRawSync(Buffer.from(s,"base64")))' "$1"; }
elif command -v python3 >/dev/null 2>&1; then
  INFLATE="python3"
  inflate() { python3 -c 'import sys,zlib,base64;s=sys.argv[1];s+="="*(-len(s)%4);sys.stdout.buffer.write(zlib.decompress(base64.urlsafe_b64decode(s),-15))' "$1"; }
fi

SH="bash $SCRIPTS/dd-url.sh"
PNG="bash $SCRIPTS/dd-png.sh"
HAVE_PS=0
if ps_backend; then
  HAVE_PS=1
  PSFIX="$FIX"; command -v cygpath >/dev/null 2>&1 && PSFIX="$(cygpath -w "$FIX")"
  PS="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $(cygpath -w "$SCRIPTS/dd-url.ps1" 2>/dev/null || echo "$SCRIPTS/dd-url.ps1")"
  PSPNG="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $(cygpath -w "$SCRIPTS/dd-png.ps1" 2>/dev/null || echo "$SCRIPTS/dd-png.ps1")"
fi

echo "== 1. output shape, both backends =="
OUT_SH="$($SH "$FIX")"
eq "sh: two lines" "$(printf '%s\n' "$OUT_SH" | wc -l | tr -d ' ')" "2"
has "sh: URL line" "$OUT_SH" '^URL=https://deltadraw\.submillisecond\.com/#dsl='
has "sh: LENGTH line" "$OUT_SH" '^LENGTH=[0-9]+$'
URL_SH="$(printf '%s\n' "$OUT_SH" | sed -n 's/^URL=//p')"
eq "sh: LENGTH matches" "$(printf '%s\n' "$OUT_SH" | sed -n 's/^LENGTH=//p')" "${#URL_SH}"
if [ "$HAVE_PS" = 1 ]; then
  eq "ps == sh (byte-identical)" "$($PS "$PSFIX" | tr -d '\r')" "$OUT_SH"
else
  echo "(powershell.exe not present: ps backend skipped)"
fi

echo "== 2. the URL decodes back to the trimmed scene =="
ENC="${URL_SH#*#dsl=}"
has "no raw # in the fragment" "$ENC" '^[^#]*$'
has "no raw & or +" "$ENC" '^[^&+]*$'
has "only unreserved + %XX" "$ENC" '^[A-Za-z0-9._~%-]*$'
eq "round-trip" "$(pdecode "$ENC")" "$EXPECTED_SRC"
eq "stdin works" "$($SH - < "$FIX")" "$OUT_SH"
CRLF="$T/crlf.scene"; printf 'canvas 10x10\r\ncircle 5,5 2 fill #fff\r\n' > "$CRLF"
eq "CRLF reads as LF" "$(pdecode "$($SH "$CRLF" | sed -n 's/^URL=.*#dsl=//p')")" "$(printf 'canvas 10x10\ncircle 5,5 2 fill #fff')"

echo "== 3. compressed form: d1, base64url, inflates to the scene =="
C_SH="$($SH "$FIX" --compress | sed -n 's/^URL=//p')"
has "sh: d1 key" "$C_SH" '^https://deltadraw\.submillisecond\.com/#d1=[A-Za-z0-9_-]+$'
if [ -n "$INFLATE" ]; then
  eq "sh: d1 inflates to the scene" "$(inflate "${C_SH#*#d1=}")" "$EXPECTED_SRC"
else
  echo "(no node or python3: inflate check skipped)"
fi
if [ "$HAVE_PS" = 1 ]; then
  C_PS="$($PS "$PSFIX" -Compress | tr -d '\r' | sed -n 's/^URL=//p')"
  has "ps: d1 key" "$C_PS" '#d1=[A-Za-z0-9_-]+$'
  [ -n "$INFLATE" ] && eq "ps: d1 inflates to the scene" "$(inflate "${C_PS#*#d1=}")" "$EXPECTED_SRC"
fi

echo "== 4. options, in the documented order and spelling =="
OPT="$($SH "$FIX" --title 'Moon & sea' --theme white --replay --edit | sed -n 's/^URL=//p')"
has "options tail" "$OPT" '&title=Moon%20%26%20sea&theme=light&replay&edit$'
has "base override" "$($SH "$FIX" --base http://localhost:3030/deltadraw | sed -n 's/^URL=//p')" '^http://localhost:3030/deltadraw#dsl='
has "options ride the compressed form" "$($SH "$FIX" --compress --title T | sed -n 's/^URL=//p')" '#d1=[A-Za-z0-9_-]+&title=T$'
if [ "$HAVE_PS" = 1 ]; then
  eq "ps options == sh options" "$($PS "$PSFIX" -Title 'Moon & sea' -Theme white -Replay -Edit | tr -d '\r' | sed -n 's/^URL=//p')" "$OPT"
fi

echo "== 5. error paths: exit 2, ERROR= on stderr =="
ERR="$($SH 2>&1 >/dev/null)"; RC=$?
eq "no file: rc" "$RC" "2"; has "no file: ERROR=" "$ERR" '^ERROR='
ERR="$($SH "$FIX" --theme sepia 2>&1 >/dev/null)"; RC=$?
eq "bad theme: rc" "$RC" "2"; has "bad theme: ERROR=" "$ERR" '^ERROR=theme'
ERR="$($SH "$FIX" --nope 2>&1 >/dev/null)"; RC=$?
eq "unknown flag: rc" "$RC" "2"
ERR="$($PNG 2>&1 >/dev/null)"; RC=$?
eq "png, no file: rc" "$RC" "2"; has "png, no file: ERROR=" "$ERR" '^ERROR='
ERR="$($PNG "$FIX" 2>&1 >/dev/null)"; RC=$?
eq "png, no --out: rc" "$RC" "2"; has "png, no --out: ERROR=" "$ERR" '^ERROR=--out'
ERR="$($PNG "$FIX" --out x.png --width big 2>&1 >/dev/null)"; RC=$?
eq "png, bad width: rc" "$RC" "2"
ERR="$($PNG "$FIX" --out x.png --page 0 2>&1 >/dev/null)"; RC=$?
eq "png, page 0: rc" "$RC" "2"; has "png, page 0: ERROR=" "$ERR" '^ERROR=page'
GIF="bash $SCRIPTS/dd-gif.sh"
ERR="$($GIF "$FIX" 2>&1 >/dev/null)"; RC=$?
eq "gif, no --out: rc" "$RC" "2"; has "gif, no --out: ERROR=" "$ERR" '^ERROR=--out'
ERR="$($GIF "$FIX" --out x.gif --mode bounce 2>&1 >/dev/null)"; RC=$?
eq "gif, bad mode: rc" "$RC" "2"; has "gif, bad mode: ERROR=" "$ERR" '^ERROR=mode'
if [ "$HAVE_PS" = 1 ]; then
  ERR="$($PS "$PSFIX" -Theme sepia 2>&1 >/dev/null | tr -d '\r')"
  has "ps bad theme: ERROR=" "$ERR" '^ERROR=theme'
  ERR="$($PSPNG "$PSFIX" 2>&1 >/dev/null | tr -d '\r')"
  has "ps png, no -Out: ERROR=" "$ERR" '^ERROR=-Out'
fi

echo "== 6. the contract documents what the scripts accept =="
CONTRACT="$(cat "$HERE/CONTRACTS.md")"
for flag in title theme replay edit compress base; do
  has "CONTRACTS.md names --$flag" "$CONTRACT" "[-]-$flag"
  has "dd-url.sh handles --$flag" "$(cat "$SCRIPTS/dd-url.sh")" "[-]-$flag\\)"
done
for flag in Title Theme Replay Edit Compress Base; do
  has "CONTRACTS.md names -$flag" "$CONTRACT" "[-]$flag"
  has "dd-url.ps1 declares -$flag" "$(cat "$SCRIPTS/dd-url.ps1")" "[\$]$flag\\b"
done
for flag in out width page host; do
  has "CONTRACTS.md names dd-png --$flag" "$CONTRACT" "[-]-$flag"
  has "dd-png.sh handles --$flag" "$(cat "$SCRIPTS/dd-png.sh")" "[-]-$flag\\)"
done
for flag in Out Width Page HostUrl; do
  has "CONTRACTS.md names dd-png -$flag" "$CONTRACT" "[-]$flag"
  has "dd-png.ps1 declares -$flag" "$(cat "$SCRIPTS/dd-png.ps1")" "[\$]$flag\\b"
done
for flag in out mode width host; do
  has "dd-gif.sh handles --$flag" "$(cat "$SCRIPTS/dd-gif.sh")" "[-]-$flag\\)"
done
for flag in Out Mode Width HostUrl; do
  has "CONTRACTS.md names dd-gif -$flag" "$CONTRACT" "[-]$flag"
  has "dd-gif.ps1 declares -$flag" "$(cat "$SCRIPTS/dd-gif.ps1")" "[\$]$flag\\b"
done

echo "== 7. the MCP entry and the skill agree with the contract =="
MCP="$(cat "$PACK/.mcp.json")"
has ".mcp.json registers deltadraw over http" "$MCP" '"type": "http"'
has ".mcp.json points at the documented endpoint" "$MCP" '"url": "https://deltadraw\.submillisecond\.com/mcp"'
has "CONTRACTS.md names the same endpoint" "$CONTRACT" 'https://deltadraw\.submillisecond\.com/mcp'
SKILL="$(cat "$PACK/skills/deltadraw/SKILL.md")"
has "SKILL.md points at the contract, not a copy" "$SKILL" 'contract/CONTRACTS.md'
has "SKILL.md points at the generated spec" "$SKILL" '/deltadraw/spec.md'
for word in deltadraw_png deltadraw_pack dd-png '-Compress' '--compress'; do
  has "SKILL.md documents $word" "$SKILL" "[$(printf '%s' "$word" | cut -c1)]$(printf '%s' "$word" | cut -c2-)"
done
VERSION="$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' "$PACK/.claude-plugin/plugin.json")"
has "SKILL.md version matches plugin.json ($VERSION)" "$SKILL" "^version: $VERSION\$"
has ".mcp.json X-Runes-Pack matches plugin.json ($VERSION)" "$MCP" "\"X-Runes-Pack\": \"deltadraw/$VERSION\""

contract_result
