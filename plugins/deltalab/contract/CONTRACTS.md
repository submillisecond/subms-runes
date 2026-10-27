# deltalab plugin - canonical contract

The canonical contract for the deltalab pack. Skill docs under `../skills/`
POINT here; they do not restate it. ASCII only. Guarded by `contract-test.sh`,
which starts the bundled server and checks it against this file.

## 1. What the pack ships, and what it does not own

- `server/deltalab-mcp.mjs`: one bundled file, the deltalab MCP server. Built
  from `subms-ui/apps/deltalab` (`pnpm mcp:build`, then copied here); its first
  lines say so. Never edited in this repo.
- `.mcp.json`: starts it with `node ${CLAUDE_PLUGIN_ROOT}/server/deltalab-mcp.mjs`.

The room protocol, the signing, the share link format and the relay are
`subms-ui`'s. This pack fixes only the MCP surface below. The server runs
locally because the share link's fragment is the room key: a hosted server
would hold the key and see the plaintext.

Runtime: Node 22 or newer (built-in WebSocket and WebCrypto). Older Node: the
server writes the reason to stderr and exits 1.

## 2. Transport

MCP over stdio, newline-delimited JSON-RPC 2.0. Protocol version `2025-06-18`.
`serverInfo.name` is `deltalab` and `serverInfo.version` equals this pack's
version. `initialize` returns `instructions`. Methods: `initialize`, `ping`,
`tools/list`, `tools/call`; anything else with an id is `-32601`. stdout carries
only protocol; logs go to stderr, prefixed `deltalab: `.

## 3. Tools

Every result is `{ content: [{ type: "text", text }] }`; a refusal adds
`isError: true` and says what to do instead. `room` is optional everywhere:
omitted, it is the room joined most recently.

| Tool | Arguments (required in bold) | Does |
|---|---|---|
| `deltalab_join` | `link` or `code`, `relay` | Join; returns handle `rN`, title, permission, who is here. A code waits in the lobby until the owner admits. |
| `deltalab_status` | - | Every room: state, permission, who is here, unread inbox. |
| `deltalab_read` | `room`, `from_line`, `to_line`, `numbered` | Document: outline plus numbered lines. Board: elements, discussion, diagram DSL, viewer link. |
| `deltalab_write` | `room`, **`text`**, `under_heading`, `after_line` | Direct write into a document. Refused unless permission is `edit`. |
| `deltalab_suggest` | `room`, **`find`**, **`replace`**, `why` | Propose a replacement for the owner to accept. Refused for view-only. |
| `deltalab_board` | `room`, **`action`**, `ref`, `text`, `near`, `dsl`, `ops` | Board change; `action` is one of `sticky`, `set_text`, `vote`, `unvote`, `comment`, `say`, `set_diagram`, `edit_diagram`, `relayout`. Refused unless `edit`. |
| `deltalab_inbox` | `room`, `wait_seconds` (0-55) | Messages people wrote since the last call, each `[rN mK] author: text`. |
| `deltalab_reply` | `room`, **`id`**, **`text`** | Answer an inbox message where it was written. |
| `deltalab_leave` | `room` | Leave; presence clears at once. |

Room states in `deltalab_status`: `joining`, `waiting`, `live`, `closed`,
`failed`. A closed room names why: removed by the owner (4001), identity refused
(4003), share ended (4004), duplicate or replaced session (4006, 4007), not
admitted (4008), rate limited (4029).

Permissions: `edit` (write directly), `suggest` (a Review link, or the owner
set the whole document to Review), `view`.

## 4. Environment

| Variable | Effect | Default |
|---|---|---|
| `DELTALAB_AGENT_NAME` | The name people see | `Agent <nnn>-<X>`, random per process |
| `DELTALAB_RUN_BY` | The "run by" label on the avatar | the OS user |
| `DELTALAB_RELAY` | Relay for links that do not name one (localhost) | inferred from the link; codes use production |
