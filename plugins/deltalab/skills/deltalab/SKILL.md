---
name: deltalab
description: This skill should be used when the user hands over a deltalab share link (deltalab.submillisecond.com/#/share/... or beta.deltalab...) or a share code (like KQ47-XMP0, dash optional), or says "join deltalab <code>", "join share <code>", "join a deltalab <anything>", "join this doc", "join the board", "help on this deltalab", "work in the shared document", "be an agent in the room", "/deltalab", or pastes a bare code on its own. Joins the live document or board as a named robot participant through the pack's deltalab MCP server, reads before writing, keeps to its section, suggests instead of writing when the document is in Review, and holds a conversation with the people in the room through the inbox.
version: 0.2.0
---

# deltalab - work in a live shared document or board

deltalab is a collaborative editor: markdown documents and whiteboards that
several people, and agents, edit at once over an end-to-end encrypted room.
This pack's MCP server makes you one of the participants. People see a robot
avatar with your name, your cursor moving to where you work, and who runs you.
The tools and their arguments are in `../../contract/CONTRACTS.md`; the tool
descriptions carry the same.

## Steps

1. **Join.** Call `deltalab_join` at once with whatever the user gave; do not
   ask first. A link goes in `link` exactly as given, fragment and all
   (everything after `#` is the key; never trim it). Anything that looks like a
   code goes in `code`: 8 letters and digits, dash optional, O read as 0 and
   I/L as 1. If the tool rejects it, show the user the expected shape
   (`KQ47-XMP0`) and ask for the code from Share. A code waits in the lobby:
   tell the user right away that they need to admit the agent, then poll
   `deltalab_status`. Keep the room handle it returns (`r1`).
   - A document key (`f_...`, from the address bar or a file list) is not a
     share. The room key travels only in a link's fragment or behind a code,
     so ask for one of those; `/collab` without a token only opens the Join
     dialog and gets you no further.
2. **Read first.** `deltalab_read`. A document comes back with line numbers and
   its heading outline; a board with every element's id and text, the
   discussion, and the diagram as deltagraph DSL. Note your permission:
   - `edit`: write directly.
   - `suggest`: the link is a Review link, or the owner put the whole
     document in Review. Every change goes through `deltalab_suggest`; the owner
     accepts or rejects each one.
   - `view`: read, and say so if asked to change something.
3. **Do the work.** Documents: `deltalab_write` with `under_heading` for the
   section you were asked to own (it stays correct while others type
   elsewhere), `deltalab_suggest` for anyone else's words. Boards:
   `deltalab_board` with `sticky`, `set_text`, `vote`, `comment`, `say`, or
   `set_diagram` / `edit_diagram` for the diagram.
4. **Talk.** What people type to you arrives in `deltalab_inbox`. Answer with
   `deltalab_reply` so the answer sits where they asked. To stay in a
   conversation, loop `deltalab_inbox` with `wait_seconds` (up to 55) and stop
   when the user tells you to or the room goes quiet for a few rounds.
5. **Leave** with `deltalab_leave` when done, so your avatar goes.

## Iterating a diagram live with the room

A common session: the user joins the agent to a board, asks for a diagram,
then reshapes it over many short requests while others watch (rename this,
split that, add a section, line these up, add ideas as notes). What works:

1. **Join, admit, read.** Join on the code at once, tell the user to admit the
   agent from the lobby, read the board (empty is fine).
2. **First version: native DSL, `direction: top_down`, one `subgraph` per
   causal stage,** edge classes on every edge, one pulse. Top-down makes
   sections read as bands.
3. **Keep your own source file as the truth**, with `<br/>` labels and
   `@(x,y)` positions, and send it whole with `set_diagram` on every change.
   The DSL `deltalab_read` returns flattens `<br/>` to spaces, so rebuilding
   from it loses two-line labels.
4. **Each request is one small edit to that file, then check, render and
   send.** Answer in a line or two. Requests arrive mid-work and pile up:
   apply them in order, and say which ones landed.
5. **Once someone cares where things sit, switch to positions.** Read the
   current `@(x,y)` from the board once, then do layout as arithmetic on the
   file: sections side by side (same y), every band spread across one shared
   width, equal gaps between bands, single nodes centred. Shift every node
   below an inserted band down by the band's height plus the gap. Never call
   `relayout` after that.
6. **Names are the user's.** Names they introduce replace generic ones
   everywhere, and when they correct how something is described, sweep your
   own stickies and comments for the old wording too.
7. **Ideas go on stickies beside the diagram, never on it**, in columns to the
   right, and are moved again after the diagram grows.
8. **When the engine cannot do what is asked, say so in a sentence, give
   lettered options, and do the one picked.** Placing one section beside
   another is not a layout option; it is positions.

## Laying out a board

The diagram engine places nodes; you place everything else. What holds:

- Look before you hand it over. Render the diagram (`deltalab_read` gives a
  viewer link; the deltagraph `/png?d1=` route gives a picture) and check it.
  "Applied" is not "looks right": frames stretch, and sections land in
  places nobody asked for.
- The engine stacks every `subgraph` in its own band along the flow. Two
  sections never sit side by side, whatever the declaration order or nesting.
  To put them side by side, write positions: each node takes `@(x,y)` in the
  DSL and `set_diagram` keeps them.
- `relayout` re-solves everything and throws those positions away. Never run
  it on a board someone has arranged.
- A section's frame wraps its members, so a band is as wide as its boxes. For
  bands of equal width, spread each band's nodes from one shared left edge to
  one shared right edge, centre single nodes, and keep the same gap between
  bands. A single-node band stays narrow.
- Edges that cut across the flow (governance, control, metadata) drag their
  section across many rows and leave it mostly empty. Keep cross-cutting
  concerns as an edge-free strip, and group nodes by causal stage.
- A box's width follows its label. To make two boxes the same size, give them
  labels of the same length; `set_diagram` re-sizes diagram nodes from their
  labels, so `resize` holds only for things the diagram does not own.
- Stickies are not part of the diagram. They land in two columns to the right
  of the board's content; `near` puts one beside an element, `x`/`y` place it
  exactly, and `move` rearranges existing ones. Re-check them after the
  diagram grows: a taller diagram does not push them aside.
- When someone renames or re-scopes a thing on the board, re-read your own
  stickies and comments for the old wording too.

## Etiquette that matters

- Re-read before a write when time has passed. You are not the only writer.
- One section or area per agent. Several agents writing the same paragraph
  converge, but the result reads like a collision.
- Short, concrete suggestions with a one-line `why`. The owner reviews them
  one at a time.
- A refused write in Review is not an error to retry. Switch to
  `deltalab_suggest`.
- Keep loops slow. The relay removes a socket that floods it (close 4029), and
  the room then reports the agent closed.

## Gotchas

- The link fragment is the decryption key. Pass it whole; do not paste it into
  any other tool, search, or web request.
- Password-protected links are refused: ask for an unlocked link, or join by
  code and have the owner admit you.
- A `localhost` link from someone's dev server needs `relay`
  (`wss://beta.collab.submillisecond.com`), or `DELTALAB_RELAY` in the
  environment.
- Needs Node 22 or newer on PATH. The server says so and exits otherwise.
- Name: `DELTALAB_AGENT_NAME` sets it (default `Agent <nnn>-<X>`);
  `DELTALAB_RUN_BY` sets the "run by" label (default: the OS user).
