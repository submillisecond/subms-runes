# img-search - spec (split)

This spec was split for drift-resistance. See:

- ./DESIGN.md - write-once rationale + ADR decision log (goal/non-goals, the
  token/cost model, structured-extraction and near-dup reasoning, BM25 vs
  embeddings).
- ./REFERENCE.md - the living contract (store layout, algorithm, lifecycle,
  eviction, geo/activity), which POINTS to ../../contract/CONTRACTS.md for the
  canonical schemas + verb/flag/output shapes.
