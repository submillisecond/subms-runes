---
name: img-organize
description: This skill should be used when the user asks to "/img-organize", "organize my photos by year/month", "sort this folder into albums", "rename my last N screenshots by content", "delete screenshots older than X days", "archive last week's screenshots to <folder>", "tidy up my phone photo dump", or otherwise wants images in a folder restructured, renamed, archived, or deleted in place.
version: 0.1.0
---

# img-organize - restructure / rename / archive / delete images in place

The single in-place curator for an image folder. The operation is whatever the
arguments ask for:
- **structure** -> sort into `YYYY/MM` (EXIF date, file-time fallback) and/or content **albums** (decided by looking at the images).
- **rename** -> by content (what each image shows), keeping extensions.
- **archive / move** -> selected images to a destination folder.
- **delete** -> selected images.

Source is any `--dir` (a phone dump, the Screenshots folder, anywhere); for
screenshot-style requests the recent-selection flags work too. This MUTATES the
folder, so it runs as a dry run and confirms before any change.

Shared scripts at `${CLAUDE_PLUGIN_ROOT}/scripts/` (Windows
`powershell.exe ... -File "<script>.ps1"`; macOS/Linux `bash "<script>.sh"`):
`image-find` (find image files: recency/name/recurse + dates + optional hash),
`thumbs` (downscale for cheap reads), `build-manifest` (classification -> move/copy
plan), `file-ops` (perform the plan), `workspace` (per-run temp), `prefs` (remember
the per-folder scheme), `journal` (history + undo). **The rune's ONLY judgement is
the classification (which album each image is). Everything else is scripted - do
NOT hand-roll thumbnail, manifest, or move/copy loops.**

