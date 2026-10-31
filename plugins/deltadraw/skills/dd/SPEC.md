# dd - reference

Follows /docs/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

Turn "draw me X" into a `https://www.submillisecond.com/deltadraw` URL that
compiles a scene in the reader's browser, checked and looked at through the real
engine before it is handed over. The rune owns the choice between drawing and
diagramming, the scene the model writes, the look step and the hand-off.
Compiling, rendering and packing belong to the engine in `subms-ui`, reached
through the hosted MCP server or the worker's plain HTTP routes.
Non-goals: shipping the engine in the pack, and restating its grammar.

## Scripts + data flow

Three paths, best first:

- MCP (`.mcp.json`): the hosted `deltadraw` server. `deltadraw_check`,
  `deltadraw_png`, `deltadraw_url` and the rest; every answer from the engine.
- `scripts/dd-png.{ps1,sh}`: scene file -> POST `/png` -> a PNG file (one page of
  a multi-page scene); exit 1 when nothing drew. Network.
- `scripts/dd-gif.{ps1,sh}`: scene file -> POST `/gif` -> an animated GIF, the
  pages as frames or the first page being drawn. Network.
- `scripts/dd-url.{ps1,sh}`: scene file -> trim -> percent-encode over UTF-8
  bytes (or raw DEFLATE + base64url with compress) -> `URL=` + `LENGTH=`. No
  network.

## Logic / algorithm

1. Decide: drawing (`dd`) or diagram (`dg`).
2. Write the scene against the spec; prefer built-in symbols.
3. Check, render, look, fix; repeat.
4. Hand back the viewer URL; carry history with `previous_url` on a revision.

## Edge cases

- A painting from deltalab: `deltadraw_pack` (MCP only; the packer is engine code).
- A link that must stay readable in the address bar: plain `#dsl=` (the default
  for `dd-url`); everything else, `#d1=`.
- Very large scenes: the worker caps marks, points and repeat iterations and
  says which line hit the cap. A GIF is also capped on frames x pixels; a smaller
  width fits more frames.
- An animation: `page` / `tween` / `id` in the scene; check frames with
  `deltadraw_png` `page`, the whole with `deltadraw_gif`.

## Verification

`contract/contract-test.sh` (offline, both backends) and
`contract/live-test.sh` (the hosted worker).
