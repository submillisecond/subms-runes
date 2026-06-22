# img-search - design

Follows skills/SPEC-TEMPLATE.md (DESIGN kind). Write-once rationale.
For the living contract see ./REFERENCE.md and ../../contract/CONTRACTS.md.

## Goal / non-goals

Goal: a `/img-search` rune that finds the image(s) matching a query across a
directory tree (including subdirs), where the query spans cheap metadata (date,
geo, name, size, dims) and semantic content ("the error dialog", "receipts",
"beach photos in Santa Monica"). Repeated searches over a stable library must
not re-pay vision cost.

Non-goals (stated as non-claims on the skill page):

- Not fuzzy visual similarity ("cozy autumn vibes"). That needs an embedding
  model (a heavy native dep), out of the zero-install ethos. Keyword/BM25 over
  structured captions is what ships.
- Not OCR of record. Cached visible-text is vision-extracted for recall, not a
  guaranteed transcript - that is `/clip-ocr`'s job on a single image.
- Not real time. A cold library's first semantic search pays vision on the
  whole distinct-image set; the win is amortization across many later searches.

## The model / economics

The only expensive tier is vision. Every cheaper tier shrinks the candidate set
handed to the next, so vision is a once-per-distinct-image cost.

| Tier | Work | Cost | Source |
|---|---|---|---|
| 0 | path+identity+date -> skip rehash | ~0 | `image-find -HashCache` (opt-in, large trees) |
| 1 | enumerate + EXIF/GPS/camera + sha1 | ~0 | `image-find -Recurse -Hash` |
| 2 | metadata prefilter (date/geo/name/size/dims) | ~0 | `image-index query` |
| 3 | text recall over cached structured captions | ~0 | `image-index query` |
| 4 | vision read of thumbnails | expensive | `thumbs` + model, cold delta or top-K rerank only |

The honest economics: the cold pass is O(distinct images), unavoidable - you
cannot find content you have never looked at. The lever is to look ONCE and
extract maximally, so warm searches answer from text at tier 3 and never
re-input the image.

## Design choices + tradeoffs

### Content-addressed cache

The cache is GLOBAL and keyed by content hash, not by folder or filename. This
buys move/rename/copy proof (same bytes, same hash, caption already valid),
cross-folder and cross-rune reuse, and no time-based invalidation. Content
addressing means a caption can never go stale; only a `.schema` bump
invalidates it. That deletes the hardest correctness problem outright.

### Structured extraction (the index quality lever)

Recall is only as good as what the cold vision pass captured. Because the
image-input cost is sunk the moment the thumbnail is read, extract maximally in
that one look: a controlled (soft) vocab for `category`/`subcategory`, all
visible text into `text`, salient items into `objects`, named things into
`entities`. Bump `iv` when the vocab changes. The column set is the contract -
see ../../contract/CONTRACTS.md.

### Near-dup reduction

Exact dups collapse for free via sha1 keying (N copies, one look). Near dups
(different bytes) collapse via local dHash hamming distance, no model/deps,
under a conservative threshold. A propagated record carries only COARSE fields
and is marked lower-confidence - never the `text`/`entities`/`attributes` that
subtly different look-alikes differ in. The non-claim: a propagated record is
lower confidence than a looked-at one.

### Semantic layer: BM25 vs embeddings

- A. Captions + BM25-over-structured-text (ships). In-ethos: vision does the
  extraction, no engine to install, pure local PS/sh, zero deps. Covers the
  dominant "find the screenshot/photo with X" need.
- B. CLIP embeddings + vector search (parked, non-claim). True visual
  similarity, but bundles a native model and breaks the zero-install promise.
  Documented as the future lever; not built in v1.

## Non-claims

- No fuzzy visual similarity (needs embeddings, breaks zero-install).
- No OCR-of-record guarantee on cached `text`.
- No real-time first-search; the cold pass is O(distinct images).
- A propagated near-dup record is lower confidence than a looked-at one.
- tier-0 hashcache is a PERFORMANCE cache; correctness never depends on it. The
  `put` that writes a caption always uses a freshly computed hash, never a
  cached one.

## Decision log (ADR)

Append-only. Amend by ADDING an entry, never by editing a landed one.

### 2026-06-22 - Content-addressed (sha1) cache; the hash is the authority, not mtime
Context: filename/folder/mtime keys all go stale on move, rename, copy, or
touch. Why: keying on content hash makes a caption path-independent and
non-staleable - a touched or relocated file reuses its caption, and only a
`.schema` bump can invalidate a row. mtime is a rehash TRIGGER, never the
invalidation authority.

### 2026-06-22 - last_seen LRU refreshed on query, bounded once/day
Context: eviction by last-PUT time evicts images that are searched often but
re-captioned rarely. Why: a search is a use, so `query` bumps `last_seen` for
warm hashes in the scan; bounding the refresh to once/day avoids write
amplification on every query while still making eviction least-recently-USED.

### 2026-06-22 - BM25-lite over cached captions, not embeddings
Context: the semantic layer needs a ranking engine. Why: BM25-lite over the
structured caption fields is pure local PS/sh with zero deps and covers the
dominant "find the screenshot/photo with X" need; embeddings would bundle a
native model and break the zero-install ethos. Embeddings are parked as the
documented future lever, not v1.

### 2026-06-22 - Date filtering delegated upstream to image-find
Context: date/recency could be filtered in `image-index query` or in the
scan producer. Why: `image-find` already owns the calendar-bucket logic
(`-Within`/`-Since`/`-Until`) and produces the `-Tsv` scan, so delegating
date there keeps that logic in one language pair instead of re-implementing it
in `query` for both backends.

### 2026-06-22 - Inline secret redaction in put
Context: cached `text` is model-extracted on-screen text and can capture API
keys/tokens from screenshots into a durable file. Why: `put` runs an inline set
of redaction patterns over each `text` before persisting, rather than depending
on the clipboard plugin's `secret-scan`, so imageverse stays self-contained.

### 2026-06-22 - Near-dup propagation conservative: coarse fields only, never text
Context: near-dups (different bytes, small hamming distance) could share a full
caption. Why: subtly different look-alikes differ exactly in `text`/`entities`/
`attributes`, so propagation copies only coarse fields and marks
`source=propagated:<rep>`; propagating text would manufacture false recall hits.

### 2026-06-22 - tier-0 hashcache rebuilt per scan; signature includes file identity
Context: a path+size+mtime key returns a stale hash when a different file lands
at an old path with coincidentally equal size and mtime. Why: the signature is
size+mtime+ctime(+inode on Unix), so a different file forces a rehash even on a
size/mtime collision; the cache is rebuilt (self-pruning) from each scan and is
PERFORMANCE-only - `put` always uses the live hash.

### 2026-06-22 - img-organize trip scheme is year-first and month-prefixed
Context: trip albums need a stable, chronologically sortable layout, while
pooling schemes span months. Why: the default `trip` scheme renders
`2026/06. Paris` (year-first, `MM.` = trip start month, so folders sort
chronologically and two same-year Paris trips stay separate); pooling schemes
(year-location, activity) span months so carry NO month prefix. `build-manifest`
strips the `MM.` prefix from the FILE stem (the date in the name already orders
files) but keeps it on the FOLDER.
