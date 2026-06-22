# Skill spec template (shared convention)

The fixed shape every rune's spec doc follows, across all packs. Each pack's
`plugins/<pack>/skills/SPEC-TEMPLATE.md` is a THIN pointer to this file plus its
own policy (which skills are design-heavy) - it does not restate the convention.

## Two doc kinds

- **REFERENCE.md** - LIVING. Describes what the code does NOW and must match it.
  Every skill has exactly one (named `REFERENCE.md`, or `SPEC.md` where a pack
  keeps a single combined file).
- **DESIGN.md** - WRITE-ONCE rationale: why the design is the way it is, plus a
  dated, append-only ADR decision log. Only design-heavy skills carry one.

The line: if a senior reader would ask "why is it built this way, and what did you
decide against?" and the answer is non-trivial, it needs a DESIGN.md. Otherwise
REFERENCE.md alone. Each pack states which of its skills cross that line.

## Drift rule (load-bearing)

Specs REFERENCE the canonical contract; they do NOT re-define it. Schemas, verbs,
flags, and output shapes live once in the pack's `../../contract/CONTRACTS.md`
(+ the `*.columns` files) and are guarded by `../../contract/contract-test.sh`. A
spec lists WHICH verbs/flags/outputs its skill uses and points at the contract for
the shapes. Copying a column schema or KEY=value vocabulary inline is a drift bug -
link instead. (`contract-test.sh` check 5 also asserts any schema a SKILL.md quotes
inline still matches the `.columns` field count.)

ASCII only (hyphen-minus; no em/en dashes), tight and senior: no praise adjectives,
no `Note:` callouts, document only the non-obvious WHY.

## REFERENCE.md - required sections (in order)

```markdown
# <skill> - reference

Follows /docs/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose
<what the skill IS in one breath; its place among the sibling runes; goals/non-goals>

## Scripts + data flow
<the scripts it drives, in invocation order; how data moves; where vision (if any)
happens. Name the verbs; do NOT document their flags (that is the contract).>

## Logic / algorithm
<the decision logic the skill OWNS - input resolution, branching, routing,
output shaping. The WHY of non-obvious choices.>

## Contract
<POINTS to ../../contract/CONTRACTS.md. Lists which verbs / flags / output markers
this skill consumes, by name. Does NOT re-define column schemas or row shapes.>

## Correctness + edge cases
<the cases that must hold: empty, missing input, oversize, name reuse, deletion,
the kind/branch boundaries the script does not handle on its own.>

## Parity
<.ps1 / .sh status and the VERIFIED platform; per-platform non-claims. A
single-backend change is a parity bug - update both in the same change.>

## Gotchas
<the sharp edges a maintainer needs to know>

## Status
<SHIPPED / PLANNED / verified-on-<platform> per capability>

## Verified by
<pointer to ../../contract/contract-test.sh and what it does / does not exercise>
```

## DESIGN.md - required sections (in order, design-heavy skills only)

```markdown
# <skill> - design

Follows /docs/SPEC-TEMPLATE.md (DESIGN kind). Write-once rationale.
For the living contract see ./REFERENCE.md and ../../contract/CONTRACTS.md.

## Goal / non-goals
<what it solves; the non-goals stated as non-claims on the skill page>

## The model / economics
<the cost model that justifies the architecture - e.g. the token tiers>

## Design choices + tradeoffs
<the decisions made and the alternatives weighed against them>

## Non-claims
<workloads / guarantees explicitly out of scope>

## Decision log (ADR)
<dated entries; each: DECISION, context (one line), why. APPEND-ONLY - amend by
ADDING an entry, never by editing a landed one. The audit trail for "why is it
like this".>
```
