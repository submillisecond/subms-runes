# imageverse data contracts (canonical)

This is the canonical, human-readable contract for the imageverse plugin
scripts. It is the single source of truth for every data schema and every
`KEY=value` output line the scripts emit. Skill / SPEC docs POINT here; they
must NOT re-define columns or output rows. Re-definition is what caused drift -
keep it in one place and guard it with a test.

The machine-readable column ORDER lives in the sibling `.columns` files (one
column per line, order significant). This doc names them; the files are the
data:

| Schema | File | Cols | Key | Used by |
|---|---|---|---|---|
| captions | `captions.columns` | 20 | `hash` | `image-index` store rows |
| put batch | `put.columns` | 11 | `hash` | `image-index put --batch` input |
| image-find scan | `imagefind.columns` | 7 | `path` | `image-find` TSV scan output |

Verified by `./contract-test.sh` (runs both backends against an isolated store,
exits non-zero on any drift between this doc, the `.columns` files, and the
live script output). `image-index.ps1 $COLS` is asserted equal to
`captions.columns` by that test, so the store schema cannot drift from the
canonical list without a red run. A `.schema` integer in the store gates row
validity; bumping it invalidates caption rows below the new version.

The `.ps1` and `.sh` backends are byte-equivalent on these shapes;
`image-index.ps1` / `image-find.ps1` are the verified backends, the `.sh`
ports mirror them. A perceptual-hash (`phash`) VALUE may differ between
backends (different resampler); the `sha1` content key that drives warm/cold
is identical cross-platform.

---

## 1. Data schemas

### 1.1 captions.tsv (the index store) - 20 columns

One row per content hash. Column order is the on-disk contract; see
`captions.columns`. Stored at
`${XDG_DATA_HOME:-$HOME/.local/share}/runes/imageverse/index/captions.tsv`
(`.sh`) / `%LOCALAPPDATA%\runes\imageverse\index\captions.tsv` (`.ps1`).

| # | Name | Meaning |
|---|---|---|
| 1 | `hash` | sha1 content hash. The path-independent primary key. |
| 2 | `iv` | index/schema version (integer). A row is live only when `iv >= .schema`. |
| 3 | `phash` | 64-bit dHash as 16 hex chars (gradient, left>right). Blank if no ImageMagick. Local-only; not compared cross-machine. |
| 4 | `last_seen` | ISO 8601 UTC timestamp of last put/touch. LRU key for eviction + prune cutoff. |
| 5 | `seen_path` | one representative path last seen for this hash (informational). |
| 6 | `w` | pixel width (blank if undecodable). |
| 7 | `h` | pixel height (blank if undecodable). |
| 8 | `lat` | GPS latitude (joined from the scan TSV at put time; blank if none). |
| 9 | `lon` | GPS longitude. |
| 10 | `camera` | camera model string (EXIF Model). |
| 11 | `place_path` | reverse-geocoded place path (e.g. `France/Paris`). |
| 12 | `activity` | activity label. |
| 13 | `category` | top-level content category. |
| 14 | `subcategory` | finer category. |
| 15 | `entities` | named entities (people/landmarks). |
| 16 | `objects` | salient objects. |
| 17 | `attributes` | visual attributes. |
| 18 | `text` | on-screen text, redacted + sanitised, capped at 2000 chars. |
| 19 | `caption` | one-line caption. |
| 20 | `source` | provenance: `model`, or `propagated:<rep-hash>` for a near-dup follower. |

### 1.2 put batch row (`--batch` input) - 11 columns

The upsert row fed to `image-index put`. Tab-separated; parsed with `cut`
(empty fields are kept, not folded). See `put.columns`. Field 11 (`text`) is
taken as `-f11-` so it may itself contain stray tabs.

| # | Name | Maps to captions col |
|---|---|---|
| 1 | `hash` | 1 (`hash`); required, row skipped if empty. |
| 2 | `path` | drives dims + phash open (not stored verbatim as a column). |
| 3 | `category` | 13 |
| 4 | `subcategory` | 14 |
| 5 | `activity` | 12 |
| 6 | `place_path` | 11 |
| 7 | `entities` | 15 |
| 8 | `objects` | 16 |
| 9 | `attributes` | 17 |
| 10 | `caption` | 19 |
| 11 | `text` | 18 (redacted + sanitised) |

`lat`/`lon`/`camera` (captions cols 8/9/10) are joined in from the `--scan` TSV
by hash, not supplied in the batch row. `iv`, `phash`, `last_seen`, `w`, `h`,
`seen_path`, `source` are computed by `put`.

