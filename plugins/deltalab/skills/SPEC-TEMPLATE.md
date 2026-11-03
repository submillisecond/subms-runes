# deltalab skill spec - pack policy

Follows the shared convention in `/docs/SPEC-TEMPLATE.md` (doc kinds, drift rule,
required sections, tone). This file states ONLY what is specific to deltalab.

## Which skills get which docs

- **`deltalab` is REFERENCE-kind**, one combined `SPEC.md`. The rune drives an
  MCP server whose behaviour is fixed by `../contract/CONTRACTS.md`; the design
  of the room (signed envelopes, Review mode, the relay) belongs to the
  `subms-ui` design docs, not to this pack.

## Pack notes

- The client is a build artefact of `subms-ui/apps/deltalab`, signed and
  published by its deploy; this pack holds only the loader. A change to a tool
  is made there and deployed, and the contract, the contract test and the
  SKILL.md move in the same sweep.
- `contract-test.sh` needs only Node: it starts the loader and checks the
  handshake, the tool list against the contract table, and the refusal paths.
  It never joins a room.
