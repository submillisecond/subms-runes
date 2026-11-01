#!/usr/bin/env bash
# contract-test: start the bundled MCP server over stdio and check the handshake, tools, refusals, version and bundle.
# Offline; the live room path is subms-ui's pnpm mcp:e2e.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
PACK="$(cd "$HERE/.." && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"
contract_isolate

command -v node >/dev/null 2>&1 || { echo "contract-test: node is required"; exit 2; }
BUNDLE="$PACK/server/deltalab-mcp.mjs"
CONTRACT="$(cat "$HERE/CONTRACTS.md")"
VERSION="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$PACK/.claude-plugin/plugin.json" | head -1)"

# One session: every request on stdin, the replies as `<id>\t<json>` lines.
rpc() {
  printf '%s\n' "$@" | node "$BUNDLE" 2>"$T/stderr" | node -e '
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
eq "serverInfo.version == pack version" "$(js "$INIT" 'm.result.serverInfo.version')" "$VERSION"
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

echo "== 4. the bundle and the pack agree =="
has "bundle says where it is built" "$(head -3 "$BUNDLE")" 'subms-ui/apps/deltalab'
eq "bundle is ASCII" "$(LC_ALL=C grep -c '[^ -~]' "$BUNDLE" | tr -d ' ')" "0"
has ".mcp.json runs the bundle" "$(cat "$PACK/.mcp.json")" 'CLAUDE_PLUGIN_ROOT}/server/deltalab-mcp.mjs'
SKILL="$(cat "$PACK/skills/deltalab/SKILL.md")"
has "SKILL.md points at the contract" "$SKILL" 'contract/CONTRACTS.md'
for t in $NAMES; do has "SKILL.md or contract covers $t" "$SKILL$CONTRACT" "$t"; done
for v in DELTALAB_AGENT_NAME DELTALAB_RUN_BY DELTALAB_RELAY; do
  has "contract documents $v" "$CONTRACT" "$v"
  has "bundle reads $v" "$(grep -o "process.env.$v" "$BUNDLE" | head -1)" "$v"
done

contract_result