### 1.3 image-find TSV - 7 columns

One line per matched image file, newest first. See `imagefind.columns`.

| # | Name | Meaning |
|---|---|---|
| 1 | `date` | `YYYY-MM-DD HH:MM:SS` sortable date; `.fff` sub-second appended when EXIF SubSecTimeOriginal is present (burst ordering). EXIF DateTimeOriginal else file mtime. |
| 2 | `size` | file size in bytes. |
| 3 | `sha1` | sha1 hash, or empty unless `--hash` / `-Hash` was passed. |
| 4 | `path` | full file path. |
| 5 | `lat` | GPS latitude (EXIF; blank if none / no exiftool). |
| 6 | `lon` | GPS longitude. |
| 7 | `camera` | camera model (EXIF Model). |

### 1.4 cluster CLUSTER line

`cluster` prints `CLUSTER_COUNT=N`, then per cluster (newest first) a 7-field
tab line:

```
CLUSTER <TAB> id <TAB> count <TAB> start..end <TAB> geo <TAB> reps=i,j,k <TAB> index-ranges
```

| Field | Meaning |
|---|---|
| `CLUSTER` | literal marker. |
| `id` | 1-based cluster id, newest first. |
| `count` | members in the cluster. |
| `start..end` | `YYYY-MM-DD HH:MM..HH:MM` span, or `undated`. |
| `geo` | `lat,lon` centroid (3dp), or `-` if no GPS. |
| `reps=i,j,k` | first / middle / last member indices (1-based into the scan). |
| `index-ranges` | member indices compressed to ranges, e.g. `1-16,19,22-26`. |

### 1.5 build-manifest manifest line + dest-name rule

`build-manifest` writes one tab line per image:

```
<op> <TAB> <src> <TAB> <dest>
```

`op` is `move` or `copy`. The dest path is fully deterministic:

```
<base>/<album>/<file-stem>[-N].<ext>
```

`<album>` may be a nested path (`yyyy/mm/album`). The FOLDER keeps any
chronological `MM. ` month prefix (e.g. `06. Paris`); the FILE stem DROPS that
`(0[1-9]|1[0-2])\. ` prefix (the date already orders files). The file-stem
rule:

```
<leaf>-YYYY-MM-DD-HHMMSS[.subsec][-N].ext
```

- `<leaf>` = album leaf with the `MM. ` month prefix stripped from the stem.
- date/time from EXIF (`--meta` TSV) if available, else a `YYYY-MM-DD` in the
  source filename, else file mtime; `undated` / `000000` as a last resort.
- `[.subsec]` appended only when EXIF sub-second is present.
- `[-N]` collision suffix (`-2`, `-3`, ...) within one album+stem group.

### 1.6 file-ops journal line

`file-ops` writes a durable reverse-manifest journal under
`<data>/runes/<plugin>/journals/<apply|restore>-YYYYmmdd-HHMMSS-PID.tsv`. It is
a manifest in the same `op<TAB>src<TAB>dest` shape, where each line reverses a
move from the forward run:

```
move <TAB> <final-dest> <TAB> <original-src>
```

A `copy` op writes a comment line (`# copy - to undo, delete: <final>`) instead,
since a copy has no clean reverse. The first line is a header comment.

### 1.7 geocode forward / reverse outputs

REVERSE (`--lat` / `--lon`): `GEOCODE_PLACE=<place>, <country>` or
`GEOCODE_NONE`.

FORWARD (`--query`):
- `GEOCODE_LATLON=<lat>,<lon>`
- `GEOCODE_BBOX=<south>,<west>,<north>,<east>`
- `GEOCODE_RADIUS_KM=<km>` (centre -> NE corner)

or `GEOCODE_NONE` when nothing resolves.

---

## 2. Per-script verb / flag / output reference

### 2.1 image-index verbs

The seven verbs are `status`, `plan`, `put`, `query`, `facets`, `prune`,
`clear`. Flags are shown in `.sh` long form; the `.ps1` equivalents are
PascalCase (`-Tsv`, `-Scan`, `-Batch`, `-Query`, `-Geo`, `-Name`, `-MinBytes`,
`-TagAny`, `-Days`, `-NearDup`, `-HammingMax`, `-Followers`, `-Recurse`,
`-Top`).

