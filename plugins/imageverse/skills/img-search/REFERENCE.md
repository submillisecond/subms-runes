# img-search - reference

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

`/img-search` finds the image(s) matching a query across a directory tree -
cheap metadata (date, geo, name, size, dims) and semantic content - without
re-paying vision cost on a stable library. The script (`image-index`) does
everything deterministic and zero-token; the skill is the only place vision
happens. Rationale and the cost model live in ./DESIGN.md.

## Scripts + data flow

- `image-find` - enumerate + EXIF/GPS/camera + sha1; the live scan and the sole
  authority on presence. Owns date/recency filtering and the tier-0 hashcache.
- `image-index` - the deterministic engine: cold/warm diff, metadata prefilter,
  BM25-lite recall, hash-grouping, cold-worklist emission, cache writes, inline
  secret redaction, size cap + prune. No vision.
- `thumbs` + model - the skill's vision pass over the cold delta (or a top-K
  rerank), then `image-index put`.
- `geocode` - place-name resolution for the geo search path (forward + reverse).

Pipeline: scan (`image-find`) -> query (`image-index`) -> caption cold delta
(`thumbs` + vision + `put`) -> re-query -> hash-grouped reply.

## Store layout

Durable-state root, mirroring `clip-history` (owner-only ACLs; `%LOCALAPPDATA%`
on Windows, `${XDG_DATA_HOME:-$HOME/.local/share}` elsewhere):

```
<root>/runes/imageverse/index/
  captions.tsv     content-keyed structured record (the token-saving cache)
  hashcache.tsv    path -> sig -> sha1 fast path (tier 0, opt-in)
  .schema          integer; bump invalidates caption rows
```

GLOBAL and keyed by content hash, not folder or filename: a caption written by
one search (or opportunistically by `/img` / `/img-organize`) is warm
everywhere, and a move/rename/copy keeps it valid.

## Schema

The caption row is 20 columns keyed by `hash`; the `put` batch is 11 columns;
the `image-find` scan is 7. The authoritative lists and their order live in
../../contract/CONTRACTS.md (+ the `*.columns` files). This doc does NOT
duplicate them. `lat`/`lon`/`camera` are content-intrinsic (embedded in the
file bytes, consistent across exact copies); `place_path` is derived and cached
so reverse geocoding runs once per location.

## Contract (verbs / flags / outputs this skill uses)

Shapes are defined in ../../contract/CONTRACTS.md - listed here, not redefined.

- Verbs: `plan` (cold delta), `put -Batch [-Scan] [-Followers]` (write rows),
  `query -Tsv [-Query] [-TagAny] [-Name] [-MinBytes] [-Geo] [-Top]`,
  `facets -Tsv` (shared-index reads), `status`, `prune`, `clear`.
- `image-find` flags: `-Recurse -Hash`, date (`-Within`/`-Since`/`-Until`),
  optional `-HashCache` (tier 0), `-NearDup`/`-HammingMax` feed `plan`.
- Output markers consumed: `INDEX_COLD`, `INDEX_WARM`, `INDEX_HITS`,
  `INDEX_HIT` (6 fields), `INDEX_HIT_PATH`, `INDEX_FACET` (8 fields),
  `INDEX_PUT`, `INDEX_REDACTED`, `INDEX_EVICTED`, `INDEX_TOUCHED`,
  `INDEX_NEARDUP`, `INDEX_PROPAGATED`.

## Logic / algorithm (prefilter -> recall -> optional rerank)

1. Live cheap scan of the target dir (`image-find -Recurse -Hash`), tier 0/1.
   The `(hash, path, date, lat, lon, camera, size)` that ACTUALLY exist now;
   the sole authority on presence.
2. Metadata prefilter (tier 2, zero tokens): date (delegated upstream to
   `image-find`), geo (`-Geo lat,lon,km`, Haversine reused from `cluster`),
   `-Name`, `-MinBytes`, dims. Many real queries finish here.
3. Text recall (tier 3, zero tokens) over the cached structured fields of the
   survivors: BM25-lite (k1=1.5, b=0.75) over `text`/`entities`/`objects` with
   an exact-tag bonus on `category`/`subcategory`/`place_path`. Linear scan is
   fine to ~100k rows; an inverted index is a future lever. Returns top-K.
