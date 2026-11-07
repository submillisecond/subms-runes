---
name: deltagraph
description: This skill should be used whenever a diagram is wanted or would help - "draw this", "diagram", "flowchart", "sequence diagram", "architecture diagram", "state machine", "ERD", "mind map", "timeline", "kanban", "show me how X flows", "/deltagraph", or any moment you would otherwise write a mermaid fence - and whenever a deltagraph link does not render, renders wrong, or reads badly ("why is this diagram broken", "tidy this diagram", "the arrows are a mess", "debug this deltagraph"). Produces a deltagraph.submillisecond.com URL that renders the diagram laid out and routed, checked through the real engine via the bundled deltagraph MCP server, and debugs a failing or tangled one down to the line and rule. Carries the per-kind table, the native DSL essentials, the hard rules and the substitutes for mermaid kinds the engine does not draw; fetches the generated spec for anything beyond that.
version: 1.0.0
---

# deltagraph - draw a diagram as a deltagraph URL instead of a mermaid fence

A deltagraph link IS the diagram: the source rides in the URL fragment and the
viewer at `https://deltagraph.submillisecond.com/` lays it out, routes it and
draws it. A mermaid fence renders nowhere a terminal reader looks; a URL renders
for anyone who clicks it. So: never a mermaid fence. A URL.

The grammar is generated from the engine and served at
`https://www.submillisecond.com/deltagraph/spec.md` (readable at
`/deltagraph/spec`). This file carries enough for the common case; fetch the
spec, or call `deltagraph_spec`, when you need a kind's exact syntax. The pack's
contract is `../../contract/CONTRACTS.md`.

## The loop, with the bundled server

Installing this pack registers the hosted `deltagraph` MCP server. When its
tools are available, use them; they run the real engine.

1. **Pick the kind and write the source** (below).
2. **`deltagraph_check`** it. Fix every error and warning.
3. **`deltagraph_png`** and look at the picture: labels whole, the hot path
   visible, nothing routed through a box, no knot of crossing edges.
4. **`deltagraph_debug`** when check fails and the fix is not obvious, when the
   picture reads badly, or before handing over anything past a dozen nodes. It
   names each dropped line and the rule it broke, the mistakes the engine
   accepts silently (a node in two groups, a shape given twice, an unclosed
   subgraph, a stray `end`, an unknown direction, role or edge class), and
   scores the layout (crossings, bends, back edges, routing violations). It
   tries the other direction and other declaration orders and returns the best
   source it found, plus the picture with problem edges amber and clipped
   nodes red. Take a better source only when it keeps the author's labels,
   shapes and groups; a reorder moves declarations, nothing else.
5. **`deltagraph_url`** for the links. Hand back the viewer URL as a named
   markdown link (see Handing diagrams over) and say in a few words what it
   shows. When the diagram is a new
   version of one you handed back before, pass `previous_url` so the link
   carries its history.

To change an existing link, `deltagraph_edit` with ops; to compare two,
`deltagraph_diff`; to combine two forks of one link, `deltagraph_merge`; to
draw from terraform, CloudFormation, Cargo or a Kafka Streams topology,
`deltagraph_from_code`. The `tidy` prompt runs step 4 on a link end to end.

## Writing the source

Pick the kind. For a system, a pipeline, a hot path or an architecture, the
native DSL. Otherwise the mermaid header for the kind: `flowchart TD`,
`sequenceDiagram`, `stateDiagram-v2`, `erDiagram`, `classDiagram`, `mindmap`,
`requirementDiagram`, `journey`, `kanban`, `timeline`, `gitGraph`,
`quadrantChart`, `radar`, `treemap`. Not drawn, use instead: `gantt` ->
`timeline`; `pie` -> `treemap`; C4 /
`architecture` / `block` / `sankey` / `packet` -> native DSL; `xychart` ->
`radar`; `zenuml` -> `sequenceDiagram`.

Native DSL essentials:

- First line `direction: left_right`, `top_down`, or `auto` to let the engine
  keep whichever direction scores better; `theme: light` optional;
  a line starting `#` is a comment.
- Nodes: `id[box]` `id(round)` `id{decision}` `id[[queue]]` `id((source))`
  `id{{engine}}` `id[(store)]` `id/actor/` `id<<aws:lambda|Label>>`.
  Roles after the shape: `:::in` `:::proc` `:::dec` `:::out` `:::err`
  `:::ext`. `:::pulse` on the one hot endpoint.
