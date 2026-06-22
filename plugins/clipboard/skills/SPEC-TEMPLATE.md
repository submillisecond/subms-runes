# clipboard skill spec - pack policy

Follows the shared convention in `/docs/SPEC-TEMPLATE.md` (doc kinds, drift rule,
required sections, tone). This file states ONLY what is specific to clipboard.

## Which skills get which docs

- **Every clipboard skill is REFERENCE-kind.** One file per skill (`REFERENCE.md`,
  or `SPEC.md` for a combined file), no DESIGN.md split - each is a focused wrapper
  over the shared scripts, not a design epic. (Contrast imageverse's `img-search`.)
  If a clipboard skill ever grows a non-trivial design rationale, add a DESIGN.md
  then, per the shared rule.

## Pack notes

- The canonical contract is `../contract/CONTRACTS.md` (+ `history.columns`,
  `snippet.columns`), guarded by `../contract/contract-test.sh`.
- The contract test does NOT exercise the system clipboard: `clipboard-io`
  read/write and the `get` recall path touch the live clipboard and are out of
  scope for the automated test by design. State that in a skill's "Verified by"
  rather than implying full coverage.
- Sharp edges to carry in a skill's Gotchas: Windows STA requirement for
  `clipboard-io`, UTF-8 console encoding, TEMP vs data-dir locations.