4. Cold candidates: prefilter survivors with no caption are emitted as
   `INDEX_COLD`. The skill captions them in one batched vision pass, `put`s
   them, and re-queries (now warm + cache warmed for next time).
5. Optional precision rerank (tier 4, bounded): for high-precision asks, vision
   only the top-K thumbnails to confirm/rank - never the mechanism for finding,
   only for disambiguating already-text-matched hits.

Results group BY HASH: one logical hit per distinct image, current paths listed
beneath, with a copy count (a natural `/img-dedup` hint). Copies outside the
searched scope are not returned but reuse the shared caption with no re-vision.
Near-copies collapse to one hit only when dHash propagation is on,
conservatively.

## Lifecycle (new / moved / edited / deleted)

Presence is decided by the live scan, never by the index. Every run is a
cold-delta diff, never a full re-vision.

| Event | What happens | Vision | False results? |
|---|---|---|---|
| New file added | hash not in cache -> COLD -> captioned this run | only the new file | no |
| Moved / renamed | same hash, new live path -> WARM, `seen_path` refreshed | zero | no |
| Edited in place | new hash -> new COLD; old row orphaned | only the changed file | no |
| Deleted | absent from live scan -> unreturnable; row a harmless orphan | zero | no (structural) |
| Name reused by a different file | different content -> different hash -> own entry | only the new file | no |

Deletion correctness is free: a deleted file is structurally unreturnable
because it is not in the live scan. The orphan caption row is a SPACE concern,
not a correctness one.

## Eviction (global cache)

Do NOT prune on absence - a hash absent from one dir's scan may live in another
folder. Prune only under size pressure.

- Cap at `RUNES_IMAGEVERSE_INDEX_MAX` (default 50k), evict by `last_seen`.
  `last_seen` is set on `put` AND refreshed by `query` for warm hashes in the
  scan (bounded once/day, `INDEX_TOUCHED=N`), so eviction is least-recently-USED.
  Enforced on `put` (`INDEX_EVICTED=N`). SHIPPED.
- `prune --days N` drops rows last seen before the cutoff (user action, never
  presence-based); `clear` nukes the cache. SHIPPED.

## Privacy / secrets

Cached `text` can capture API keys/tokens from screenshots into a durable file.
`put` runs an INLINE set of redaction patterns over each `text` (api-key
`sk-/pk-/rk-`, AWS `AKIA`, GitHub `gh*_`, bearer, PEM private-key headers, and
`key/secret/password/token = ...` pairs), replaces matches with
`[redacted:<type>]`, and reports `INDEX_REDACTED=N`. Inline (not a dependency on
the clipboard plugin) so imageverse stays self-contained. Store stays
owner-only ACL'd. SHIPPED.

## Geo and activity

Most of the ORGANISE side already exists in `img-organize` (location albums,
trip clustering by time+geo, reverse-geocoded cluster centroids, nested album
paths in `build-manifest`). The search additions are a facet model + scheme
templates + the geo SEARCH path.

### Facet model

Each image resolves to independent facets in the hash-keyed record: time (year,
month), place (`place_path`), trip (cluster id + name, real trips only),
activity (vision soft tag), content (category/objects). A "scheme" is a template
over facets that `build-manifest`'s nested album paths render:

