# img-organize - design spec

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

Status: SHIPPED. Verified platform is Windows (the `.ps1` backend). The
`.sh` mirror exists for every script and is parity-intended, with the gaps
called out in section 8. The geo / trip / activity facet schemes and the
month-prefixed per-trip naming were added recently (the timeseries-of-this-pack
build order step 8 in img-search/SPEC.md section 15); they are live in the
skill prose and in `build-manifest` + `cluster` + `geocode`.

This skill is the most complex one in the imageverse pack: it is the only one
that MUTATES the target folder, it runs an 8-script pipeline, and its single
unit of model judgement (the album decision) is wrapped in a deterministic
coverage check that is the source of truth for completeness.

## 1. Goal / non-goals

Goal: an in-place CURATOR for an image folder. The operation is whatever the
arguments ask for, over the same pipeline:

- structure -> sort into `YYYY/MM` (EXIF date, file-time fallback) and/or
  content / location / activity albums (decided by looking at the images).
- rename -> by content, keeping the extension.
- archive / move -> selected images to a destination album.
- delete -> via an `archive` album move; never a hard delete without an
  explicit ask.

Because every one of these MUTATES the folder, the skill ALWAYS runs as a dry
run first (the manifest IS the preview) and requires explicit confirmation
before any move / rename / delete. `--copy` preserves originals when
structuring.

Non-goals:

- Not a search tool. Finding the image that matches a query is `/img-search`.
- Not a viewer. Answering questions about recent images is `/img`.
- Not a deduper. Exact-duplicate removal is `/img-dedup` (though `image-find
  -Hash` is shared plumbing).
- Not a generative editor. Pixel edits are `/img-edit`.
- Not a global content index. img-organize visions clusters fresh each run; it
  does NOT (yet) read from or write to the `image-index` caption cache - that
  shared-cache hook is the PLANNED build-order-5 item (img-search/SPEC.md
  sections 10, 16.5). Today the two runes share the vocab and the
  `build-manifest` pipeline, not the cache.

The model's ONLY judgement is the classification - which album each cluster /
image belongs to. Everything else (thumbnailing, clustering, manifest naming,
move/copy, journaling, prefs) is scripted. The skill never hand-rolls a
thumbnail loop, a `cat batch*.tsv`, a manifest line, a move/copy loop, or an
empty-folder cleanup.

## 2. Scripts and data flow

Eight scripts, each with a `.ps1` (Windows, verified) and a `.sh`
(macOS/Linux) backend. The pipeline, with what each step emits and how it
feeds the next:

```
workspace new            -> WORKSPACE=<run dir>   (unique per run)
        |
image-find <flags>       -> shots.txt  (abs paths, one per line; for thumbs)
   -OutFile shots.txt       scan.tsv   (full per-file TSV; for cluster + build-manifest -Meta)
   -TsvFile scan.tsv     -> IMG_DIR / IMG_COUNT / TSV lines
        |
prefs get -Dir <folder>  -> PREFS_SCHEME / PREFS_ALBUMS / PREFS_OP  (recommendation, not a lock)
        |
cluster -Tsv scan.tsv    -> CLUSTER_COUNT=N
                            CLUSTER <id> <count> <span> <geo|-> reps=<i,j,k> <index-ranges>
        |
thumbs -List shots.txt   -> THUMB_DIR / THUMB_COUNT / THUMB_SECONDS
   -OutDir thumbs/           <thumb>\t<source> lines  (index-stamped 001,002,...)
        |
[ MODEL JUDGEMENT ]      -> read each cluster's reps thumbnails, assign ONE album
   Write cls/batchNN.tsv    each line: <album>\t<index-ranges>  (grouped, verbatim from cluster)
        |
[ geocode -Lat -Lon ]    -> GEOCODE_PLACE=City, Country   (opt-in, network, centroid only)
        |
build-manifest           -> MANIFEST_FILE / MANIFEST_COUNT
   -Class cls/              MANIFEST_COVERAGE=assigned X of Y; unassigned N; duplicated M
   -Shots shots.txt         MANIFEST_UNASSIGNED / MANIFEST_DUPLICATE rows
   -Meta scan.tsv           MANIFEST_BATCHES / MANIFEST_CLASSIFY_SECONDS
   -Manifest manifest.tsv   manifest lines: <op>\t<src>\t<dest>
        |
file-ops -Manifest       (dry run) -> PLAN rows + OPS_* summary
   (no -Apply)
        |
[ CONFIRM ]
        |
file-ops -Manifest -Apply -> DONE rows, OPS_JOURNAL=<path>, OPS_DIR lines,
                             OPS_DIRS_NEW / OPS_DIRS_EXISTING
        |
prefs set -Scheme ... -Albums ...   (remember the scheme actually used)
workspace clean -Dir <run dir>
```