| Verb | Flags | Emits |
|---|---|---|
| `status` | `--tsv` (optional scan) | `INDEX_DIR=`, `INDEX_SCHEMA=`, `INDEX_CAPTIONS=`; with `--tsv` also `INDEX_WARM=`, `INDEX_COLD=`. |
| `plan` | `--tsv` (required), `--neardup`, `--hammingmax` | `INDEX_COLD=N` + `INDEX_COLD<TAB>hash<TAB>path` rows, `INDEX_WARM=N`. With `--neardup`: also `INDEX_NEARDUP=N` + `INDEX_NEARDUP<TAB>follower-hash<TAB>path<TAB>rep-hash` rows. `INDEX_ERROR=` if no `--tsv`. |
| `put` | `--batch` (required), `--scan`, `--followers` | `INDEX_PUT=N`; optional `INDEX_PROPAGATED=N` (followers), `INDEX_REDACTED=N` (secrets masked), `INDEX_EVICTED=N` (LRU cap). `INDEX_ERROR=` if no `--batch`. |
| `query` | `--tsv` (required), `--query`, `--geo`, `--name`, `--minbytes`, `--tagany`, `--top` | `INDEX_HITS=K`, then per hit `INDEX_HIT<TAB>rank<TAB>score<TAB>hash<TAB>copies<TAB>snippet` + `INDEX_HIT_PATH<TAB>hash<TAB>path` rows; `INDEX_COLD=N` (+ `INDEX_COLD<TAB>hash<TAB>path` rows); optional `INDEX_TOUCHED=N` (LRU bump). `INDEX_ERROR=` if no `--tsv`. |
| `facets` | `--tsv` (required) | `INDEX_FACETS=N`, then per warm hash `INDEX_FACET<TAB>hash<TAB>path<TAB>category<TAB>subcategory<TAB>activity<TAB>place_path<TAB>caption`. `INDEX_ERROR=` if no `--tsv`. |
| `prune` | `--days` (default 365) | `INDEX_PRUNED=N`, `INDEX_CAPTIONS=kept`. |
| `clear` | (none) | `INDEX_CLEARED=1`. |

`INDEX_HIT` carries 6 tab fields (marker, rank, score, hash, copies, snippet).
`INDEX_FACET` carries 8 tab fields. Both `--recurse` and `--top` are accepted
by the parser; `--top` caps the hit count, `--recurse` is a pass-through flag.
Date/recency filtering lives in `image-find`, NOT in `image-index query`.

### 2.2 image-find flags

| `.sh` flag | `.ps1` flag | Meaning |
|---|---|---|
| `--count N` | `-Count` | newest N files. |
| `--minutes X` | `-Minutes` | within the last X minutes. |
| `--today` / `--yesterday` | `-Today` / `-Yesterday` | calendar-day buckets. |
| `--since` / `--until` | `-Since` / `-Until` | explicit date bounds. |
| `--within SPEC` | `-Within` | bucket: `t`/`today`, `yesterday`, `<N>h|d|w|m|y`. |
| `--name SUB` | `-Name` | filename substring filter. |
| `--dir PATH` | `-Dir` | search dir (else Screenshots auto-detect). |
| `--recurse` | `-Recurse` | descend subfolders. |
| `--hash` | `-Hash` | emit sha1 per file. |
| `--outfile F` | `-OutFile` | persist the path list. |
| `--tsvfile F` | `-TsvFile` | persist the full 7-col TSV (for build-manifest `--meta`). |
| `--hashcache F` | `-HashCache` | tier-0 sha1 cache keyed by `path<TAB>size_mtime_ctime_inode<TAB>sha1`; self-pruning, rebuilt each run. |

Outputs: `IMG_DIR=` (one per searched dir), `IMG_COUNT=`, optional `IMG_NOTE=`,
`IMG_SKIPPED=` / `IMG_SKIPPED_PATH=` (path contains tab/newline), `IMG_OUTFILE=`,
`IMG_TSVFILE=`, `IMG_HASHCACHE=`, then the TSV rows.

### 2.3 cluster

Flags: `--tsv` (required), `--gap-minutes` (default 2), `--geo-km` (default 2),
`--trip-gap-hours` (default 8). Outputs: `CLUSTER_COUNT=`, `CLUSTER` lines (see
1.4), `CLUSTER_ERROR=` on missing `--tsv`.

### 2.4 build-manifest

Flags: `--class` (file or dir of batch `*.tsv`; required), `--shots`, `--meta`,
`--base`, `--op` (move/copy), `--plugin`, `--manifest`. Outputs:
`MANIFEST_FILE=`, `MANIFEST_COUNT=`, the manifest lines (see 1.5), optional
`MANIFEST_BATCHES=` / `MANIFEST_CLASSIFY_SECONDS=`, `MANIFEST_COVERAGE=` +
`MANIFEST_UNASSIGNED<TAB>` / `MANIFEST_DUPLICATE<TAB>` rows, `MANIFEST_ERROR=`
on bad input.

