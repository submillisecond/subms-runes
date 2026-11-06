# deltalab rune - reference

What the `deltalab` rune does now. Tool names, arguments, room states and the
environment are in `../../contract/CONTRACTS.md`; this file does not repeat them.

## Uses

- Every tool in the contract. The rune's steps are join, read, agree the plan
  in the room, write or suggest, inbox and reply (or say in the chat), leave.
- The server's `initialize` instructions carry the same working-together and
  per-kind guidance as the skill, and `/llms.txt` on deltalab prints them; the
  skill restates them in its own words for the steps, not as a schema. That
  includes how to write in the room (plain English, one point per message, no
  praise or sign-offs, work shared only through the room and never as a file
  on disk, even between agents on one machine), which came from reading the
  messages of a two-agent session: 900-1200 character messages, compliments,
  self-introductions and closing rituals. The contract test checks the
  instructions carry it.
- No scripts of its own: the MCP server is the whole runtime.

## Behaviour the rune relies on

- Boards, text documents (markdown, code, other text) and drawings are the
  kinds the tools work in. On a board that includes spreadsheets (formulas
  and their values), coding workspaces (files, not running them), drawings on
  the board and mermaid diagrams. Notebooks and record files are not; the
  share panel offers no agent invite on them.
- A direct write is refused unless the agent's permission is `edit`. The rune
  treats that refusal as the signal to suggest, never as an error to retry.
- `deltalab_inbox` with `wait_seconds` returns on the first new message, so a
  conversation is a loop of inbox and reply with no polling sleep.
- Every agent receives every chat message, thread reply and comment from a
  person, tagged with who it was for (`to you`, `to every agent`, `to
  everyone`, someone else, `open`). The rune decides whether to answer from
  that tag. Another agent's message is delivered only when it tags this agent
  by name, so two agents converse by handle and open or group-tagged agent
  talk cannot set agents answering agents; an agent never receives its own. Its own name is its @handle, and a message that tags it
  shows it as working on a reply to the room until it answers (or 90 s pass).
- Document chat reaches the agent as well as board discussion. A reply to a
  chat message is a new message in the room; a reply to a comment on a passage
  goes in that comment's thread.
- A room the relay closed stays listed with its reason, so the rune can tell
  the user why the agent is out (removed, share ended, rate limited).
- `deltalab_join` accepts a code in either field, names a document key as
  not a share, and sends codes to the production relay. The rune therefore
  joins on whatever the user pasted and only asks when the tool refuses.
- The pack carries no client: `server/deltalab-mcp.mjs` is a loader that
  fetches the signed client from deltalab at each start, checks its Ed25519
  signature, size and hash, and runs it from memory (CONTRACTS.md section 1).
  No proprietary code ships in this public pack.
- The server carries no diagram engine (the build fails if one is bundled):
  `set_diagram`, `edit_diagram`, `relayout` and reading the diagram back go
  to the deltagraph worker's `POST /board`, which returns the delta the server
  writes into the room.
- `set_diagram` keeps `@(x,y)` node positions and `relayout` drops them; the
  engine stacks subgraphs in bands. Side-by-side sections and equal-width
  bands are positions the rune writes, not layout options.
- `move` and `resize` act on any element; `set_diagram` re-sizes diagram nodes
  from their labels, so `resize` sticks only for stickies, frames and other
  non-diagram elements. A sticky with no placement lands right of the content.

## Verification

- `../../contract/contract-test.sh`: the server, started through the loader,
  against the contract, plus the loader refusing a changed client and a
  changed manifest. Offline when a local signed build exists beside the repo.
- `subms-ui/apps/deltalab`: `pnpm test` (the tool layer against an in-memory
  room) and `pnpm mcp:e2e` (the built bundle in a fresh room on the beta
  relay: join, read, section write, presence, inbox, reply, suggest, leave).
