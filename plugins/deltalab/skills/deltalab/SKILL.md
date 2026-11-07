---
name: deltalab
description: This skill should be used when the user hands over a deltalab share link (deltalab.submillisecond.com/join/#/room/..., /collab/#/room/..., /#/share/... or beta.deltalab...) or a share code (like KQ47-XMP0, dash optional), or says "join deltalab <code>", "join share <code>", "join a deltalab <anything>", "join this doc", "join the board", "help on this deltalab", "work in the shared document", "be an agent in the room", "/deltalab", or pastes a bare code on its own. Joins the live document or board as a named robot participant through the pack's deltalab MCP server, reads before writing, keeps to its section, suggests instead of writing when the document is in Review, and holds a conversation with the people in the room through the inbox. Not for drawing a diagram or a picture on its own, even one about deltalab: that needs no room, link or share; use the deltagraph pack (a deltagraph.submillisecond.com URL, hosted MCP at https://deltagraph.submillisecond.com/mcp) or deltadraw for pictures.
version: 0.5.0
---

# deltalab - work in a live shared document or board

deltalab is a collaborative editor: markdown documents and whiteboards that
several people, and agents, edit at once over an end-to-end encrypted room.
This pack's MCP server makes you one of the participants. People see a robot
avatar with your name, your cursor moving to where you work, and who runs you.
The tools and their arguments are in `../../contract/CONTRACTS.md`; the tool
descriptions carry the same.

## Only a diagram or a picture? No room needed

A room is for working beside people. To draw an architecture, a flow, a
layout sketch or any diagram on its own, do not ask anyone to create a board
or share a link: make it directly and hand over a URL.

- **Diagrams: the deltagraph pack** (skill `deltagraph`). Its hosted MCP
  server (`https://deltagraph.submillisecond.com/mcp`, no sign-in) checks and
  renders through the real engine; its `dg-url` script turns a source file
  into a link offline. The link is
  `https://deltagraph.submillisecond.com/#dsl=<percent-encoded source>`, and
  the grammar is at `https://www.submillisecond.com/deltagraph/spec.md`. A
  picture to look at first: `https://deltagraph.submillisecond.com/png?dsl=<same>`.
- **Pictures, illustrations, sketches: the deltadraw pack** (skill
  `deltadraw`, MCP `https://deltadraw.submillisecond.com/mcp`, `dd-url`).
- **If neither pack is installed**, build the deltagraph link by hand from the
  spec, and say once that installing the deltagraph pack
  (`claude plugin install deltagraph@subms-runes`) checks it before it is sent.
- **Box drawings in ASCII are not a substitute.** Draw the real diagram.

Join a room only when the user gives a share link or code, or asks to work in
one. A diagram made this way can be dropped on a board later.

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
     so ask for one of those; `/join` (or the older `/collab`) without a
     token only opens the Join dialog and gets you no further.
2. **Read first.** `deltalab_read`. A document comes back with line numbers and
   its heading outline; a board with every element's id and text, the
   discussion, and the diagram as deltagraph DSL. Note your permission:
   - `edit`: write directly.
   - `suggest`: the link is a Review link, or the owner put the whole
     document in Review. Every change goes through `deltalab_suggest`; the owner
     accepts or rejects each one.
   - `view`: read, and say so if asked to change something.
3. **Agree the plan in the room.** Before a large change, say what you intend
   where people will see it (the board discussion with `deltalab_board` `say`,
   or a reply in the document) and ask for objections. Give your view with a
   reason when you disagree, with the user or with another agent, and propose
   what you would do instead. If other agents are in the room, settle who
   takes which part before anyone starts. Then work in small steps and say
   what changed after each, so people can steer between them.
4. **Do the work.** Documents: `deltalab_write` with `under_heading` for the
   section you were asked to own (it stays correct while others type
   elsewhere), `deltalab_suggest` for anyone else's words. Boards:
   `deltalab_board` with `sticky`, `set_text`, `vote`, `comment`, `say`, or
   `set_diagram` / `edit_diagram` for the diagram (`set_diagram` also takes
   mermaid state, sequence, ER and class diagrams, drawn with the board's own
   components). Spreadsheets, coding workspaces and drawings on a board have
   their own moves; see below.
5. **Talk.** The chat is one room for people and agents. Every message
   from a person arrives in `deltalab_inbox`; another agent's arrives only
   when it tags you by name. Each is marked with who it was for: `to you` (your
   name, which is your @handle), `to every agent` (@agent-valkyrie-all or
   @agents), `to everyone` (@all), someone else, or `open`. Answer what is to
   you, every agent or everyone with `deltalab_reply`; leave someone else's
   message to them; take open talk when you are the only agent or it is about
   your part. Start a thread or hand work over with `deltalab_say`, tagging the
   handle (`@agent-valkyrie-fehu, can you take the intro?`). To stay in a
   conversation, loop `deltalab_inbox` with `wait_seconds` (up to 55) and stop
   when the user tells you to or the room goes quiet for a few rounds.
6. **Leave** with `deltalab_leave` when done, so your avatar goes.

## By kind of file

- **Boards.** Discuss in the board discussion and comment on the element you
  mean; votes show which options have support. Change the diagram with
  `edit_diagram` one step at a time and read the board again before each
  step, since others edit it too.
- **Markdown and other text documents.** Reply where you were asked, write
  under your own heading, and suggest edits to anyone else's text.
- **Code files.** They are text documents to these tools: write at the lines
  you were given (`after_line`), keep a change to what you were asked about,
  and say what it does. Suggest rather than rewrite someone else's code.
- **Spreadsheets on a board.** A `table` shape is a spreadsheet. A cell that
  starts with `=` is a formula (`=SUM(B2:B5)`, `=B2*C2`, `$A$1`, `IF`,
  `ROUND`, `VLOOKUP`), each sheet has a name, and another sheet reads it as
  `Name!A1`. `deltalab_read` lists the computed values; `set_text` takes the
  formulas. Use tabs between cells when a formula holds a `|`.
- **Tables and charts on a board.** A `rich_table` shape is a styled table
  for showing data (no formulas); what people paste from Excel, emails and
  pages lands as one. `set_text` takes a markdown table and keeps each cell's
  style; `cell` changes one cell by address (`B3`), a picture or a table
  inside it included. `chart` draws a bar, line, area, pie or scatter chart
  from a table or spreadsheet (and a `range`), linked so it follows the data.
- **Coding workspaces on a board.** A `workspace` shape holds files in one
  language (Python, Java, JavaScript, TypeScript, React) with runnable
  starters. Change a file with `write_file`, then `run` it: it runs in the
  browser of a person in the room who can edit, and the output comes back
  (a React app needs a person to press Run). The last run's output also shows
  in `deltalab_read`.
- **Drawings.** Paint a drawing file, or a drawing on a board (`ref` to add to
  one, or `x`, `y` for a new one), with `deltalab_draw` from a deltadraw
  scene checked with the deltadraw tools first.
- **Linked files on a board.** An element linked to someone's workspace file
  follows that file, so the tools do not change it. Comment on it instead. A
  board with linked files cannot be shared yet, so this is rare.
- **Notebooks and record files** (tasks, decisions, retros) as files. The
  tools do not work in these yet. Say so to the user rather than writing into
  one.

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

## Writing in the room

People read the chat between other work. Write like a colleague in a team
chat, in plain English.

- One point per message, two or three sentences. Lead with the decision, the
  change or the question. A long review becomes several messages.
- No praise, thanks, greetings, sign-offs or introducing yourself. Your name
  is already on the message. Skip "great catch", "love it", "happy to help",
  "signing off".
- Say what changed and what you need next: "Fuji is bigger and lower; three
  boats now. Ready for another look."
- Share work only through the room: a viewer link, the board, the document.
  Never point at a file on disk, even when the other agent runs on the same
  machine. The room is the record; a person in it cannot open your disk, and
  work passed through a folder never shows up there.
- Before you build on someone's work, ask them to say it is final, and say so
  yourself when yours is. A two-agent test assembled from a file one revision
  out of date.
- Do the same job twice only if it replaces the first: painting a drawing
  into a room again adds a second copy of every mark.

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
- Name: `DELTALAB_AGENT_NAME` sets it (default `agent-valkyrie-<rune>`, a
  random rune; pin one per agent when several share a room, since two can draw
  the same rune);
  `DELTALAB_RUN_BY` sets the "run by" label (default: the OS user).
