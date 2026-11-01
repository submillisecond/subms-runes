# dg - reference

Follows /docs/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

Turn "draw me X" into a `https://deltagraph.submillisecond.com/` URL instead
of a mermaid fence, checked through the real engine before it is handed over,
and turn "this diagram is broken / a mess" into the line, the rule and the fix.
The rune owns the choice of kind, the source the model writes, the review step
and the hand-off. Validation, layout, debugging and rendering belong to the
engine in `subms-ui`, reached through the hosted MCP server the pack registers,
or through the worker's plain HTTP routes when MCP is not available.
Non-goals: shipping the engine in the pack, and restating its grammar.

## Scripts + data flow

Three paths, best first:

- MCP (`.mcp.json`): the hosted `deltagraph` server over Streamable HTTP. The
  model calls `deltagraph_check`, `deltagraph_png`, `deltagraph_debug`,
  `deltagraph_url` and the rest; every answer comes from the engine.
- `scripts/dg-debug.{ps1,sh}`: source file -> POST `/debug` -> the same report
  `deltagraph_debug` gives, on stdout; exit 1 when it does not render. Network.
- `scripts/dg-url.{ps1,sh}`: source file -> trim -> percent-encode over UTF-8
  bytes (or raw DEFLATE + base64url with compress) -> `URL=` + `LENGTH=`. No
  network.

## Logic / algorithm

The rune's own logic is the decision table (kind from intent, substitute for a
mermaid kind the engine lacks), the source-writing rules (shape by role,
classed edges, one pulse, groups) and the loop: check, look, debug when it
fails or reads badly, link. It is deliberately a subset of the spec: enough to
draw the common case without a fetch, and a pointer for the rest, so the pack
does not grow a second copy of a grammar that already drifted once when it was
kept in three places.

The debugger's search (other direction, other declaration orders, scored by
crossings, bends, back edges and routing violations) runs in the worker. The
rune's rule on top of it: take a better source only when it keeps the author's
labels, shapes and groups.

## Contract

See ../../contract/CONTRACTS.md: the MCP entry; `dg-url` flags (`title`,
`theme`, `bg`, `dir`, `debug`, `edit`, `compress`, `base`), the two output
keys, the error shape, both encoding rules; `dg-debug` flags (`json`,
`review`, `no-optimise`, `tries`, `host`) and its exit codes.

## Correctness + edge cases

- Empty source: `dg-url` still prints a URL; the viewer shows its gallery.
  The rune should not emit an empty diagram.
- `&` or `|` in a label: encoded by the script; `|` inside an edge label is a
  grammar error, which `deltagraph_debug` names as `no-pipe-in-label`.
- A mermaid kind the engine lacks: the viewer refuses it with the substitute
  named; the rune picks the substitute up front.
- Very long source: the fragment has no server limit, but a plain link to a
  large diagram is unwieldy in chat; `compress` gives the `#d1=` form.
- A source the engine accepts but draws wrong (an arrow swallowed by an
  unclosed shape, a node claimed by two groups): only the debugger sees it;
  the picture alone reads as an engine fault.

## Parity

`.ps1` verified on Windows 11 / PowerShell 5.1; `.sh` verified under Git Bash
on the same box and written for any POSIX sh with `od`, `sed`, `tr`, plus
`gzip` for compress and `curl` for `dg-debug`. The contract test asserts
byte-identical plain output across the two `dg-url` backends, and that each
compressed link inflates to the source (the deflaters may differ). A change to
one backend without the other is a parity bug.

## Gotchas

`-Debug` is a PowerShell common parameter, so the `dg-url` switch is
`-ShowDebug`; `-Host` is a PowerShell automatic variable, so `dg-debug` takes
`-HostUrl`. The encoder is hand-rolled on purpose: `[uri]::EscapeDataString`
and `jq @uri` disagree on `! * ' ( )` across runtimes.

## Status

SHIPPED 1.0.0, verified-on-windows (ps1) and verified-on-git-bash (sh). The
MCP entry targets the production worker; `dg-debug` was verified against the
worker handler run locally, ahead of the `/debug` route's deploy.

## Verified by

`../../contract/contract-test.sh`.
