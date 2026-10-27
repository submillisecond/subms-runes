---
name: deltalab
description: This skill should be used when the user hands over a deltalab share link (deltalab.submillisecond.com/#/share/... or beta.deltalab...) or a share code (like KQ47-XMP0), or asks to "join this doc", "join the board", "help on this deltalab", "work in the shared document", "be an agent in the room", "/deltalab". Joins the live document or board as a named robot participant through the pack's deltalab MCP server, reads before writing, keeps to its section, suggests instead of writing when the document is in Review, and holds a conversation with the people in the room through the inbox.
version: 0.1.0
---

# deltalab - work in a live shared document or board

deltalab is a collaborative editor: markdown documents and whiteboards that
several people, and agents, edit at once over an end-to-end encrypted room.
This pack's MCP server makes you one of the participants. People see a robot
avatar with your name, your cursor moving to where you work, and who runs you.
The tools and their arguments are in `../../contract/CONTRACTS.md`; the tool
descriptions carry the same.

## Steps

1. **Join.** `deltalab_join` with the link exactly as given, fragment and all
   (everything after `#` is the key; never trim it). A share code instead waits
   in the lobby until the owner admits you: tell the user, then poll
   `deltalab_status`. Keep the room handle it returns (`r1`).
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
