# img - design spec

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

Status: SHIPPED. Verified platform = Windows (`.ps1`, System.Drawing). The
`.sh` backend exists and mirrors the contract but is NOT the verified path
(see section 6).

## 1. Purpose

Goal: a `/img` rune that pulls image FILES - recent screenshots by default, or
any folder via `-Dir` - and answers the user's question about them by vision:
read the text in them, compare a set, summarize them. Selection is the cheap
deterministic tier (scripts); the answer is the vision tier (skill).

Non-goals:

- Read-only. The finder LISTS files; it never moves, renames, deletes, or
  edits. Restructuring is `/img-organize`, transforms are `/img-edit`,
  dedup is `/img-dedup`, durable search is `/img-search`.
- Not the clipboard path. A single image sitting ON the clipboard is deferred
  to the `clip` rune; `/img` works over files on disk.
- No persistent index. Every run re-scans and re-visions; nothing is cached
  to durable state. (That cache is `/img-search`'s job.)
- Not OCR-of-record. Vision reads text for the answer, it is not a guaranteed
  transcript - that is `/clip-ocr` on a single image.

## 2. Scripts + data flow

Three scripts, each `.ps1` (Windows, verified) + `.sh` (macOS/Linux). Output
is the house `KEY=value` lines, then (for the finders) TSV rows.

Pipeline order: select (workspace) -> find (image-find) -> thumbnail (thumbs)
-> read (model vision) -> answer.

### image-find

Enumerates image files under the target dir(s), newest first, with a sortable
date and optional content hash. Emits:

```
IMG_DIR=<dir>            (one per searched dir)
IMG_COUNT=<n>
IMG_SKIPPED=<n> (...)    (only if any path was skipped)
IMG_SKIPPED_PATH=<path>  (.ps1 only, per skip)
IMG_OUTFILE=<f>          (if -OutFile given)
IMG_TSVFILE=<f>          (if a TSV side file was written)
<TSV rows, newest first>
```

TSV columns (TAB-separated, exactly 7, in order):

```
<date[.fff]>  <size-bytes>  <sha1-or-empty>  <path>  <lat>  <lon>  <camera>
```

`date` is `yyyy-MM-dd HH:mm:ss`, EXIF `DateTimeOriginal` when present else file
mtime, with a `.fff` sub-second suffix from EXIF `SubSecTimeOriginal` for burst
ordering. `sha1` is empty unless `-Hash`. `lat`/`lon`/`camera` are read from
EXIF in the SAME file open as the date (free) and are blank for screenshots.

`-OutFile <f>` writes just the absolute paths (one per line) for `thumbs -List`
to consume; when `-OutFile` is given WITHOUT `-TsvFile`, image-find also writes
the full TSV to a sibling `scan.tsv` in the same dir (so downstream steps -
cluster/manifest in other runes - never find it missing). `/img` itself uses
only the paths file.

### thumbs

Batch-downscales sources to small thumbnails for cheap vision reads. Emits:

```
THUMB_DIR=<dir>
THUMB_COUNT=<n>
THUMB_SECONDS=<elapsed>
<thumb>\t<source>       (one per thumbnailed image)
```

Inputs: `-Path a,b,c` (repeatable) and/or `-List <file>` (newline-separated
source paths). `-Max` caps the longest side (default 1600). Output names are
index-prefixed (`001_<basename>.png`) to keep order and avoid basename
collisions. Each thumbnail is STAMPED with a top-left index badge (`001`,
yellow on a dark box) so the model maps a thumbnail back to its source by the
visible number, not by read order. `THUMB_SECONDS` is surfaced to the user
("N thumbnails generated locally in X s, no upload").

### workspace

Mints / cleans a unique per-run temp dir under `<TEMP>/runes/<plugin>/`.

```
new  -Plugin imageverse -Skill img   ->  WORKSPACE=<dir>
clean -Dir <dir>                     ->  WORKSPACE_CLEANED=<dir>
```

`new` uses a fresh GUID (`.ps1`) / `mktemp -d` (`.sh`) so two concurrent runs
never share a dir. `clean` refuses any path not under `<TEMP>/runes` (guard
against nuking real data).

## 3. Logic / algorithm

1. Translate the user request into selection flags. Default source is the OS
   Screenshots folder; `-Dir`/`--dir` overrides. Flag translation:
   - `-Within` / `--within`: calendar bucket, 0 = current period, 1 = previous.
     `t`/`today`/`0d`, `yesterday`/`1d`, or `<N>h|d|w|m|y`. Window math is
     period-aligned (week starts Monday, month/year on the 1st).
   - `-Count N`: keep the last N after other filters.
   - `-Minutes X`: modified within the last X minutes.
   - `-Since` / `-Until`: explicit date-time bounds (any parseable form).
   - `-Name`: filename contains substring (case-insensitive).
   - `-Dir`: scan a specific folder.
   - `-Recurse`: include subfolders.
   Flags combine. THE DEFAULT: with no filter AND no `-Dir`, image-find returns
   the SINGLE most recent file (`anyFilter` false -> `Count = 1`). Note `-Dir`
   alone counts as a filter, so `-Dir <folder>` returns the whole folder, not
   just the newest.
2. Get a unique workspace (`workspace new`), inline its path literally into
   every subsequent command (tool calls do not share shell vars across turns -
   never stash the path in a flat file or reuse a fixed name like
   `runes-shots.txt`; concurrent runs would clobber).
3. Decide thumbnail vs full-res:
   - ONE or a FEW images -> Read the source files directly.
   - MANY images, or wide / hi-res ones -> `image-find ... -OutFile shots.txt`,
     then `thumbs -List shots.txt -OutDir thumbs`, then Read the thumbnails.
   Read ALL thumbnails in a SINGLE message so the reads run concurrently in one
   turn; only split if the request is rejected for too many images. Map each
   `<thumb>\t<source>` line back to cite the real path.
4. Answer the question across the images, ALWAYS citing each image's full path
   (newest first when several). Re-Read one source at full res only when tiny
   text needs it.
5. `workspace clean -Dir <run>`.
6. `IMG_COUNT=0` -> say so, list the searched `IMG_DIR` lines, suggest `-Dir`.

Workspace / concurrency rule: one workspace per run, all temp under it, keep
read-and-write in ONE shell so a path written by Bash as `/tmp/...` is not read
by PowerShell as `C:\tmp\...`.

## 4. Data contracts

- EXIF date: `DateTimeOriginal` (tag 36867) is preferred over file mtime as the
  sort key; mtime is the fallback. `SubSecTimeOriginal` (37521) normalises to 3
  digits and appends as `.fff` so a burst sorts in true capture order.
- GPS: tags 2/4 (lat/lon as degree-minute-second rationals) with 1/3 as the
  N/S, E/W ref; converted to signed decimal degrees, 6 dp. Read in the same
  file open as the date, so it is free; blank when absent (screenshots).
- Camera: EXIF `Model` (tag 272).
- Thumbnail cap: 1600px longest side, aspect preserved, NEVER upscaled
  (`scale > 1` clamps to 1). The rationale is two-sided: 1600 stays legible for
  dense screenshot text, yet sits under the 2000px/side many-image request cap
  so a batch of thumbnails can be read in one message.
- Index stamping: thumbnails carry both an index-prefixed filename
  (`001_...`) AND a rendered top-left index badge. The badge is the
  authoritative source mapping for bulk reads - the model reads the visible
  number, not the read order, which kills the off-by-one mislabel when many
  thumbnails arrive in one message.

## 5. Correctness + edge cases

- `IMG_COUNT=0`: emitted with the `IMG_DIR` lines already printed; the skill
  reports it and suggests `-Dir`. No Screenshots folder at all -> `IMG_COUNT=0`
  plus `IMG_NOTE=...`.
- Tab / newline in a path: would corrupt the TSV (field/line split) and silently
  misfile downstream. `.ps1` skips any path matching `[\t\r\n]`, emits
  `IMG_SKIPPED=<n>` plus one `IMG_SKIPPED_PATH=` per skip (newlines/tabs
  replaced with `?` in the report). `.sh` skips only TAB (`IMG_SKIPPED=<n>`,
  no per-path line) and does not handle embedded newlines (a known limit of the
  line-based `find` read - would need `-print0`).
- Wide-image full-res reads trip the 2000px/side cap; the thumbnail path is the
  default for wide screenshots for exactly this reason. Re-Read full res only
  when needed.
- `-f` format-operator trap (documented in code): the TSV row is built with
  `-join`, NOT `-f`, because the format operator drops trailing empty args
  (lat/lon/camera are empty for screenshots) and would throw "index out of
  range", silently emptying the TSV.
- thumbs degrades safely: a source that fails to load is skipped (try/catch),
  so `THUMB_COUNT` can be less than the input count.

## 6. Parity (.ps1 vs .sh)

Verified platform is Windows (`.ps1`). The `.sh` backend mirrors the flag set
and the KEY/TSV contract but is the unverified path. Real differences:

- EXIF approach: `.ps1` reads EXIF in-process via System.Drawing (GDI+) - zero
  external deps. `.sh` shells out to `exiftool` (one call per file fetches
  date + sub-second + GPS + camera together). Without `exiftool` on PATH, the
  `.sh` finder still works but every date falls back to mtime and lat/lon/camera
  are always blank.
- Thumbnailing: `.ps1` uses System.Drawing (bicubic resize + drawn badge).
  `.sh` prefers ImageMagick (`magick`/`convert`) which resizes AND draws the
  index badge; on a `sips`-only macOS box it can resize but CANNOT draw text -
  NO index stamp, so the skill must read smaller batches there to keep order
  trackable. With neither ImageMagick nor sips, thumbs emits `THUMB_COUNT=0`
  plus a "need sips or ImageMagick" note.
- Default Screenshots dirs differ by OS: `.ps1` probes `Pictures\Screenshots`,
  the three OneDrive roots, and the Explorer User-Shell-Folders registry GUID.
  `.sh` probes the macOS `screencapture location` default + `~/Desktop`, or on
  Linux `XDG_PICTURES_DIR` + `~/Pictures`.
- Skip handling: `.ps1` guards tab AND newline; `.sh` guards tab only (above).

## 7. Gotchas

- Workspace is per-run, NOT a flat file. The SKILL prose is emphatic: do NOT
  reuse a fixed temp name (e.g. `%TEMP%\runes-shots.txt`); two concurrent `/img`
  runs would clobber each other. The workspace path is a literal string for the
  run - inline it into each command, never store it in a shell var (vars do not
  persist across tool calls) or a flat side file.
- One-shell rule for temp paths. Writing with Bash (`/tmp/...`) and reading from
  PowerShell (`C:\tmp\...`) is a cross-translation foot-gun; keep find/thumbs/read
  in the same shell.
- `IFS=$'\t' read` field-folding (a bug class that has bitten this codebase
  multiple times). Any consumer that parses the `<thumb>\t<source>` or 7-column
  TSV with `IFS=$'\t' read a b c ...` will FOLD consecutive empty fields - and
  lat/lon/camera ARE routinely empty (screenshots). A trailing-empty-field read
  silently mis-binds columns. The img scripts themselves emit with explicit
  `printf '%s\t...\t%s\n'` / `-join "\t"` (correct); the risk is on the parse
  side, so any future `.sh` consumer of these rows must read the whole line and
  split, not `IFS=$'\t' read` into positional vars.
- PowerShell case-insensitive variable collisions: `.ps1` reuses `$u` for both
  the Within unit char and the Until datetime within the same scope. They do not
  overlap at runtime (Until is applied before the Within block reassigns `$u`),
  but it is a latent collision - a future edit that interleaves the two blocks
  would silently cross them.
- `-Dir` is a filter. A bare `/img` returns ONE image; `/img -Dir <folder>`
  returns the WHOLE folder (because `-Dir` flips `anyFilter` true and skips the
  default `Count = 1`). Add `-Count N` to bound a folder scan.
- The auto sibling `scan.tsv`: any `-OutFile` without `-TsvFile` also writes
  `scan.tsv` next to it. `/img` only needs the paths file, but the TSV lands
  anyway - harmless, but it is written into the per-run workspace, not a shared
  location, so cleanup removes it.

## 8. Status

SHIPPED. Verified on Windows (`.ps1` / System.Drawing). macOS/Linux (`.sh`)
ships against the same contract but needs `exiftool` for EXIF dates/GPS and
ImageMagick (or sips, no badge) for thumbnails, and is the unverified backend.