| scheme | album example |
|---|---|
| `trip` (DEFAULT location) | `2026/06. Paris` (year-first, MONTH-PREFIXED) |
| `year-location` | `2026/Paris` (pools a city's visits; no month prefix) |
| `location-year` | `Paris/2026` |
| `year-activity` | `2026/Hiking` |
| `activity` | `Dining` |
| `year-month` | `2026/06` |

### geocode forward mode

`geocode -Query "<place>"` hits Nominatim `/search?...&format=jsonv2&limit=1`,
printing `GEOCODE_LATLON=<lat>,<lon>` + `GEOCODE_BBOX=<s,w,n,e>`. Privacy: sends
only a place NAME, opt-in, 1 req/s, real User-Agent (same policy as reverse).
The bbox is the natural "near X" extent; a default radius is the fallback.
SHIPPED.

### Geo search (zero vision)

"all photos near Paris in 2026" is a tier-2 metadata query, no captions needed:
resolve "Paris" (PREFER the cache - any indexed `place_path` containing Paris
gives a centroid with zero network; else forward-geocode), filter the live scan
by Haversine radius/bbox AND year/date, return hash-grouped hits with place +
date. Activity search ("all hiking photos") is a tier-3 match on the cached
`activity` field - vision only for the cold delta. SHIPPED.

### Trip vs city vs activity routing

Route each cluster by context (lives in `img-organize` skill prose, not a script
flag). Detect HOME (densest GPS location, or a `prefs` override). Per cluster:
geotagged + away-from-home + spans real time -> TRIP (year-first,
month-prefixed: `2026/06. Paris`); geotagged + near-home or a single session ->
everyday scheme; no geo (screenshots) -> content/date. Rule: trip > place/time >
activity; activity is an opt-in secondary axis, never the default leaf for a
trip. Multi-city trips split by city by default. `build-manifest` keeps the
`MM.` prefix on the FOLDER, strips it from the FILE stem. SHIPPED in both
backends.

### Shared index across img-search AND img-organize

The cache is SHARED infrastructure; both runes are clients, so a photo looked at
by either is warm for both, and they stay consistent (both speak the same
`category`/`subcategory`/`activity`/`place_path` vocab, centralised in the
schema; changing it bumps `.schema`). `img-organize` READS facets via
`image-index facets -Tsv` (skip re-visioning warm clusters) and WRITES via the
opt-in warming hook. The index supplies facts; the skill supplies the album
policy (trip-vs-everyday routing + naming). SHIPPED.

## Integration hooks (free cache warming)

`/img` and `/img-organize` already vision-read thumbnails. An OPT-IN tail step
(off by default) `image-index put`s their observations into the same global
cache, so normal browsing/organising warms search at zero extra token cost.
Idempotent (last-write-wins). Wired into both SKILL.md files. SHIPPED.

Reuse, do not duplicate: `image-find` (enumerate/EXIF/GPS/hash), `thumbs`
(vision), `workspace` (temp), `cluster`'s Haversine (geo filter), `geocode`
(place names), `clip-history`'s store/ACL/cap/secret patterns.

## Correctness + edge cases

- Cold -> warm: index a folder, re-run -> `INDEX_COLD=0`, zero vision.
- Move/rename: reshuffle the tree -> `INDEX_COLD=0` (content-keyed).
- Name reuse: rename A, create B with A's old name -> B is its own entry, no
  false hit.
- Identity guard (tier-0 hashcache): replace a file in place with same
  size+mtime but different content -> rehash forced via FileId/inode.
- Duplicate collapse: 3 identical files -> 1 caption, all 3 surface grouped.
- Geo: a GPS photo -> `lat`/`lon`/`place_path` cached; "in <place>" matches.
- Metadata-only query returns with zero captions present (no vision path).
- Secret redaction: a fake `sk-...` key -> `text` stores `[redacted:...]`.
- Schema bump invalidates old rows. Cap eviction at `MAX` by `last_seen`.

## Parity

`.ps1` + `.sh` for `image-find`, `image-index`, `geocode`, `cluster`,
`build-manifest`. Both backends are parity-tested (identical BM25 scores,
hash-grouping, geo filter, cold emission, column order). Verified path is
asserted by the contract test on both backends.

## Gotchas

- `put` must use a freshly computed hash from the live scan, never a
  tier-0-cached one. Tier-0 only feeds the cheap warm/cold prefilter.
- Default to real-hashing (`image-find -Hash`, cheap to a few thousand images,
  zero staleness risk); enable `-HashCache` only for 10k+ multi-GB trees.
- `status` labels not-in-this-scan rows "elsewhere/unseen", never "stale" - a
  global cache means absence here is not absence on disk.

## Status

Core + the four follow-ups SHIPPED: content-addressed `captions.tsv` + `.schema`,
dHash + dims, inline secret redaction, BM25-lite recall, geo/size/name/tag
prefilter, hash-grouped hits, cold emission, size cap + `prune`; near-dup
collapse (`plan -NearDup` + `put -Followers`); tier-0 `hashcache`
(`image-find -HashCache`); `geocode` forward + reverse; LRU scan-refresh;
shared-index reads (`facets -Tsv`); opportunistic warming hooks in `/img` and
`/img-organize`. PLANNED: CLIP-embedding semantic layer (parked, non-claim);
inverted index for recall beyond ~100k rows.

## Verified by

../../contract/contract-test.sh
