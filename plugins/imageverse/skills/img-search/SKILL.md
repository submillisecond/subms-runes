---
name: img-search
description: This skill should be used when the user asks to "/img-search", "find the screenshot with X", "which photo shows Y", "search my images for Z", "find photos near <place>", "all photos near Paris in 2026", "find receipts in <folder>", or otherwise wants to SEARCH a folder of images by CONTENT (what they show) and/or METADATA (date, place, size). It reuses a cached, content-addressed index so repeated searches don't re-read pixels. For a single image on the clipboard use /clip-ocr; to ASK questions about a few recent screenshots use /img.
version: 0.2.0
---

# img-search - find images by content + metadata, with a reusable index

Search a folder (recursively) for the image(s) matching a request that spans
CONTENT ("the error dialog", "receipts", "temple photos") and METADATA (date,
place, size). The first pass over a folder vision-captions each distinct image
ONCE into a global, content-addressed cache; every later search reads that
cached text instead of re-reading pixels, so repeats are near-zero token. The
cache survives moves/renames/copies (keyed by file content) and is shared with
`/img-organize`.

Shared scripts at `${CLAUDE_PLUGIN_ROOT}/scripts/` (Windows
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<script>.ps1"`;
macOS/Linux `bash "<script>.sh"`): `image-find` (enumerate + EXIF/GPS/hash),
`image-index` (the search cache: `status`/`plan`/`query`/`put`), `thumbs`
(downscale for cheap reads), `geocode` (place name <-> coordinates, for "near
<place>"), `workspace` (per-run temp). **The rune's ONLY
vision work is captioning the COLD delta and (optionally) confirming the top
hits - everything else is scripted. Do NOT hand-roll enumeration, hashing,
ranking, or the cache.**

## How the cost model works (read this once)

The only expensive thing is vision. Cheap, scripted tiers run first and shrink
what vision ever sees:

- METADATA queries (date / place / size / name) are answered with no vision at
  all - `image-find` + `image-index query`'s geo/size filters.
- CONTENT queries run BM25 recall over the cached captions (no vision) and only
  vision-read images that are not yet captioned (the COLD delta), once.
- A warm folder (already indexed) answers a content search with zero vision, or
  a handful of reads if the user asks to confirm the top hits.

So: caption the cold delta once, then search forever.

## Steps

0. **Mint a workspace** (do NOT hand-roll guid/mktemp): `workspace new -Plugin imageverse -Skill img-search` (`.sh`: `--plugin`/`--skill`) prints `WORKSPACE=<dir>`. That dir is a FIXED string for this run - INLINE it literally in every later command (the steps write `$run` as shorthand; substitute the real path, never type `$run`). Keep all run files under it.

1. **Parse the request into two groups of flags:**
   - DATE / RECENCY / NAME / FOLDER -> `image-find` flags (it owns these): `-Dir <folder>` - a literal path OR the KEYWORD `screenshots` / `downloads` (resolved to the OS folders, incl. the Windows drive under WSL); omit = `screenshots`. `-Recurse` (search subfolders - usually yes for a library search, so organised album subfolders are included), `-Within`/`-Since`/`-Until` (e.g. "in 2026" -> `-Since 2026-01-01 -Until 2026-12-31`), `-Name <sub>`.
   - SEMANTIC text + GEO / SIZE / TAGS -> `image-index query` flags: `-Query "<what the image shows>"` (the content words: "error dialog", "temple lantern"), `-Geo "<lat>,<lon>,<km>"` (see geo resolution below), `-MinBytes <n>`, `-TagAny <a,b>` (filter to images whose category/subcategory/activity/place match a tag), `-Top <K>` (default 12).
   - GEO RESOLUTION for "near <place>": resolve the place with `geocode -Query "<place>"` (`.sh`: `--query`) -> `GEOCODE_LATLON=<lat>,<lon>` + a suggested `GEOCODE_RADIUS_KM`; pass them as `-Geo "<lat>,<lon>,<km>"`. This is a NETWORK call (OpenStreetMap Nominatim) that sends only the place NAME (never user coordinates) - opt-in, so confirm with the user before the lookup. A broad administrative match (a whole prefecture/state, sometimes with offshore territory) can return a very large radius; sanity-check `GEOCODE_RADIUS_KM` and tighten the km (e.g. 25-50 for a city) if the user clearly means the city, not the region.
   A request can be pure-metadata ("photos near Paris in 2026"), pure-content ("the error dialog"), or both.

2. **Scan the folder (cheap, no vision):** `image-find <date/name/dir flags> -Recurse -Hash -OutFile "$run\shots.txt"` (`.sh`: `--recurse --hash --outfile`). `-Hash` is REQUIRED - it populates the sha1 the index joins on; it auto-writes the sibling `scan.tsv` (the full `date\tsize\thash\tpath\tlat\tlon\tcamera` TSV). If `IMG_COUNT=0`, say so, list the searched `IMG_DIR`, suggest `-Dir`, and stop.
   - OPTIONAL for VERY LARGE libraries (10k+ files): add `-HashCache "<index-dir>\hashcache.tsv"` (`.sh`: `--hashcache`) so unchanged files are not re-read to rehash on every search (`<index-dir>` is the `INDEX_DIR` from `image-index status`). Skip it for normal folders - real-hashing is already cheap there.

3. **Query the index (cheap, no vision):** `image-index query -Tsv "$run\scan.tsv" -Query "<semantic words>" [-Geo .. -MinBytes .. -TagAny ..] -Top 12` (`.sh`: `query --tsv .. --query ..`). Read the output:
   - `INDEX_HITS=N`, then per hit `INDEX_HIT  <rank>  <score>  <hash>  <copies>  <snippet>` followed by its `INDEX_HIT_PATH  <hash>  <path>` lines (one per copy - exact duplicates are grouped under one hit).
   - `INDEX_COLD=M` + `INDEX_COLD  <hash>  <path>` lines = images that passed the filters but are not yet captioned (only emitted for a `-Query`/content search).

4. **Caption the COLD delta (the only vision step), then re-query** - do this when `INDEX_COLD > 0` AND the request is semantic (a pure-metadata query needs no captions; its hits are already complete):
   - **Collapse near-duplicates first (saves vision reads).** Instead of thumbnailing the raw cold list, run `image-index plan -Tsv "$run\scan.tsv" -NearDup` (`.sh`: `plan --tsv .. --neardup`). It opens each cold file locally for a perceptual hash and emits two groups: `INDEX_COLD  <hash>  <path>` = the REPS to vision (one per distinct look), and `INDEX_NEARDUP  <follower-hash>  <follower-path>  <rep-hash>` = near-identical images (a burst, a re-screenshot, a resize) that will INHERIT their rep's caption and are NEVER vision-read. Write the rep paths (col 3 of each `INDEX_COLD`) one-per-line to `$run\cold.txt`, and the `INDEX_NEARDUP` lines (3 cols, tab-separated) to `$run\fol.tsv`.
   - `thumbs -List "$run\cold.txt" -OutDir "$run\thumbs"` (`.sh`: `--list`/`--out`) on the REPS only. It prints `THUMB_COUNT`, `THUMB_SECONDS`, then index-STAMPED `<thumb>\t<source>` lines.
   - Read the stamped thumbnails in ONE message (concurrent), mapping each by its STAMPED index (not read order). For EACH rep, extract a structured record (schema below) and write one tab-separated row to `$run\put.tsv`:
     `<hash>\t<path>\t<category>\t<subcategory>\t<activity>\t<place_path>\t<entities>\t<objects>\t<attributes>\t<caption>\t<text>`
     - `<hash>` and `<path>` are copied from the matching `INDEX_COLD` rep line (map thumbnail -> source path -> its rep hash).
     - The final `<text>` is ALL legible on-screen text, flattened to ONE line (no tabs/newlines). Lists (`entities`/`objects`/`attributes`) are comma-separated. Leave a field empty if not applicable, but keep the tabs (every row has 11 columns).
   - **OPTIONAL (opt-in, OFF by default) - reverse-geocode `place_path` from GPS.** Cold images that carry GPS (non-empty lat/lon in `scan.tsv`) can have their `place_path` column filled from coordinates so "in <city>" searches match. This is a NETWORK call to OpenStreetMap Nominatim - CONFIRM with the user first; never run it per-photo blindly. When confirmed: BATCH by location - round each photo's lat/lon to ~2-3 decimals, reverse-geocode each DISTINCT rounded location ONCE via `geocode -Lat <lat> -Lon <lon>` (`.sh`: `--lat`/`--lon`) -> `GEOCODE_PLACE=City, Country` at <=1 req/s, then reuse that result for every photo at that location (avoids N calls, respects Nominatim policy). Put the resulting place into the `place_path` column of each such photo's put row (`City, Country` is a fine value; a `Country/Region/City` string also fits). Screenshots / no-GPS images keep an empty `place_path`. GPS-derived place naming is opt-in and off by default.
   - `image-index put -Batch "$run\put.tsv" -Followers "$run\fol.tsv" -Scan "$run\scan.tsv"` (`.sh`: `put --batch .. --followers .. --scan ..`). The `-Scan` join fills lat/lon/camera; the script computes dims + perceptual hash and REDACTS any secrets in `<text>` (reports `INDEX_REDACTED=N`). `-Followers` propagates each rep's COARSE fields (category/subcategory/objects/place_path/caption, NOT text) to its near-dups, marking them `source=propagated:<rep>` (reports `INDEX_PROPAGATED=N`). Omit `-Followers` if `fol.tsv` is empty.
   - Re-run step 3's query. The newly-captioned images now rank; `INDEX_COLD` should be 0 (or smaller). Tell the user how many reps were "indexed locally this run", how many near-dups inherited a caption (no vision), and the `THUMB_SECONDS` (local, no upload).

5. **Optional precision pass** - if the user wants high precision, or recall looks thin (few/low-score hits), thumbnail the top-K hit paths and Read them to confirm/re-rank before reporting. Skip for a confident warm search.

6. **Report** the hits HASH-GROUPED, newest/most-relevant first, ALWAYS citing each image's FULL PATH(s). For a hit with multiple copies, show the count and list the paths. Note warm vs cold (e.g. "312 images, 304 warm, 8 indexed this run"). Then `workspace clean -Dir "$run"` (`.sh`: `--dir`).

## Extraction schema (what to record per cold image)

Recall is only as good as what you capture in the one look, so extract broadly.
Soft controlled vocab (pick the nearest; the index is `.schema`-versioned):

- `category`: screenshot | photo | document | diagram | chart | code | ui | map | receipt | chat | social | meme | art | other.
- `subcategory`: `<category>-<qualifier>`, e.g. `screenshot-terminal-error`, `photo-outdoor-beach`, `document-invoice`, `chart-timeseries`.
- `activity` (mainly photos): what is happening - hiking, dining, sightseeing, concert, sports, travel, work, home, ... (empty for most screenshots).
- `place_path`: `Country/Region/City` if known from the image (a visible landmark/sign) - else empty. For GPS-bearing cold images this can be filled by the opt-in reverse-geocode sub-step in step 4 (off by default).
- `entities`: named things - app/site names, error types, brands, people, place names.
- `objects`: salient unique things in the frame.
- `attributes`: theme/colors/mood (dark theme, warm tones, ...).
- `caption`: one-line summary.
- `text`: ALL legible on-screen text, one line. The biggest recall driver for screenshots.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and
identical across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img-search` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version, e.g. `v0.1.0`, NEVER omit it). The folder path line follows it.
- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a narrow variation-selector glyph that eats its space. Use the vetted full-width set: `🔍` `📁` `📷` `📊` `📌` `📄` `🔖` `🚩`.
- The folder path lives ALONE on its line, in backticks.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the result.
- **Nest copies as INDENTED sub-bullets** (2-space indent) under their hit.

Line 1 after the banner is `📁 ` + the searched folder. Line 2 is the heading
`🔍 **Search:**` + the query in quotes. Then `📌 What`, then one `📷` bullet per
hit (most relevant first) with its path(s) and a short reason, then a `📊` cost
line. Cite FULL paths. Summarize when there are many hits.

```
ᚱ imageverse › /img-search v0.1.0
📁 `C:\Users\you\Pictures\Screenshots`
🔍 **Search:** "error dialog"
- 📌 **What:** 2 matches across 312 images (304 warm, 8 indexed this run).
- 📷 **NullReferenceException dialog** - `...\Screenshot 2026-06-19 144210.png` (2 copies)
  - `C:\Users\you\Pictures\Screenshots\Screenshot 2026-06-19 144210.png`
  - `C:\Users\you\Pictures\Archive\err.png`
- 📷 **"Failed to connect" toast** - `...\Screenshot 2026-06-11 091533.png`
- 📊 **Cost:** 8 thumbnails read locally in 0.6s; 304 served from cache, 0 re-read.

Want me to look closer at any of these?
```

## Notes

- The index is GLOBAL and content-addressed under `%LOCALAPPDATA%\runes\imageverse\index\` (`.sh`: `$XDG_DATA_HOME/...`), owner-only. Deleting/moving files never produces stale hits - presence is decided by the live `image-find` scan each run, never by the index. `image-index status -Tsv "$run\scan.tsv"` reports warm/cold coverage for a folder before a big search.
- DATE filtering is `image-find`'s job (upstream); `image-index query` handles geo/size/name/tags + content recall. Recall is bounded by what was captured - an out-of-schema ask ("where the chart line is red") may need a deeper look; offer to re-caption.
- **"find photos of <person>"**: if the query names a REGISTERED person (`settings person list`), fetch their refs with `settings person refs -Name <X>` (emits `SETTINGS_REF<TAB>person<TAB>path`), thumbnail them, and use that labelled reference sheet as CONTEXT when reading candidate thumbnails to confirm the person is present. Recognition is reference-images-as-context (no ML), so this needs a precision pass (step 5) over candidates, not just caption recall. If the person isn't registered, offer to register them via `/img-settings` first.
- Windows is the verified backend; macOS/Linux via the `.sh` mirror (needs `exiftool` for EXIF/GPS, ImageMagick for thumbnails + perceptual hash). Reads only; never moves or modifies the searched files.