Out-of-band (history / undo): `journal list | show | revert <name>`, where
revert drives `file-ops -Restore` over the saved reverse manifest.

Step roles:

- `workspace` - mints a unique per-run temp dir under `%TEMP%\runes\imageverse\`
  so two terminals never collide; cleans it (guarded to that root).
- `image-find` - enumerates image files by predicate; emits the paths list +
  the full EXIF/GPS/camera TSV in one open.
- `prefs` - per-folder memory of the last scheme + album set (a recommendation).
- `cluster` - the cheap metadata-only grouping prior (time + geo); turns N
  images into far fewer clusters so the model reads ~3 reps per cluster.
- `thumbs` - downscales + index-stamps for cheap, order-safe vision.
- `build-manifest` - resolves classification -> deterministic dest names +
  the coverage check.
- `file-ops` - performs the plan, writes the journal, reports per-dir deltas.
- `journal` - lists / shows / reverts past runs.
- `geocode` - reverse-geocodes a cluster centroid into a place name (opt-in).

## 3. Scheme catalogue

The remembered scheme (from `prefs`) is a RECOMMENDATION, not a lock-in. An
explicit request in the args wins with no re-ask ("by month", "year then
content"); otherwise the skill ALWAYS confirms via an `AskUserQuestion`
multiple-choice before doing any work. `build-manifest` renders every nested
scheme purely from a slash in the album field - the schemes are conventions
over what string the model writes into `cls/batchNN.tsv`, not script flags.

Documented exactly as the skill supports them:

| scheme | album shape | notes |
|---|---|---|
| `content-albums` | `<album>` | group by what each image shows; classifier decides albums, remembered list seeds them. |
| `date` | `YYYY/MM` | from capture time; NO classification, SKIP thumbnails. |
| `year-content` | `YYYY/<album>` | year, then content album. |
| `month-content` | `YYYY/MM/<album>` | year/month, then content album. |
| `location-albums` | default `YYYY/MM. <city>` | photo libraries with GPS; default IS the month-prefixed per-trip layout. |
| `year-location` | `YYYY/<city>` | POOLS all of a city's visits that year into one folder; NO month prefix by design (a pool spans many months). |
| `trip` (DEFAULT location) | `YYYY/MM. <city>` | one album per detected trip, year-first + month-prefixed so trips sort chronologically. |
| `activity` / `year-activity` | `Dining`, `2026/Hiking` | group by what is happening, POOLED across time; opt-in, everyday libraries; NO month prefix (pools across months). |
| `flat-rename` | `<no subfolder>` | rename in place by content/date. |

### The MONTH-PREFIX rule (trips)

A trip folder is `YYYY/MM. <city>` (e.g. `2026/06. Paris`). The `MM.` prefix
is the trip cluster's START month. Consequences:

- A holiday crossing a month boundary stays ONE atomic folder, named by its
  start month - never split per-photo / per-day.
- Two trips to the same city in the same year stay separate and in order:
  `06. Paris`, `09. Paris`.
- A multi-city trip splits by city, each year-first month-prefixed:
  `2026/06. Paris`, `2026/06. Rome`.
- The prefix belongs ONLY to per-trip folders (each is one time-bounded event =
  one month, so they sort chronologically without extra nesting). POOLING
  schemes (`year-location`, `activity`) aggregate across many months, so they
  carry NO month prefix - prefixing would fragment the pool and defeat it.
- A deeper `YYYY/MM/<city>` subfolder level is a separate, rarely-needed
  option; the prefix already gives chronological ordering with no extra depth.

### Facet routing (trip > place/time > activity)

The rule is TRIP > place/time > activity; the skill does not force one global
axis. Per cluster:

- Detect HOME FIRST: the densest / most-frequent GPS location across the whole
  library is home (zero config). Everything else is "away".
- Away-from-home, multi-hour / multi-day geo cluster = a TRIP. (`cluster
  -TripGapHours 8` already keeps a multi-day same-place trip as ONE cluster.)
  Route the WHOLE trip to ONE album, year-first month-prefixed by default. Do
  NOT subdivide a holiday by day or by activity.
- Near-home or a single short session = everyday -> route by the chosen
  everyday scheme (`date`, `activity`, or `content-albums`).
- No GPS (screenshots) -> content / date as before.
- Activity is OPT-IN, never the default leaf of a trip. Use it for
  everyday/home libraries when the user picks an activity scheme. Inside a
  trip, sub-split by activity only on an explicit ask ("split my Japan trip by
  activity" -> `2026/06. Japan/Temples`).

The city name comes from the visible landmark in the rep thumbnails (offline)
or the confirmed `geocode` centroid; `build-manifest` renders `2026/06. Paris`
(or `2026/Paris` for `year-location`) from the slash in the album field.

ALTERNATIVES offered only on request: `year-location` (`2026/Paris`, drop the
prefix to pool a city's visits); a single `2026/<trip name>` album for one
multi-city journey; a flat `Trips/` parent pooling all holidays regardless of
year.

## 4. Data contracts

### scan.tsv (image-find -TsvFile) and shots.txt (-OutFile)

`shots.txt` is one absolute path per line, newest first, 1-based index. It is
the index space for everything downstream (cluster ranges, classification
ranges, coverage).

`scan.tsv` is the full per-file TSV, SAME row order as shots.txt:

```
<date[.subsec]> \t <size> \t <sha1-or-empty> \t <path> \t <lat> \t <lon> \t <camera>
```

- `date` is `yyyy-MM-dd HH:mm:ss`, EXIF `DateTimeOriginal` preferred, file
  mtime fallback. EXIF `SubSecTimeOriginal` is appended as `.fff` (3 digits,
  fraction-aligned) when present, for burst ordering.
- `lat`/`lon` are signed decimal degrees (6 dp), from the same EXIF open;
  blank for screenshots / no-GPS files. `camera` is EXIF make/model.
- The TSV is built with `-join "\t"`, NOT the `-f` format operator, because
  `-f` drops trailing null/empty args (lat/lon/cam empty for screenshots) and
  would empty the file (build-manifest.ps1 comment, image-find.ps1 line 186).
- If `-OutFile` is given without `-TsvFile`, image-find auto-writes
  `scan.tsv` alongside it, so `cluster` never finds the TSV missing.
- Paths containing a tab/newline are SKIPPED + warned (`IMG_SKIPPED`), because
  they would corrupt the TSV field/line splitting and break a later revert.

### cluster output

```
CLUSTER_COUNT=N
CLUSTER \t <id> \t <count> \t <start..end> \t <geo lat,lon | -> \t reps=<i,j,k> \t <index-ranges>
```

- Ordered NEWEST cluster first.
- `reps` = the 1-based shots indices to READ - first / middle / last by time
  (deduped). ~3 per cluster.
- `<index-ranges>` = ALL members, run-length-compressed (`1-16,19,22-26`),
  1-based into shots order. These are copied VERBATIM into the classification.
- `<geo>` is the mean lat,lon (3 dp) of the cluster's geotagged members, or
  `-` for no-GPS clusters. A non-`-` geo column marks a location cluster.

### classification TSV (cls/batchNN.tsv)

Written by the model (Write tool), one ZERO-PADDED file per classification
message (`batch01.tsv`, `batch02.tsv`, ...) so they sort. Grouped form, one
line per cluster:

```
<album> \t <index-ranges>
```

The ranges are copied verbatim from the cluster output. The grouped/index form
is SAFE here precisely because the indices are SCRIPT-computed cluster
memberships, not eyeballed - the off-by-one risk only applies when the model
counts indices itself. If a cluster is split, the model writes one line per
sub-album with its sub-ranges. The album may be a NESTED path
(`2026/05/<album>`) for the nested schemes. Blank lines and `#` comments are
ignored. (The per-image alt form `<album>\t<filename>` is also accepted - used
when clusters are useless singletons.)

