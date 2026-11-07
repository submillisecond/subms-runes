# deltalab plugin - canonical contract

The canonical contract for the deltalab pack. Skill docs under `../skills/`
POINT here; they do not restate it. ASCII only. Guarded by `contract-test.sh`,
which starts the server through the loader and checks it against this file.

## 1. What the pack ships, and what it does not own

- `server/deltalab-mcp.mjs`: the loader, a few dozen lines with no
  dependencies. The deltalab client (room protocol, agent, MCP server) is not in
  this pack. At each start the loader fetches `manifest.json`, `manifest.sig` and
  the client file the manifest names from `DELTALAB_CLIENT_BASE`, and runs the
  client from memory only when all of these hold:
  - `manifest.sig` is an Ed25519 signature over the exact bytes of
    `manifest.json` by the key whose public half is built into the loader;
  - the client's size and SHA-256 equal the manifest's `size` and `sha256`;
  - the manifest's `name` is `deltalab-client`, its `version` is `0.4.x`, and
    its `builtAt` is no earlier than the loader's minimum, so an older signed
    client cannot be replayed.
  Otherwise it writes `deltalab: not starting: <reason>` to stderr and exits 1
  without running any of it. On start it writes `deltalab: client <build>
  (deltalab <deploy>), built <builtAt>, signature verified`; the deploy part
  appears when the manifest carries one.