Temp + app-data are namespaced **by PLUGIN** (`imageverse`), shared across its
skills: a UNIQUE per-run workspace under `%TEMP%\runes\imageverse\<skill>-<run-id>\`
(so two terminals never collide), durable revert journals at
`%LOCALAPPDATA%\runes\imageverse\journals\`. Keep EVERY temp artifact inside the one
workspace, in ONE shell (git-bash `/tmp` = `%TEMP%`, but `C:\tmp` is a different
folder - never cross shells). Wipe `%TEMP%\runes` to clear all rune temp.

## Steps

0. **Mint the workspace** with the script (do NOT hand-roll guid/mktemp): `workspace new -Plugin imageverse -Skill img-organize` (`.sh`: `--plugin`/`--skill`) prints `WORKSPACE=<dir>`. That dir (e.g. `%TEMP%\runes\imageverse\img-organize-XXXX`) is a FIXED string for this whole run - INLINE it literally in every later command (`<workspace>\shots.txt`, `<workspace>\thumbs`, `<workspace>\cls\` (batch classification files), `<workspace>\manifest.tsv`). Do NOT stash it in an ad-hoc file like `/tmp/imgorg_run.txt`, and do NOT rely on a shell variable carrying it across tool calls (each call is a fresh shell - vars don't persist; the only durable handle is the literal path you already have). Keep ALL run files under that one workspace dir - nothing in flat `/tmp` or `%TEMP%` root. (The steps below write `$run\...` as SHORTHAND for that literal path - substitute the actual dir each time; do not type the characters `$run` into a command expecting it to expand.)
1. **Select -> list + TSV in one step**: `image-find <flags> -OutFile "$run\shots.txt" -TsvFile "$run\scan.tsv"` (`.sh`: `--outfile`/`--tsvfile`). `shots.txt` = absolute paths (for `thumbs`); `scan.tsv` = full per-file TSV `<date[.subsec]>\t<size>\t<hash>\t<path>\t<lat>\t<lon>\t<camera>` (for `build-manifest -Meta`: true EXIF capture time incl. sub-second, GPS, camera). Flags: recency (`-Count`/`-Within`/`-Since`/`-Name`), `-Dir <folder>`, `-Recurse` (include existing subfolders when RE-ORGANIZING), `-Hash` for dedup.
1b. **Choose the SCHEME** (the remembered one is a recommendation, NOT a lock-in): `prefs get -Dir "<folder>" -Plugin imageverse` returns `PREFS_SCHEME`/`PREFS_ALBUMS`/`PREFS_OP` if this folder was organized before. Scheme catalogue:
    - `content-albums` - group by what each image shows (classifier decides albums; remembered list seeds them).
    - `date` - `YYYY/MM` folders from capture time; no classification, skip thumbnails.
    - `year-content` - nested `YYYY/<album>` (year, then content album).
    - `month-content` - nested `YYYY/MM/<album>` (year/month, then content album).
    - `location-albums` - PHOTO libraries with GPS: group by trip/place. DEFAULT is the month-prefixed per-trip layout `YYYY/MM. <city>` (e.g. `2026/06. Paris`) so folders sort chronologically (see 1c).
    - `year-location` - nested `YYYY/<city>` (`2026/Paris`); POOLS all of a city's visits that year into one folder. No month prefix BY DESIGN - a pooled folder spans many months, so there is no single month to prefix; pick it only to MERGE a city's visits rather than the default per-trip chronological layout.
    - `trip` (DEFAULT location layout) - one album per detected trip, year-first with a MONTH-PREFIXED leaf so folders sort chronologically: `YYYY/MM. <city>` (e.g. `2026/06. Paris`); a holiday stays ONE album, and two trips to the same city stay separate and in order (`06. Paris`, `09. Paris`) - see 1c.
    - `activity` / `year-activity` - group by what's happening, POOLED across time (`Hiking`, `2026/Dining` gather every hike/dinner that year); opt-in, for everyday libraries. Like `year-location` these pool across months, so no month prefix - for chronological folders use the month-prefixed `trip` default (see 1c).
    - `flat-rename` - no subfolders; rename in place by content/date.
    (build-manifest handles the nested ones via a slash in the album field, e.g. `2026/05/<album>` or `2026/Paris`.)

    Decide the scheme: (a) an EXPLICIT request in the args wins ("by month", "re-derive albums", "year then content") - use it, no re-ask. (b) OTHERWISE **ALWAYS CONFIRM with an `AskUserQuestion` multiple-choice prompt** (NOT plain text) before doing any work - never silently reuse. State the remembered scheme + albums + when last used in the question text, then offer the scheme choices as options. `AskUserQuestion` caps options at 4 and AUTO-APPENDS its own "Other" (free-text) choice. So pass AT MOST 4 options and do NOT add your own "Other"/"Type something" - a 5th option throws "Invalid tool parameters". The 4 to pass (when a scheme is remembered): `Reuse <remembered>`, `Re-derive albums fresh`, `By date (YYYY/MM)`, `Date + content (YYYY/MM/<album>)`; if the user picks a date-based family and the granularity is unclear, ask a quick follow-up (`YYYY/MM` vs `YYYY/<album>` vs `YYYY/MM/<album>`). Do no work (thumbnails/classification) until answered. Whatever scheme is finally used gets saved in step 8b - so changing it sticks.
    REUSING a remembered album set: it SEEDS the albums (a starting set), it does NOT cap them. CORRECT GROUPING BEATS FOLDER-MINIMALISM: a coherent CLUSTER (roughly 3+ images of a clearly distinct subject - e.g. one project's screenshots, a holiday) that fits no existing album well SHOULD get its OWN new album. Do NOT force-fit a real cluster into a loosely-related existing album just to avoid a new folder (e.g. a distinct project's shots wrongly folded into an unrelated existing album). Reserve "nearest existing album" for 1-2 genuine one-offs, and `misc` only for true strays. In the plan, list EVERY target album marked NEW vs reused, so the user sees and confirms the new albums before the move - then step 8b saves the expanded set so they seed next time.
1c. **Location / trip albums (photos with GPS)** - the `image-find` TSV ALWAYS carries `<lat>\t<lon>\t<camera>` (columns 5-7; free from the same EXIF open as the date - blank for screenshots / no-GPS files). The `cluster` step (2b) already groups geotagged photos into trips by place + time; a cluster with a non-`-` geo column is a location cluster. NAME each such album from what's VISIBLE in the rep thumbnails (a landmark -> the place) + the date span - offline, no coords leave the machine. THEN, only if the user confirms, reverse-geocode just the cluster CENTROID (the geo lat,lon in the cluster line) for an accurate name: `geocode -Lat <c> -Lon <c>` (`.sh`: `--lat`/`--lon`) -> `GEOCODE_PLACE=City, Country` (NETWORK: sends that one centroid to OpenStreetMap Nominatim; never auto-run, never per-photo). Non-GPS clusters fall back to date or content.

    **Facet routing (trip vs city vs activity)** - the rule is TRIP > place/time > activity; do not force one global axis. The dest each cluster gets depends on context:
    - **Detect HOME first**: the densest / most-frequent GPS location across the whole library is home (zero config - just look at where the most clusters sit). Everything else is "away".
    - **Away-from-home, multi-hour/multi-day geo cluster = a TRIP** (`cluster -TripGapHours 8` already keeps a multi-day same-place trip as one cluster). Route the WHOLE trip to ONE album - do NOT subdivide a holiday by day or by activity. The DEFAULT album shape is YEAR-FIRST and MONTH-PREFIXED so trip folders sort chronologically within the year: `YYYY/MM. <city>` -> `2026/06. Paris`. Each distinct journey gets its own folder, so two Paris trips in 2026 stay separate and in date order (`06. Paris`, `09. Paris`); a multi-city trip splits by city (`2026/06. Paris`, `2026/06. Rome`). ALTERNATIVES, only on request: `year-location` `2026/Paris` (drop the month prefix to POOL all of a city's visits that year into one folder); a single `2026/<trip name>` album for one multi-city journey; a flat `Trips/` parent pooling all holidays regardless of year.
    - **Near-home or a single short session = everyday** -> route by the chosen everyday scheme (`date` YYYY/MM, `activity`, or `content-albums`).
    - **No GPS (screenshots)** -> content/date as before.
    - **Activity is OPT-IN, never the default leaf of a trip.** Use it for everyday/home libraries ("all my gym photos" -> `Hiking`, `2026/Dining`) when the user picks an activity scheme. Inside a trip, only sub-split by activity on an explicit ask ("split my Japan trip by activity" -> `Trips/2026 Japan/Temples`). Read the activity from the rep thumbnails (what's happening: hiking, dining, sightseeing, concert, sports, ...).
    - The city name comes from the visible landmark (offline) or the confirmed `geocode` centroid; `build-manifest` renders `2026/06. Paris` (or `2026/Paris` for `year-location`) from the slash in the album field.
    - **The MONTH-PREFIX principle.** The `MM.` prefix is the trip cluster's START month, so a holiday crossing a month boundary stays ONE atomic folder - never split per-photo. The prefix belongs ONLY to per-trip folders (each is one time-bounded event = one month, so they sort chronologically). POOLING schemes (`year-location`, `activity`) aggregate across many months, so they carry NO month prefix - prefixing would fragment the pool and defeat it. A deeper `YYYY/MM/<city>` SUBFOLDER level is a separate, rarely-needed option (sparse extra depth); the prefix already gives chronological ordering with no extra nesting.
2. **Thumbnail** (skip only for pure date/count structuring that reads no content): `thumbs -List "$run\shots.txt" -OutDir "$run\thumbs"` (`.sh`: `--list`/`--out`). 1600px longest side - legible for dense screenshot text yet under the 2000px many-image cap. Thumbnails are INDEX-STAMPED (`001`, `002`, ... top-left). Emits `THUMB_COUNT`, `THUMB_SECONDS`, then `<thumb>\t<source>` lines. Tell the user e.g. "generated 100 thumbnails locally in 2.3s" (`THUMB_SECONDS`) - local, no upload.
2b. **Cluster by time + geo FIRST** (the grouping prior that makes classification both faster and more accurate - geo/time are first-class signals, not a separate mode): `cluster -Tsv "$run\scan.tsv"` (`.sh`: `--tsv`) groups images into sessions/trips by time gaps (`-GapMinutes`, default 2 - a screenshot >2 min later is usually a different task; geotagged photos instead use `-TripGapHours`, default 8, so a trip survives within-day gaps) + GPS proximity (`-GeoKm`, default 2). Output: `CLUSTER_COUNT=N` then one line per cluster: `CLUSTER\t<id>\t<count>\t<start..end>\t<geo lat,lon|->\treps=<i,j,k>\t<index-ranges>`. `reps` = the stamped thumbnail indices to READ (first/middle/last by time); the ranges = ALL the cluster's members (1-based shots indices). A run of screenshots minutes apart (one app session) or photos at one place/time (a trip) becomes ONE cluster. (If clusters come out mostly singletons - a genuinely shuffled folder - they give little; fall back to per-image classification, step 3 alt.)
2c. **OPTIONAL - reuse cached facets to skip re-vision (warm folders).** If this folder was indexed before (by `/img-search` or a prior organize), the shared cache already knows what many images show. Run `image-index facets -Tsv "$run\scan.tsv"` (`.sh`: `facets --tsv ..`) -> `INDEX_FACETS=N` then `INDEX_FACET <hash> <path> <category> <subcategory> <activity> <place_path> <caption>` per WARM image (cache keyed by the `-Hash` content hash from step 1). For a cluster whose members are ALL warm AND AGREE on category/place, assign its album straight from those cached facets and do NOT read its thumbnails. Only vision the COLD clusters (members not in `facets`) and any warm cluster whose cached facets DISAGREE (then fall to step 3's homogeneity guard). This makes a re-organize of an already-indexed library near-zero vision. Cold-only: if `INDEX_FACETS=0`, skip this and classify normally.
3. **Classify per CLUSTER, not per image** - the speed + accuracy win. For each cluster STILL NEEDING vision (cold, or warm-but-disagreeing per 2c), read its `reps` stamped thumbnails (`$run\thumbs\<idx>_*.png`, ~3 per cluster) and assign ONE album to the whole cluster, fusing GEO (the cluster's place), TIME (its date span), and CONTENT (what the reps show). Read reps for MANY clusters in ONE message (parallelism is within a message; fewer messages = faster). Map each rep by its STAMPED index, not read order. You read ~3-per-cluster instead of every image - e.g. 437 images in 25 clusters = ~75 reads, not 437.
    VERIFY HOMOGENEITY (the accuracy guard): if a cluster's reps DISAGREE (you crossed app/topic mid-session), read a few more of its members; if it is genuinely mixed, SPLIT it - assign sub-ranges of its members to different albums, or fall back to reading that cluster's members individually. A bad cluster must never silently misfile a whole group. For GEO clusters, name the album from the visible landmark + date span (step 1c), optionally `geocode` the centroid on user confirm.
    Step 3 ALT (no useful clusters - mostly singletons, e.g. screenshots spanning months): classify per-image. Read the stamped thumbnails in as few messages as possible (all in one if they fit), map by stamped index, and STILL write each message's results to `$run\cls\batchNN.tsv` (per-file `<album><TAB><filename>` lines) - so coverage + timing work the same.
    CLASSIFY BY WHAT THE SCREEN *IS*, not a loose theme - this is where albums go wrong:
    - An org chart / about-page / internal tool of a NAMED company -> that company's album (the company name as the album), NEVER a personal album like `cv`.
    - `career` is the umbrella for job-hunting: your CV/resume, job applications, interview prep/exercises, offers, garden-leave/contract clauses. Use `career`, not `cv` (a CV is just one artifact in it).
    - A social/news/research post (a LinkedIn article, a paper) -> `misc` or a `research` album by subject, not whatever the poster's job is.
    - Don't let one album become a catch-all for adjacent-but-different content. If a few thumbnails share a vague theme but are different KINDS of thing, give them their proper albums (or `misc`) rather than forcing a single bucket.
4. **Write the classification GROUPED by cluster** to `$run\cls\batchNN.tsv` (Write tool; ZERO-PADDED names `batch01.tsv`, `batch02.tsv`, ... so they sort; one file per classification message). One line per cluster: `<album><TAB><index-ranges>` - copy the ranges VERBATIM from the cluster output. The grouped/index form is SAFE here because the indices are SCRIPT-computed cluster memberships, not eyeballed (the off-by-one risk only applies when YOU count indices). If you split a cluster, write one line per sub-album with its sub-ranges. The album may be a NESTED path for a `yyyy/mm/album` schema.
    PERSIST AS YOU GO - one batch file per message; never hold assignments only in your head. The `cls\` dir on disk is the source of truth, NOT memory: a context COMPACTION can wipe what you "remember", so never report "all N done" from recollection - trust the files + the step-6 coverage check. After a compaction, recover from the existing `cls\*.tsv` + the cluster output (re-cluster is deterministic). Do NOT hand-roll a `cat` to merge - build-manifest reads the whole `cls\` dir (step 5).
5. **Build the manifest** - `build-manifest -Class "$run\cls" -Shots "$run\shots.txt" -Meta "$run\scan.tsv" -Manifest "$run\manifest.tsv" [-Op copy]` (`.sh`: `--class`/`--shots`/`--meta`/`--manifest`). `-Class` is the `cls\` DIR - build-manifest concatenates every `batch*.tsv` in name order itself (no `cat` step). It resolves filenames/index-ranges to full paths; names each dest `<album>/<album>-<YYYY-MM-DD>-<HHMMSS>.ext` using the EXIF capture time from `-Meta` (sub-second for bursts -> `…-HHMMSS-fff.ext`; photos with no date-in-name get their real EXIF date, not mtime). Same-second-no-subsec dupes still get `-2`; nested dirs for nested albums. Emits `MANIFEST_COVERAGE=assigned X of Y; unassigned N; duplicated M` + `MANIFEST_UNASSIGNED`/`MANIFEST_DUPLICATE` rows. For delete, classify into an `archive` album (move); never hard-delete without an explicit ask.
6. **Coverage is the SOURCE OF TRUTH (esp. after a compaction), then dry-run + confirm** - `MANIFEST_COVERAGE=assigned X of Y` is the authoritative completeness check; never declare the run complete from memory. If `MANIFEST_UNASSIGNED` (images in no album) or `MANIFEST_DUPLICATE` (assigned twice) is non-zero, STOP: re-classify the listed unassigned images (re-read just those stamped thumbnails from `$run\thumbs`), write a fresh `$run\cls\batchNN.tsv` for them, and rebuild - repeat until `unassigned 0, duplicated 0`. Only then `file-ops -Manifest "$run\manifest.tsv"` (no `-Apply`) prints `PLAN` + `OPS_*`. Show a SUMMARY (per-album counts, a few example `old -> new`) and ask for confirmation. Include a ⏱ TIMINGS line: thumbnails in `THUMB_SECONDS`s (from step 2), and "classified N in `MANIFEST_BATCHES` batches over `MANIFEST_CLASSIFY_SECONDS`s" (from build-manifest).
7. **Apply** - `file-ops -Manifest "$run\manifest.tsv" -Apply -Plugin imageverse` (`.sh`: `--apply`/`--plugin`). `-Apply` = the FORWARD migration. Collision-safe; creates dest folders; auto-writes a durable journal to `%LOCALAPPDATA%\runes\imageverse\journals\` and prints `OPS_JOURNAL=<path>`. It also emits per-album `OPS_DIR\t<dir>\t<new|existing>\t<added>\t<total>\t<subfolders>` lines and an `OPS_DIRS_NEW=.. OPS_DIRS_EXISTING=..` summary.
8. **Report** from the `OPS_DIR` lines: distinguish **New folders** vs **Existing folders** (don't call a pre-existing album new), and show files-added + total-now per album. End with the undo line: "to undo: `journal revert <journal-name>`" (the friendly verb, not raw file-ops).
8b. **Remember the scheme actually used**: `prefs set -Dir "<folder>" -Scheme <content-albums|date|date-albums|flat-rename> -Albums "<comma-separated albums, if any>" -Op <op> -Plugin imageverse`. This OVERWRITES the prior pref for this folder, so if the user changed the scheme this run, the new one becomes the recommended default next time. (Skip on a revert-only run.)
8c. **OPTIONAL (opt-in, OFF by default) - warm the shared search cache.** You already vision-read the rep thumbnails to classify, so those observations can be written into the global `image-index` cache for free, leaving `/img-search` warm. Best-effort and OPT-IN - do it ONLY when the user asks (e.g. "also index these") or a stored pref says so; do NOT add a turn or latency to the core organize flow by default. When doing it: ensure the scan carried `-Hash` (step 1's dedup hash - the cache is keyed by content hash), then write one 11-column row per classified image to `$run\put.tsv` and call `image-index put -Batch "$run\put.tsv" -Scan "$run\scan.tsv"` (columns: `<hash>\t<path>\t<category>\t<subcategory>\t<activity>\t<place_path>\t<entities>\t<objects>\t<attributes>\t<caption>\t<text>`, the same format `/img-search` uses; leave fields empty where not applicable but keep all 11 tabs). It is purely additive: writes are idempotent (last-write-wins per hash), so re-warming is always safe.
9. **Clean up** - `workspace clean -Dir "$run"` (`.sh`: `--dir`) whether you finished or aborted (it is guarded to only delete under `%TEMP%\runes`). Do NOT delete the journal (it lives in app-data, outside `$run`). Orphaned run dirs under `%TEMP%\runes\imageverse\` from crashed runs are always safe to delete (or wipe `%TEMP%\runes` entirely).

## History & revert

Every apply leaves a durable journal, so past runs can be listed and undone:
- **List** the run history: `journal list` (`.sh`) - shows `[plugin] <name> <when> <N moves> -> <albums>` newest-first across all plugins.
- **Inspect** one: `journal show <name>`.
- **Revert (undo)** a specific run: `journal revert <name>` - runs `file-ops -Restore` on that journal: reverses the moves AND prunes any album folder it leaves EMPTY (a folder with other content is kept). The restore is itself journaled, so it can be **redone** with `journal revert <restore-journal-name>`.

`-Apply` (forward) vs `-Restore` (undo, prunes emptied dirs) are the two file-ops
modes; `journal revert` always uses `-Restore`. NEVER hand-roll an empty-folder
cleanup loop - `-Restore` does it, guarded to truly-empty dirs only.

When the user says "undo my last organize" / "show my organize history", drive `journal`.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img-organize` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📷` `📁` `📦` `📊` `📝` `📌` `🔖` `🔍` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the plan/result.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place. Use `🚩` to flag anything that needs the user's attention before they confirm.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - per-bucket counts, per-album examples, multi-part heads-up notes. Don't flatten everything to one level; the indent is what separates a breakdown from the top-line summary.

EVERY reply from this rune leads with the cast banner, INCLUDING the dry-run
plan and any interim status - not just the final result. After the banner, line 1
is `📁 ` + the folder; line 2 is the heading: the dry-run preview uses
`🔍 **Plan:**`, the applied result uses `📁 **Organized:**`. Summarize buckets -
never print thousands of lines.

```
ᚱ imageverse › /img-organize v0.1.0
📁 `C:\Users\you\Pictures\PhoneDump`
🔍 **Plan:**
- 📌 **What:** sort 1,204 images into `YYYY/MM` by EXIF date (move, not copy).
- 📊 **Buckets:**
  - 2024/03 -> 412
  - 2024/04 -> 380
  - 2025/01 -> 412
- 🚩 **Heads-up:** 18 files have no EXIF; falling back to file time.
- ⏱ **Timings:** thumbnailed in 7.6s; classified 1,204 in 25 batches over 18m.

Confirm to proceed?
```

## Notes

- MUTATES the folder. Dry-run + explicit confirmation are required for any move / rename / delete. `--copy` preserves originals when structuring.
- EXIF-first dates, file-time fallback (HEIC without readable EXIF uses file time). Non-image files are ignored. Never overwrite.
- Standard for any content classification: `thumbs` first, then read thumbnails in PARALLEL BATCHES (10-16 Read calls per message), then `file-ops`. Do not read images one-at-a-time or hand-roll move/copy loops. Large libraries: summarize buckets, work in batches, report progress.