### build-manifest manifest format and dest naming

Manifest line: `<op> \t <src> \t <dest>` (op = move | copy).

Dest path = `<Base>/<albumPath>/<name>`, where `Base` defaults to the parent
folder of the first source, `albumPath` is the album with separators
normalised (so a nested album becomes real subdirs).

Dest file name:

```
<leaf>-YYYY-MM-DD-HHMMSS[.subsec][-N].ext
```

- `<leaf>` is the LAST segment of the album path, with the `MM. ` month
  prefix STRIPPED from the FILE stem (`06. Paris` folder -> `Paris-...` file).
  The strip regex is `^(0[1-9]|1[0-2])\.\s+`; the FOLDER keeps the prefix. The
  date in the name already orders files, so the file does not need the prefix.
- Timestamp source priority: EXIF (`-Meta`, incl. sub-second) > a
  `YYYY-MM-DD-HHMMSS`-style date in the filename > file mtime > `undated` /
  `000000`. So photos with no date-in-name get their REAL EXIF date, not mtime.
- Sub-second (when present) is appended (`...-HHMMSS-fff`) so bursts get
  unique, true-ordered names.
- Same-second, no-subsec collisions get a `-2`, `-3` counter (`$seen` map keyed
  by `albumPath|stem`). file-ops adds a SECOND collision guard at write time
  (` (2)`, ` (3)`) against pre-existing dest files.