### 2.5 file-ops

Flags: `--manifest` (required), `--apply`, `--restore`, `--prune`, `--plugin`,
`--journal`. Default is a dry run. Outputs: `PLAN<TAB>` (dry run) or `DONE<TAB>`
(apply/restore) rows, `SKIP_MISSING<TAB>`, `PRUNED<TAB>`, `OPS_JOURNAL=`,
`OPS_DIR<TAB>` per-dir rows, `OPS_MODE=`, `OPS_DIRS_NEW=` / `OPS_DIRS_EXISTING=`
/ `OPS_PRUNED=`, `OPS_DONE=` / `OPS_SKIP=` / `OPS_ERR=`, `OPS_BAD=` /
`OPS_BAD_OP=` / `OPS_ERROR=` on bad input.

### 2.6 thumbs

Flags: `--path` (repeatable), `--list`, `--max` (default 1600), `--plugin`,
`--out`. Outputs: `THUMB_DIR=`, `THUMB_COUNT=`, `THUMB_SECONDS=`, optional
`THUMB_NOTE=`, then `<thumb>\t<source>` lines.

### 2.7 geocode

Flags: `--lat`, `--lon` (reverse), `--query` (forward), `--base-url`. Outputs:
see 1.7 - `GEOCODE_PLACE=`, `GEOCODE_LATLON=`, `GEOCODE_BBOX=`,
`GEOCODE_RADIUS_KM=`, `GEOCODE_NONE=`, `GEOCODE_ERROR=`.

### 2.8 workspace

Actions: `new` (`--plugin`, `--skill`), `clean` (`--dir`). Outputs:
`WORKSPACE=`, `WORKSPACE_CLEANED=`, `WORKSPACE_ERROR=`.

### 2.9 prefs

Actions: `get` (`--dir`), `set` (`--dir`, `--albums`, `--op`, `--scheme`,
`--plugin`). Outputs: `PREFS_DIR=`, `PREFS_SCHEME=`, `PREFS_OP=`,
`PREFS_ALBUMS=`, `PREFS_UPDATED=` (get); `PREFS_SAVED=` (set); `PREFS_NONE=`,
`PREFS_ERROR=`.

### 2.10 journal

Actions: `list` (default), `show <name>`, `revert <name>`. Outputs:
`JOURNAL_ROOT=`, `JOURNAL_COUNT=`, the per-journal list lines, `JOURNAL_ERROR=`.
`revert` shells back into `file-ops --restore`.

---

## 3. KEY=value vocabulary

Alphabetical. Marker-prefixed tab rows (e.g. `CLUSTER`, `INDEX_HIT`, `OPS_DIR`)
are noted as tab lines.

