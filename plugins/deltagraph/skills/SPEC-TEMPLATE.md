# deltagraph skill spec - pack policy

Follows the shared convention in `/docs/SPEC-TEMPLATE.md` (doc kinds, drift rule,
required sections, tone). This file states ONLY what is specific to deltagraph.

## Which skills get which docs

- **`deltagraph` is REFERENCE-kind**, one combined `SPEC.md`. It is a thin wrapper over
  one encoder script plus a pointer at a specification that lives elsewhere; the
  design rationale (why the URL carries the source, why the fragment, why the
  grammar is generated and never copied) belongs to the `subms-ui` design docs,
  not to this pack.

## Pack notes

- The canonical contract is `../contract/CONTRACTS.md`, guarded by
  `../contract/contract-test.sh`, which runs BOTH backends and asserts identical
  bytes. Unlike the clipboard pack, nothing here touches the system clipboard, so
  the contract test covers the whole script.
- The GRAMMAR is not this pack's to define. It is generated from the engine in
  `subms-ui` and served at `https://www.submillisecond.com/deltagraph/spec.md`.
  A rune doc quotes a rule only as a reminder and names the spec as the
  authority; a doc that restates the grammar is a drift bug.
- Sharp edges to carry in the skill's Gotchas: `&` in the fragment, `|` in a
  label, one arrow per line, the mermaid kinds the engine does not draw.