build-manifest also emits `MANIFEST_BATCHES=<n>` +
`MANIFEST_CLASSIFY_SECONDS=<s>` when `-Class` is a directory: the classify
wall-clock is measured from the NEWEST thumbnail's mtime (vision phase start)
to now, not from a batch-write span (which is ~0 when the model reads
everything then dumps the batches at the end).

### journal (the reverse manifest)

Written by file-ops on every `-Apply` / `-Restore` to a DURABLE, per-plugin
app-data dir (NOT the temp workspace):
`%LOCALAPPDATA%\runes\imageverse\journals\<apply|restore>-<yyyyMMdd-HHmmss>-<pid>.tsv`
(`.sh`: `$XDG_DATA_HOME` or `~/.local/share`, or `~/Library/Application
Support` on macOS).

Each forward `move <src> <dest>` is recorded REVERSED as `move <dest> <src>`,
so replaying the journal undoes the run. A `copy` records a comment line `#
copy - to undo, delete: <dest>` (a copy has no clean reverse - nothing is
moved). The journal has a header comment with the redo hint.

### prefs storage

Per-plugin tab-separated table at
`%LOCALAPPDATA%\runes\<plugin>\prefs.tsv`, keyed by the normalised folder path
(absolute, no trailing slash, lowercased). Row:

```
<key> \t <Dir> \t <Scheme> \t <Op> \t <Albums> \t <updated-iso>
```

`set` is last-write-wins for the key (drops the old row, appends the new).
`get` prints `PREFS_DIR / PREFS_SCHEME / PREFS_OP / PREFS_ALBUMS /
PREFS_UPDATED`, or `PREFS_NONE=1`. The script default `-Plugin` is
`imageverse` (both backends); the skill still passes `-Plugin imageverse`
explicitly so the read/write target is unambiguous.

## 5. Correctness and coverage

`MANIFEST_COVERAGE=assigned X of Y; unassigned N; duplicated M` is the
AUTHORITATIVE completeness check, and the source of truth especially after a
context compaction. The skill must never declare a run complete from memory.

How it is computed (build-manifest, both backends): the script counts how many
times each source path appears across the expanded `(album, src)` pairs.

- `unassigned` = shots-list entries that appear in NO pair (`MANIFEST_UNASSIGNED`
  rows list them).
- `duplicated` = sources assigned more than once (`MANIFEST_DUPLICATE` rows).

If either is non-zero, STOP: re-classify the listed unassigned images (re-read
just those stamped thumbnails), write a fresh `cls/batchNN.tsv`, and rebuild -
repeat until `unassigned 0, duplicated 0`. Only then run the dry-run + confirm.

Two more accuracy guards:

- Cluster HOMOGENEITY guard (the model's job at classify time): if a cluster's
  reps DISAGREE, read a few more members; if it is genuinely mixed, SPLIT it
  (assign sub-ranges to different albums, or fall back to per-member reads). A
  bad cluster must never silently misfile a whole group.
- EXIF-first dates with mtime fallback at every layer: image-find reads EXIF
  `DateTimeOriginal` (mtime fallback), and build-manifest re-derives the dest
  date EXIF-first via `-Meta`. HEIC without readable EXIF falls back to file
  time.

The `cls/` dir on disk is the source of truth, not the model's memory. After a
compaction, recover from the existing `cls/*.tsv` plus the cluster output
(re-clustering is deterministic).

## 6. Revert / undo

Every `-Apply` leaves a durable journal, so any past run can be listed and
undone via the `journal` script (the friendly verb the skill surfaces; never
hand-roll raw file-ops for undo):

- `journal list` - all journals across all plugins, newest first, as
  `[plugin] <name> <when> <N moves> -> <albums>`. Albums are the leaf folder
  names parsed from the `move` lines.
- `journal show <name>` - prints a journal's contents. `<name>` matches the
  file name (with or without `.tsv`) or a full path.
- `journal revert <name>` - runs `file-ops -Restore` over that journal:
  - reverses the moves (the journal IS the reverse manifest);
  - PRUNES any source folder the run leaves EMPTY (a folder with other content
    is kept) - `-Restore` implies prune, guarded to truly-empty dirs only;
  - writes its OWN journal, so the restore can itself be REDONE
    (`journal revert <restore-journal-name>`).

`-Apply` (forward, no prune unless `-Prune`) vs `-Restore` (undo, prunes
emptied source dirs) are the two file-ops run modes; `journal revert` always
uses `-Restore`. file-ops is collision-safe in both directions (never
overwrites; appends ` (2)`).

`-Apply -Prune` is the separate case for RE-ORGANIZING into a new scheme: the
forward run vacates the old album folders, and `-Prune` removes those emptied
source dirs.

## 7. Geo / trip

The geo path is metadata-first and offline by default; the one network call is
opt-in and per-centroid.

- `image-find` always carries `lat/lon/camera` (columns 5-7), free from the
  same EXIF open as the date; blank for screenshots.
- `cluster` groups by TIME and GEO together. Two regimes per adjacent pair:
  - GPS regime (both points geotagged): PLACE dominates. A Haversine jump
    `> -GeoKm` (default 2 km) starts a new cluster; otherwise a same-place time
    gap `> -TripGapHours` (default 8 h) splits it (so a multi-day same-place
    trip survives within-day gaps as ONE cluster).
  - No-GPS regime (screenshots): a tight session gap `> -GapMinutes`
    (default 2 min) starts a new cluster.
  Undated rows sort to the end and break into their own clusters.
- The model names a location album from the VISIBLE landmark in the rep
  thumbnails + the date span, OFFLINE - no coordinates leave the machine.
- ONLY if the user confirms, reverse-geocode the cluster CENTROID (the geo
  lat,lon in the cluster line): `geocode -Lat <c> -Lon <c>` ->
  `GEOCODE_PLACE=City, Country`. This is a NETWORK call to OpenStreetMap
  Nominatim (`zoom=12` city granularity, `<=1 req/s`, a real User-Agent), never
  auto-run, never per-photo. `geocode -Query` is the inverse (place -> coords +
  bbox + radius), used by `/img-search`, not by organise.
- Routing: trip vs everyday is the section-3 facet routing - year-first,
  month-prefixed naming for trips; pooling / content / date for everyday.

## 8. Parity (.ps1 vs .sh)

Verified platform is WINDOWS - the `.ps1` backend is the one that has been
run. The `.sh` mirrors exist for all eight scripts and are written to match,
but treat them as parity-intended-not-verified. Honest gaps:

- `image-find.sh` depends on `exiftool` for ALL EXIF (date, sub-second, GPS,
  camera) and on `gawk`/GNU or BSD `date` for the calendar math. Without
  `exiftool` it degrades to mtime-only dates and BLANK GPS - so the geo/trip
  schemes silently lose their signal on a box with no exiftool. The `.ps1`
  uses System.Drawing (GDI+) and always has EXIF on Windows.
- `cluster.sh` needs `gawk` (for `mktime`) for the time math; plain `awk` may
  lack it. `cluster.ps1` is self-contained.
- `thumbs.sh` needs ImageMagick (`magick`/`convert`) for the index stamp; the
  `sips`-only macOS fallback resizes but CANNOT draw the index badge, so the
  off-by-one-protection is absent there (read smaller batches). `thumbs.ps1`
  always stamps via System.Drawing.
- `geocode.sh` needs `curl` and parses Nominatim JSON with grep/sed (no jq);
  `geocode.ps1` uses `Invoke-RestMethod`. Both send only the centroid /
  the place name.

build-manifest.sh specifically: it recently had TWO bugs fixed and the current
state is CORRECT (verified by reading the source):

- Pass-1 index expansion (line 97) uses `printf '%s\n' "$val"` WITH the
  trailing newline. Without it, the final `read` in the `while` loop would get
  the value but return EOF-false, so a single-index `"1"` would expand to
  NOTHING. The comment at lines 95-96 documents the fix. Current state: fixed.
- Pass-2 dest naming (lines 136-145) splits each row with per-field `cut`
  (`cut -f1`, `-f2`, ..., `-f5-`), NOT `IFS=$'\t' read`. Because `subsec` is
  often EMPTY and tab is IFS-whitespace, an `IFS=$'\t' read` would FOLD the
  empty subsec field and shift `src` into `subsec` (the path ends up in the
  name and `src` goes blank). `cut` keeps empty fields; `-f5-` captures src
  including any embedded tabs. The comment at lines 138-140 documents this.
  Current state: fixed.

  Note pass-1's own loop header (line 90) DOES use `IFS=$'\t' read -r album val
  rest`, but that is safe: `album` and `val` are the FIRST two fields and
  non-empty there, and `rest` mops up the remainder, so no empty-field fold
  shifts data.

## 9. Gotchas

- The `IFS=$'\t' read` empty-field-fold bug CLASS has bitten this pack three
  times: `image-index.sh put`, `build-manifest.sh` pass-1, and
  `build-manifest.sh` pass-2. Root cause: tab is IFS-whitespace, so an EMPTY
  trailing/middle field is folded away and later fields shift left. The fix is
  always either per-field `cut` (keeps empty fields) or guaranteeing the field
  is non-empty / not last. Any new `.sh` that reads a TSV with optional columns
  must use `cut`, not `IFS=$'\t' read`.
- Case-insensitive PowerShell variable collisions: PS variables are
  case-INSENSITIVE, so `$R` and `$r` are the SAME variable. cluster.ps1's
  Haversine carries an explicit warning comment (line 44) - using `$R` (earth
  radius) and `$r` (a record) together would silently clobber. Watch this in
  any new `.ps1` math.
- Workspace-per-run, NOT a flat temp file: each run mints a UNIQUE dir via
  `workspace new` (guid / mktemp). The dir is a FIXED literal string for the
  whole run - inline it into every command. Do NOT stash it in an ad-hoc
  `/tmp/imgorg_run.txt`, and do NOT rely on a shell variable carrying it across
  tool calls (each tool call is a fresh shell; vars do not persist - the only
  durable handle is the literal path). Keep ALL run files under that one dir;
  nothing in flat `/tmp` or `%TEMP%` root.
- Cross-shell temp path mismatch: git-bash `/tmp` maps to `%TEMP%`, but
  `C:\tmp` is a DIFFERENT folder. Never cross shells mid-run (a `.ps1` step
  writing to `%TEMP%\runes\...` and a `.sh` step reading `/tmp/runes/...` can
  land in different real dirs). Pick one backend for the whole run.
- AskUserQuestion caps options at 4 and AUTO-APPENDS its own "Other"
  free-text choice. Pass AT MOST 4 options and do NOT add your own
  "Other"/"Type something" - a 5th option throws "Invalid tool parameters".
  The 4 to pass when a scheme is remembered: `Reuse <remembered>`, `Re-derive
  albums fresh`, `By date (YYYY/MM)`, `Date + content (YYYY/MM/<album>)`.
- Reusing a remembered album set SEEDS the albums, it does not CAP them.
  Correct grouping beats folder-minimalism: a coherent cluster (~3+ images of a
  clearly distinct subject) that fits no existing album well SHOULD get its own
  NEW album. Reserve "nearest existing album" for 1-2 genuine one-offs, `misc`
  for true strays. Mark every target album NEW vs reused in the plan.
- `cluster.ps1`'s doc-comment header says `-GapMinutes` default 45, but the
  actual param default is 2 (matching the `.sh` and the skill prose). The
  header comment now also reads 2.
- prefs `-Plugin` default is `imageverse` in both backends; the skill still
  passes `-Plugin imageverse` explicitly so get/set hit the same store.

## 10. Status

SHIPPED. Verified platform: Windows (`.ps1`). The `.sh` mirror is present for
all eight scripts and parity-intended, with the dependency gaps in section 8.

Recently added (build-order step 8 in img-search/SPEC.md):

- the geo / trip / activity FACET schemes (`location-albums`, `year-location`,
  `trip`, `activity`/`year-activity`) and the facet routing prose
  (trip > place/time > activity, home detection, pooling-vs-per-trip);
- the MONTH-PREFIXED per-trip naming (`2026/06. Paris`) in `build-manifest`,
  including the prefix-strip on the file stem (both backends);
- `cluster -TripGapHours` (the GPS same-place trip-survival gap);
- `geocode -Query` forward mode (shared with `/img-search`).

PLANNED, not built (img-search/SPEC.md sections 10, 16.5): the shared
`image-index` caption cache hook - img-organize reading facets from / writing
facets back to the global cache so re-organising an already-indexed folder
approaches zero vision. Today img-organize visions clusters fresh each run.