| Key | Meaning |
|---|---|
| `CLUSTER` | tab row: one cluster (see 1.4). |
| `CLUSTER_COUNT=N` | number of clusters found. |
| `CLUSTER_ERROR=` | cluster bad input (missing `--tsv`). |
| `GEOCODE_BBOX=` | forward: `south,west,north,east`. |
| `GEOCODE_ERROR=` | geocode failure detail. |
| `GEOCODE_LATLON=` | forward: resolved `lat,lon`. |
| `GEOCODE_NONE=1` | nothing resolved. |
| `GEOCODE_PLACE=` | reverse: `<place>, <country>`. |
| `GEOCODE_RADIUS_KM=` | forward: centre-to-NE-corner km. |
| `IMG_COUNT=N` | files matched. |
| `IMG_DIR=` | a searched directory (one per dir). |
| `IMG_HASHCACHE=` | path of the rebuilt tier-0 hash cache. |
| `IMG_NOTE=` | advisory (e.g. no Screenshots folder). |
| `IMG_OUTFILE=` | path of the persisted path list. |
| `IMG_SKIPPED=` | count of files skipped (path has tab/newline). |
| `IMG_SKIPPED_PATH=` | a skipped path (`.ps1`). |
| `IMG_TSVFILE=` | path of the persisted 7-col TSV. |
| `INDEX_CAPTIONS=N` | live caption rows in the store. |
| `INDEX_CLEARED=1` | cache nuked. |
| `INDEX_COLD=N` | distinct uncaptioned hashes; also a tab row `INDEX_COLD<TAB>hash<TAB>path`. |
| `INDEX_DIR=` | store directory. |
| `INDEX_ERROR=` | verb misuse / bad input. |
| `INDEX_EVICTED=N` | rows dropped by the LRU size cap on put. |
| `INDEX_FACET` | tab row: warm-hash facets (8 fields, see 2.1). |
| `INDEX_FACETS=N` | distinct warm hashes in the facets dump. |
| `INDEX_HIT` | tab row: one ranked hit (6 fields: marker, rank, score, hash, copies, snippet). |
| `INDEX_HIT_PATH` | tab row: `INDEX_HIT_PATH<TAB>hash<TAB>path` - a live path for a hit. |
| `INDEX_HITS=K` | number of ranked hits returned. |
| `INDEX_NEARDUP=N` | near-dup followers; tab row `INDEX_NEARDUP<TAB>follower-hash<TAB>path<TAB>rep-hash`. |
| `INDEX_PROPAGATED=N` | follower rows written by put `--followers`. |
| `INDEX_PRUNED=N` | rows dropped by prune (older than cutoff). |
| `INDEX_PUT=N` | caption rows upserted. |
| `INDEX_REDACTED=N` | secret matches masked in put text. |
| `INDEX_SCHEMA=N` | current store schema version. |
| `INDEX_TOUCHED=N` | warm rows whose `last_seen` was LRU-bumped by a query. |
| `INDEX_WARM=N` | scan instances/hashes already cached. |
| `JOURNAL_COUNT=N` | journals found. |
| `JOURNAL_ERROR=` | no such journal. |
| `JOURNAL_ROOT=` | runes app-data journals root. |
| `MANIFEST_BATCHES=N` | batch `*.tsv` files concatenated from a `--class` dir. |
| `MANIFEST_CLASSIFY_SECONDS=N` | classification wall-clock span. |
| `MANIFEST_COUNT=N` | manifest lines written. |
| `MANIFEST_COVERAGE=` | `assigned X of Y; unassigned A; duplicated B`. |
| `MANIFEST_DUPLICATE` | tab row: a doubly-assigned source. |
| `MANIFEST_ERROR=` | build-manifest bad input. |
| `MANIFEST_FILE=` | manifest output path. |
| `MANIFEST_UNASSIGNED` | tab row: a shots-list source with no album. |
| `OPS_BAD=` | manifest line with no dest. |
| `OPS_BAD_OP=` | manifest line with an op other than move/copy. |
| `OPS_DIR` | tab row: per-dir summary (dir, new/existing, added, total, subs). |
| `OPS_DIRS_EXISTING=N` | dest dirs that already existed. |
| `OPS_DIRS_NEW=N` | dest dirs newly created. |
| `OPS_DONE=N` | ops applied (or planned in dry run). |
| `OPS_ERR=N` | op failures. |
| `OPS_ERROR=` | file-ops bad input. |
| `OPS_JOURNAL=` | reverse-manifest journal path. |
| `OPS_MODE=` | `apply` / `restore` / `dry-run`. |
| `OPS_PRUNED=N` | source dirs removed (left empty). |
| `OPS_SKIP=N` | sources missing at apply time. |
| `PREFS_ALBUMS=` | remembered album list. |
| `PREFS_DIR=` | folder the scheme is keyed to. |
| `PREFS_ERROR=` | prefs bad input (missing `--dir`). |
| `PREFS_NONE=1` | no remembered scheme. |
| `PREFS_OP=` | remembered op (move/copy). |
| `PREFS_SAVED=` | prefs set confirmation. |
| `PREFS_SCHEME=` | remembered scheme (default `albums`). |
| `PREFS_UPDATED=` | timestamp the scheme was last set. |
| `THUMB_COUNT=N` | thumbnails produced. |
| `THUMB_DIR=` | thumbnail output dir. |
| `THUMB_NOTE=` | advisory (no input / missing tool). |
| `THUMB_SECONDS=N` | thumbnail wall-clock span. |
| `WORKSPACE=` | minted workspace dir. |
| `WORKSPACE_CLEANED=` | removed workspace dir. |
| `WORKSPACE_ERROR=` | workspace bad input / guard tripped. |

Row markers that arrive as tab-separated lines (not `KEY=value`): `CLUSTER`,
`INDEX_COLD`, `INDEX_NEARDUP`, `INDEX_HIT`, `INDEX_HIT_PATH`, `INDEX_FACET`,
`MANIFEST_UNASSIGNED`, `MANIFEST_DUPLICATE`, `OPS_DIR`, `PLAN`, `DONE`,
`SKIP_MISSING`, `PRUNED`.