- Edges, one per line: `-->` normal, `==>` hot, `-.->` slow, `---` line,
  `=full=>` fires when the buffer fills. Label with meaning and class:
  `a -->|#write persist| b`; classes `#write` `#read` `#hot` `#cold` `#warn`
  `#ctrl`.
- Groups: `subgraph Label` ... `end`, nested. Declare a node in ONE group;
  draw cross-group edges after the blocks.

Titles are plain noun phrases: "Tick to trade", never "Tick to trade, four
versions".

## Handing diagrams over

A link full of encoded source is unreadable, and a wall of them is worse.

- **One named markdown link per diagram, to the viewer:**
  `[Architecture](https://deltagraph.submillisecond.com/#d1=...&title=Architecture)`,
  then a line on what it shows. Use the `#d1=` form and set `title`. Several
  diagrams are a short list of these, one per line.
- **Never print the raw URL** in prose, a table or a code block, and never
  the `/svg`, `/png` or `/check` addresses used to test a render. Those are
  for checking. Report "all six render" and hand over the viewer links.
- **To paste somewhere else** (Slack, email, a ticket), or when a terminal
  shows the whole address, make a short link: `POST https://www.submillisecond.com/l`
  with `{"target": "<viewer url>", "title": "<name>"}` returns
  `{"short": "https://www.submillisecond.com/l/<id>"}`, which previews as the
  diagram. It stores the diagram on the server until 30 days after its last
  visit, so ask first for anything private; the viewer link stores nothing.

## Without the server

The pack's scripts cover a session with no MCP. Write the source to a file
(`.dg` by convention), then:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/dg-url.ps1" diagram.dg -Title "Tick to trade"
bash "${CLAUDE_PLUGIN_ROOT}/scripts/dg-url.sh" diagram.dg --title "Tick to trade"
```

`dg-url` prints `URL=...` and `LENGTH=...`, with no network. Options: title,
theme `light|dark`, bg (`-Bg` / `--bg`: `transparent`, `black`, `white`,
`auto` or a hex colour), dir `LR|TD`, debug, edit, base for a local viewer,
and `-Compress` / `--compress` for the shorter `#d1=` form, which is the one
to use past a few lines.

To find out why a source fails or reads badly, `dg-debug` posts it to the
hosted debugger and prints the same report `deltagraph_debug` gives; exit 1
means it does not render:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/dg-debug.ps1" diagram.dg -Review review.svg
bash "${CLAUDE_PLUGIN_ROOT}/scripts/dg-debug.sh" diagram.dg --review review.svg
```

Without the scripts either, percent-encode the source and build
`https://deltagraph.submillisecond.com/#dsl=<encoded>`; `&` MUST be
encoded. The worker also answers plain HTTP: `/check`, `/debug`, `/svg`,
`/png?d1=<compressed>` (a picture for a README) and `/s?d1=<compressed>&title=`
(a share link that previews as the diagram on LinkedIn, Slack and X), all on
`https://deltagraph.submillisecond.com`.

## Hard rules

Each is a silent failure in the viewer, and each is one `deltagraph_debug`
names by line. One arrow per line. No raw `|` in a label. A node's shape on
first use, bare after. One `subgraph` per node. No closing delimiter inside a
shape. At most one `:::pulse`. Only the six edge classes colour a path.
Draw it architecture-grade, with zones, matching shapes, classed
edges, one pulse.

## Gotchas

- A raw `&` anywhere in the fragment ends the source: the diagram truncates at
  that label with no error. The script escapes it; a hand-built URL must too.
- The legacy `?dsl=` query form still renders but is sent to the server and
  hits an 8 KB limit. Generate the `#dsl=` or `#d1=` fragment form only.
- A `theme:` directive in the source and a `&theme=` option both work; the
  option wins.
- `&bg=` sets the ground on its own: `transparent` (a PNG from `/png` keeps
  its alpha, for a slide or a doc), `black`, `white`, `auto` (the reader's OS
  scheme) or a hex colour without its `#`. `transparent`, white and light
  colours take light ink unless `theme` pins it.
- `&debug=true` on a viewer link shows the same diagnostics under the
  diagram, with the layout search and a button to take a better source.
- The viewer refuses the mermaid kinds it does not draw and names the
  substitute; do not try to force one through.

## Verified by

`../../contract/contract-test.sh`: both `dg-url` backends over one fixture,
identical plain bytes, round-trip decode plain and compressed, option order,
error paths; the `dg-debug` usage paths; the MCP entry and this file against
the contract. The server's tools are tested in `subms-ui`.
