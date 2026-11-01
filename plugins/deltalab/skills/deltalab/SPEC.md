# deltalab rune - reference

What the `deltalab` rune does now. Tool names, arguments, room states and the
environment are in `../../contract/CONTRACTS.md`; this file does not repeat them.

## Uses

- Every tool in the contract. The rune's steps are join, read, agree the plan
  in the room, write or suggest, inbox and reply (or say in the chat), leave.
- The server's `initialize` instructions carry the same working-together and
  per-kind guidance as the skill, and `/llms.txt` on deltalab prints them; the
  skill restates them in its own words for the steps, not as a schema.
- No scripts of its own: the MCP server is the whole runtime.

## Behaviour the rune relies on

- Boards and text documents (markdown, code, other text) are the kinds the
  tools work in. Drawings, notebooks and record files are not; the share panel
  offers no agent invite on them.
- A direct write is refused unless the agent's permission is `edit`. The rune
  treats that refusal as the signal to suggest, never as an error to retry.
- `deltalab_inbox` with `wait_seconds` returns on the first new message, so a
  conversation is a loop of inbox and reply with no polling sleep.
- Every agent receives every chat message, thread reply and comment, tagged
  with who it was for (`to you`, `to every agent`, `to everyone`, someone
  else, `open`). The rune decides whether to answer from that tag; nothing is
  filtered before it. Its own name is its @handle, and a message that tags it
  shows it as working on a reply to the room until it answers (or 90 s pass).
- Document chat reaches the agent as well as board discussion. A reply to a
  chat message is a new message in the room; a reply to a comment on a passage
  goes in that comment's thread.
- A room the relay closed stays listed with its reason, so the rune can tell
  the user why the agent is out (removed, share ended, rate limited).
- `deltalab_join` accepts a code in either field, names a document key as
  not a share, and sends codes to the production relay. The rune therefore
  joins on whatever the user pasted and only asks when the tool refuses.
- `set_diagram` keeps `@(x,y)` node positions and `relayout` drops them; the
  engine stacks subgraphs in bands. Side-by-side sections and equal-width
  bands are positions the rune writes, not layout options.
- `move` and `resize` act on any element; `set_diagram` re-sizes diagram nodes
  from their labels, so `resize` sticks only for stickies, frames and other
  non-diagram elements. A sticky with no placement lands right of the content.

## Verification

- `../../contract/contract-test.sh`: the server against the contract, offline.
- `subms-ui/apps/deltalab`: `pnpm test` (the tool layer against an in-memory
  room) and `pnpm mcp:e2e` (the built bundle in a fresh room on the beta
  relay: join, read, section write, presence, inbox, reply, suggest, leave).
