# imageverse skill spec - pack policy

Follows the shared convention in `/docs/SPEC-TEMPLATE.md` (doc kinds, drift rule,
required sections, tone). This file states ONLY what is specific to imageverse.

## Which skills get which docs

- **Design-heavy (both DESIGN.md + REFERENCE.md):** `img-search` - the token/cost
  economics, structured-extraction and near-dup reasoning, and BM25-vs-embeddings
  tradeoff are non-trivial and worth a frozen rationale.
- **Reference-only (one REFERENCE.md):** `img`, `img-edit`, `img-save`,
  `img-organize`, `img-dedup` - wrappers over the shared scripts with no standing
  design debate; a rationale doc would just rot.

## Pack notes

- The canonical contract is `../contract/CONTRACTS.md` (+ `captions.columns`,
  `put.columns`, `imagefind.columns`), guarded by `../contract/contract-test.sh`.
- A `phash` VALUE may differ across backends (different resampler); the `sha1`
  content key that drives warm/cold is identical cross-platform - note this where
  relevant rather than implying byte-equivalence.