- When the manifest's `pack` (the newest released pack, stamped at signing)
  is newer than the loader's own version, the loader writes `deltalab: this
  pack is <x> and <y> is out. Update it, then restart Claude Code: claude
  plugin marketplace update subms-runes && claude plugin update
  deltalab@subms-runes` to stderr, and the server puts the same notice, with
  those commands, at the top of its `initialize` instructions and under
  `deltalab_status` and `deltalab_join`, so the model tells the user. The
  client itself never needs this: it is fetched fresh at every start.
- The client and its signed manifest are published by deltalab's deploy
  (`subms-ui/apps/deltalab/scripts/sign-client.mjs`, at
  `https://deltalab.submillisecond.com/runes/deltalab/`). Every prod deploy
  signs it and stamps `version` (the client's MCP API version), `build` (that version plus the signing time), `builtAt`, and `deploy` and `commit` (the deltalab deploy version and commit, as in its `build-info.json`) into the manifest; a prod
  deploy without the signing key fails. The private key never leaves the
  deploying machine.
- `.mcp.json`: starts the loader with `node ${CLAUDE_PLUGIN_ROOT}/server/deltalab-mcp.mjs`.

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
| `deltalab_join` | `link` or `code`, `relay` | Join; returns handle `rN`, title, permission, who is here. A code waits in the lobby until the owner admits. A code passed as `link` joins as a code; a document key (`f_...`) is refused by name. Codes go to the production relay. |
| `deltalab_status` | - | Every room: state, permission, who is here, unread inbox. |
| `deltalab_read` | `room`, `from_line`, `to_line`, `numbered`, `within`, `picture` | Board only: `within` (a frame's id or name, or `x,y,w,h`) reads just what overlaps that area; `picture: true` also returns a PNG of the board (or the area) as viewers see it, drawn by the deltagraph worker (`POST /board/png`). Document: outline plus numbered lines. Board: elements, the discussion from when the agent joined (as a person sees it; the owner sees all of it), diagram DSL, viewer link. Under an element, what its text does not say: a spreadsheet's sheet name and the computed value of each formula cell, a coding workspace's files, active file and last run output, a drawing's stroke count, a sequence or state role, and a file link (`linked to the file <name>`, read-only to the agent). |
| `deltalab_write` | `room`, **`text`**, `under_heading`, `after_line` | Direct write into a document. Refused unless permission is `edit`. |
| `deltalab_suggest` | `room`, **`find`**, **`replace`**, `why` | Propose a replacement for the owner to accept. Refused for view-only. |
| `deltalab_board` | `room`, **`action`**, `ref`, `text`, `near`, `x`, `y`, `w`, `h`, `dsl`, `ops`, `url`, `link`, `to`, `shape`, `highlight`, `note`, `image`, `accent`, `fill`, `stroke`, `size`, `code_lang`, `name`, `path`, `cell`, `table`, `kind`, `range`, `title`, `stacked`, `diagram` | Board change; `action` is one of `sticky`, `set_text`, `vote`, `unvote`, `comment`, `say`, `set_diagram`, `edit_diagram`, `relayout`, `move_diagram` (`diagram`, `x`, `y`: move a whole diagram so its top-left lands there; `diagram` names which diagram on the board, else the main one, and also applies to `set_diagram`, `edit_diagram` and `relayout`), `move`, `resize`, `image` (a web picture at `x`, `y`, `w`, uploaded encrypted to the room), `card` (title, `highlight`, `note`, `image`, `link`, `accent`; height from the text), `frame` (a titled section; add it before its contents), `shape` (`rectangle`, `ellipse`, `diamond`, `text`, `markdown`, `code`, `table`, `rich_table`, `workspace`; a `rich_table` is a styled table for showing data, no formulas: `text` is a markdown table (a `**bold**` or `[linked](url)` cell keeps its style) or tab-separated rows, and `set_text` rewrites it keeping each surviving cell's style; a `table` is a spreadsheet: cells split by `|` or tabs, `=` starts a formula, `name` names the sheet that `Name!A1` reads, the box is sized to the grid; a `workspace` is a coding workspace with runnable starter files in `code_lang` `python`, `java`, `javascript`, `typescript` or `react`), `write_file` (`ref` a workspace, `path`, `text` the whole file; added and opened when new, replaced when it exists), `run` (`ref` a workspace, `path` optional: runs it in the browser of a person in the room who can edit, in the same sandbox as their Run button, and returns the output; refused when nobody who can edit has the board open, and for React apps), `cell` (`ref` a `rich_table`, `cell` an address like `B3`, growing the table to reach it; `text` the cell's markdown, where a markdown table becomes the table inside the cell; `table` a markdown table to put inside the cell, empty removes it; `image` a picture URL added to the cell), `chart` (`ref` a `rich_table` or spreadsheet and `range` like `B1:D8`, or `text` rows of data; `kind` `bar`, `line`, `area`, `pie` or `scatter`; `title`; `stacked`; placed right of its table; a linked chart follows its table; the first column gives the categories, a scatter's x, and the header row names the series), `embed` (a live web page), `connect` (`ref` to `to`, an edge-to-edge arrow that does not follow later moves), `link` (open `url` from `ref`), `delete` (one or more refs), and `check` (lists overlaps, overhangs and overflowing text; run it after every batch). `set_diagram` also takes mermaid (`stateDiagram-v2`, `sequenceDiagram`, `erDiagram`, `classDiagram` and the other kinds deltagraph reads): the diagram is drawn with the board's own components (state start and end dots, lifelines, ER cards, class boxes) right of the existing content, replaces the previous mermaid diagram, and leaves everything else alone. In a state diagram read back as DSL, `__start__` and `__end__` are the `[*]` dots. `set_text` refuses a coding workspace (use `write_file`), a drawing (use `deltalab_draw`) and an element linked to someone's workspace file, naming what to do instead; on a spreadsheet it takes formulas and never shrinks the sheet. A sticky lands right of the board's content unless `near` or `x`/`y` place it. `move` takes `ref`, `x`, `y`; `resize` takes `ref`, `w`, `h`. Refused unless `edit`. The diagram actions are done by the deltagraph worker (`POST /board`): the server carries no layout engine, so they need the network; a board read still answers without it, with the diagram marked unreadable. |
| `deltalab_inbox` | `room`, `wait_seconds` (0-55) | Messages people wrote since the last call: paragraphs typed into a document, chat messages and thread replies, comments. Each is `[rN mK] author[ where][, to whom]:` then the text. `where` is ` in the chat` or ` on "..."`; `to whom` is `to you`, `to every agent` (@agent-valkyrie-all or @agents), `to everyone` (@all), `to @Handle, ...` (someone else) or `open, no tag`. Every agent gets every message from a person; the tag says whether it is asked. A message from another agent arrives only when it tags this agent by name (`to you`), and an agent never sees its own. Reading marks the messages seen: people see "Seen by <agent>" under them. A message asked of the agent (`to you`, `to every agent`, `to everyone`) that this tool has not returned within 2 minutes shows the agent as away in the room, until it is read or answered. |
| `deltalab_reply` | `room`, **`id`**, **`text`** | Answer an inbox message where it was written: below the paragraph, as a new chat message, or in the comment's thread. Clears the agent's "working on a reply" mark. |
| `deltalab_say` | `room`, **`text`** | Post a message in the room's chat (a document's discussion or a board's). Tag with `@` and a handle. Refused unless `edit`. |
| `deltalab_draw` | `room`, **`scene`**, `ref`, `x`, `y`, `w` | Paint a deltadraw scene (scene text, or a `#d1=` / `#dsl=` / `#p1=` link) into a shared paint file; layers match by name. On a board it makes a drawing on the board (an image carrying the painting's source, editable in deltalab like one drawn there) at `x`, `y`, `w` wide, or with `ref` paints into an existing one; the picture is rendered by the deltadraw worker (`POST /svg`). The scene is compiled by the deltadraw worker (`POST /doc`), so the server carries no drawing engine and this needs the network. Check the scene with the deltadraw tools first. Refused unless `edit`. |
| `deltalab_leave` | `room` | Leave; presence clears at once. |

Room states in `deltalab_status`: `joining`, `waiting`, `live`, `closed`,
`failed`. A closed room names why: removed by the owner (4001), identity refused
(4003), share ended (4004), duplicate or replaced session (4006, 4007), not
admitted (4008), share full at 200 people (4010), rate limited (4029).

Permissions: `edit` (write directly), `suggest` (a Review link, or the owner
set the whole document to Review), `view`.

## 4. Environment

| Variable | Effect | Default |
|---|---|---|
| `DELTALAB_AGENT_NAME` | The name people see and @mention; spaces become hyphens | `agent-valkyrie-<rune>`, a random Elder Futhark rune per process; agents are named for 40 runes, the Elder then the Younger Futhark (fehu, uruz, ... reidh), then round again as `-2`, `-3`. The old `@Agent-Smith-All` tag still reaches every agent |
| `DELTALAB_RUN_BY` | The "run by" label on the avatar | the OS user |
| `DELTALAB_RELAY` | Relay for links that do not name one (localhost) | inferred from the link; codes use production |
| `DELTALAB_CLIENT_BASE` | Where the loader fetches the signed client from: `https://`, `file://`, or a localhost `http://` address; anything else is refused | `https://deltalab.submillisecond.com/runes/deltalab/` |
| `DELTALAB_CLIENT_CACHE` | A folder that keeps the last verified client, used when the fetch fails (offline); `1` picks the OS cache folder (`%LOCALAPPDATA%\subms\deltalab-client`, `~/Library/Caches/subms/deltalab-client`, `$XDG_CACHE_HOME/subms/deltalab-client`). A cached client is checked the same way each time, and a newer one is never replaced by an older | unset: nothing is written to disk |
| `DELTALAB_DG_HOST` | The deltagraph worker that does the board's diagram work (`set_diagram`, `edit_diagram`, `relayout`, and the diagram part of `deltalab_read`) | `https://deltagraph.submillisecond.com` |
