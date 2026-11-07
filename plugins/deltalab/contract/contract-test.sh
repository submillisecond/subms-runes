#!/usr/bin/env bash
# contract-test: start the MCP server through the loader over stdio and check the handshake, tools, refusals, version, and the loader's signature checks.
# Offline; the live room path is subms-ui's pnpm mcp:e2e.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PACK="$(cd "$HERE/.." && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"
contract_isolate

command -v node >/dev/null 2>&1 || { echo "contract-test: node is required"; exit 2; }
LOADER="$PACK/server/deltalab-mcp.mjs"
# The signed client: DELTALAB_CLIENT_BASE if set, else a local deltalab build
# beside this repo (subms-ui static build), else the production host.
SIGNED="$PACK/../../../subms-ui/apps/deltalab/out/runes/deltalab"
if [ -z "${DELTALAB_CLIENT_BASE:-}" ] && [ -f "$SIGNED/manifest.json" ]; then
  export DELTALAB_CLIENT_BASE="file://$(cd "$SIGNED" && pwd -W 2>/dev/null || pwd)/"
fi
unset DELTALAB_CLIENT_CACHE
CONTRACT="$(cat "$HERE/CONTRACTS.md")"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$PACK/.claude-plugin/plugin.json" | head -1)"

# One session: every request on stdin, the replies as `<id>\t<json>` lines.
rpc() {
  printf '%s\n' "$@" | node "$LOADER" 2>"$T/stderr" | node -e '
    let d = ""; process.stdin.on("data", (c) => (d += c)).on("end", () => {
      for (const l of d.split("\n").filter(Boolean)) { const m = JSON.parse(l); console.log(m.id + "\t" + JSON.stringify(m)); }
    });'
}
reply() { printf '%s\n' "$OUT" | awk -F'\t' -v id="$1" '$1 == id { print $2 }'; }
js() { printf '%s' "$1" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{const m=JSON.parse(d);console.log($2)})"; }

OUT="$(rpc \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"contract","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"deltalab_status","arguments":{}}}' \
  '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"deltalab_join","arguments":{"link":"https://example.com/not-a-share"}}}' \
  '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"deltalab_read","arguments":{}}}' \
  '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"deltalab_join","arguments":{"code":"short"}}}' \
  '{"jsonrpc":"2.0","id":7,"method":"resources/list"}' \
  '{"jsonrpc":"2.0","id":8,"method":"ping"}' \
)"

echo "== 1. handshake =="
INIT="$(reply 1)"
eq "serverInfo.name" "$(js "$INIT" 'm.result.serverInfo.name')" "deltalab"
# Loaders run only a client on their API line; the pack version is unrelated.
LOADER_API="$(sed -n 's/^const API = "\([^"]*\)";/\1/p' "$LOADER")"
eq "serverInfo.version is on the loader's API line ($LOADER_API.x)" "$(js "$INIT" 'm.result.serverInfo.version.split(".").slice(0,2).join(".")')" "$LOADER_API"
eq "protocolVersion" "$(js "$INIT" 'm.result.protocolVersion')" "2025-06-18"
has "instructions carry the Review rule" "$(js "$INIT" 'm.result.instructions')" 'deltalab_suggest'
has "instructions ask agents to coordinate in the room" "$(js "$INIT" 'm.result.instructions')" 'Agree who takes which part'
has "instructions name the kinds the tools do not work in" "$(js "$INIT" 'm.result.instructions')" 'not supported by these tools'
has "instructions explain who a chat message is for" "$(js "$INIT" 'm.result.instructions')" '@agent-valkyrie-all'
has "instructions name the chat tool" "$(js "$INIT" 'm.result.instructions')" 'deltalab_say'
has "instructions say agents reach each other by handle" "$(js "$INIT" 'm.result.instructions')" 'only when it tags you by name'
has "instructions ask for plain, short room messages" "$(js "$INIT" 'm.result.instructions')" 'one point per message'
has "instructions keep work in the room, not on disk" "$(js "$INIT" 'm.result.instructions')" 'never a file on disk'
eq "a notification gets no reply" "$(reply undefined)" ""
eq "unknown method is -32601" "$(js "$(reply 7)" 'm.error.code')" "-32601"
eq "ping" "$(js "$(reply 8)" 'JSON.stringify(m.result)')" "{}"
eq "stdout is protocol only: one reply per request with an id" "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" "8"

echo "== 2. tools match the contract =="
LIST="$(reply 2)"
NAMES="$(js "$LIST" 'm.result.tools.map(t=>t.name).sort().join(" ")')"
DOC_NAMES="$(printf '%s\n' "$CONTRACT" | grep -oE '^\| `deltalab_[a-z]+`' | tr -d '|` ' | sort | tr '\n' ' ' | sed 's/ $//')"
eq "tool names == CONTRACTS.md table" "$NAMES" "$DOC_NAMES"
for t in $NAMES; do
  REQ="$(js "$LIST" "(m.result.tools.find(x=>x.name==='$t').inputSchema.required||[]).slice().sort().join(' ')")"
  ROW="$(printf '%s\n' "$CONTRACT" | grep -E "^\| \`$t\`")"
  DOC_REQ="$(printf '%s' "$ROW" | cut -d'|' -f3 | grep -oE '\*\*`[a-z_]+`\*\*' | tr -d '*`' | sort | tr '\n' ' ' | sed 's/ $//')"
  eq "$t required args == contract" "$REQ" "$DOC_REQ"
  eq "$t schema is an object" "$(js "$LIST" "m.result.tools.find(x=>x.name==='$t').inputSchema.type")" "object"
done
ACTIONS="$(js "$LIST" "m.result.tools.find(x=>x.name==='deltalab_board').inputSchema.properties.action.enum.join(' ')")"
for a in $ACTIONS; do has "CONTRACTS.md names board action $a" "$CONTRACT" "\`$a\`"; done

echo "== 3. refusals are tool errors that say what to do =="
eq "status with no rooms is not an error" "$(js "$(reply 3)" 'String(!!m.result.isError)')" "false"
has "status says how to start" "$(js "$(reply 3)" 'm.result.content[0].text')" 'deltalab_join'
eq "bad link: isError" "$(js "$(reply 4)" 'String(m.result.isError)')" "true"
has "bad link: says why" "$(js "$(reply 4)" 'm.result.content[0].text')" 'does not open a share'
has "read before join: says to join" "$(js "$(reply 5)" 'm.result.content[0].text')" 'deltalab_join'
has "bad code: shows the shape" "$(js "$(reply 6)" 'm.result.content[0].text')" 'KQ47-XMP0'

echo "== 4. the loader and the pack agree =="
has "loader says what it is" "$(head -3 "$LOADER")" 'deltalab MCP loader'
eq "loader is ASCII" "$(LC_ALL=C grep -c '[^ -~]' "$LOADER" | tr -d ' ')" "0"
has "loader reported the verified client" "$(cat "$T/stderr")" 'signature verified'
eq "loader PACK_VERSION == plugin.json version" "$(sed -n 's/^const PACK_VERSION = "\([^"]*\)";/\1/p' "$LOADER")" "$VERSION"
has ".mcp.json runs the loader" "$(cat "$PACK/.mcp.json")" 'CLAUDE_PLUGIN_ROOT}/server/deltalab-mcp.mjs'
SKILL="$(cat "$PACK/skills/deltalab/SKILL.md")"
has "SKILL.md points at the contract" "$SKILL" 'contract/CONTRACTS.md'
for t in $NAMES; do has "SKILL.md or contract covers $t" "$SKILL$CONTRACT" "$t"; done
for v in DELTALAB_AGENT_NAME DELTALAB_RUN_BY DELTALAB_RELAY DELTALAB_CLIENT_BASE DELTALAB_CLIENT_CACHE; do
  has "contract documents $v" "$CONTRACT" "$v"
done
for v in DELTALAB_CLIENT_BASE DELTALAB_CLIENT_CACHE; do
  has "loader reads $v" "$(grep -o "process.env.$v" "$LOADER" | head -1)" "$v"
done

echo "== 5. the loader runs nothing it cannot verify =="
case "${DELTALAB_CLIENT_BASE:-}" in
  file://*)
    SRC="${DELTALAB_CLIENT_BASE#file://}"
    cp -r "$SRC" "$T/tamper" && for f in "$T"/tamper/client-*.mjs; do printf '\n//x' >> "$f"; done
    has "a changed client is refused" "$(DELTALAB_CLIENT_BASE="file://$(cd "$T/tamper" && pwd -W 2>/dev/null || pwd)/" node "$LOADER" </dev/null 2>&1)" 'do not match the signed manifest'
    cp -r "$SRC" "$T/forge" && sed -i 's/"version": "\([0-9.]*\)"/"version": "\1-x"/' "$T/forge/manifest.json"
    has "a changed manifest is refused" "$(DELTALAB_CLIENT_BASE="file://$(cd "$T/forge" && pwd -W 2>/dev/null || pwd)/" node "$LOADER" </dev/null 2>&1)" "does not match deltalab's key"
    ;;
  *) echo "  (skipped: tamper checks need a local signed build; run subms-ui's static build first)" ;;
esac
has "a remote http base is refused" "$(DELTALAB_CLIENT_BASE=http://example.com/ node "$LOADER" </dev/null 2>&1)" 'must be https://'
# A refusing loader still answers MCP so the agent can say why.
REFUSED="$(printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"deltalab_status","arguments":{}}}' | DELTALAB_CLIENT_BASE=http://example.com/ node "$LOADER" 2>/dev/null)"
has "a refusal answers initialize with the reason" "$(printf '%s\n' "$REFUSED" | head -1)" 'not available in this session'
has "a refusal's tool call is an error with the fix" "$(printf '%s\n' "$REFUSED" | sed -n 2p)" '"isError":true'

contract_result
