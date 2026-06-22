# img-save - design spec

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

Status: SHIPPED. Verified platform: Windows (`.ps1` backend). The `.sh` mirror
exists and is parity-shaped but is NOT the verified backend.

## 1. Goal / non-goals

Goal: a `/img-save` rune that COPIES a selection of image files to a single
destination folder, for sharing or a bug report, leaving the originals exactly
where they are. Default selection is recent screenshots (the `image-find`
no-filter default); any `--dir` plus the full `image-find` filter set is
available. Destination is either an explicit path in the arguments or the runes
outbox.

Non-goals:

- NOT a move/reorganize. It never mutates the source folder - no move, no
  rename, no delete of originals. (Moving in place is `/img-organize`; that rune
  drives the SAME `file-ops` engine with `move` ops instead of `copy`.)
- NOT a transform. It copies bytes verbatim, preserving the source filename. No
  resize/redact/convert (that is `/img-edit`).
- NOT a dedup or selection engine. It copies exactly the list `image-find`
  returns; it does not collapse exact copies or near-dups.
- NOT a transcript or index step. No vision, no caption cache touched.

The honest shape: this is a thin copy front-end. The interesting logic
(collision-safe naming, journaling, dir-state reporting) lives in the shared
`file-ops` script, which `img-save` shares verbatim with `img-organize` and
`img-dedup`.

## 2. Scripts + data flow

Two scripts do the work; a third (`workspace`) is the conventional temp host for
the manifest, and `journal` is the out-of-band undo surface.

| Script | Role | Emits |
|---|---|---|
| `image-find` (`.ps1`/`.sh`) | Select the images to copy (same flags as `/img`). | `IMG_DIR=`, `IMG_COUNT=`, one TSV line per file, optional `IMG_OUTFILE=`/`IMG_TSVFILE=`. |
| `file-ops` (`.ps1`/`.sh`) | Apply a `copy` manifest to the destination, collision-safe, with a journal. | `PLAN`/`DONE`/`SKIP_MISSING` rows, `OPS_DIR`/`OPS_JOURNAL=`/`OPS_MODE=`/`OPS_DONE=` summary. |
| `workspace` (`.ps1`/`.sh`) | Mint/clean the per-run temp dir that holds the manifest + scan. | `WORKSPACE=`, `WORKSPACE_CLEANED=`. |
| `journal` (`.ps1`/`.sh`) | List/show/revert past `file-ops` runs (cross-rune undo). | `JOURNAL_ROOT=`, `JOURNAL_COUNT=`, per-journal lines. |

Pipeline (canonical, file-ops-driven):

1. `image-find <selection flags>` -> the chosen image paths (TSV; column 4 is
   the absolute path). With no filter and no `-Dir` it returns the SINGLE most
   recent image - the skill is told to confirm that is intended before saving
   just one.
2. Resolve the destination folder (section 3).
3. Build a `file-ops` manifest: one `copy<TAB><src><TAB><dest>` line per selected
   path, where `<dest>` is `<destination-folder>\<original-filename>`.
4. `file-ops -Manifest <m> -Apply -Plugin imageverse` copies each file, makes the
   destination dir, resolves collisions, and writes a durable journal.
5. Report the absolute destination, file count, and total size.

Note on the SKILL.md prose: the shipped `SKILL.md` describes step 3 as a direct
`Copy-Item` / `cp` loop ("Copy each listed path... preserving filenames"). That
is the simple inline path. The `file-ops` header explicitly names `img-save` as
one of its clients ("the img-organize / img-save / img-dedup runes build a PLAN
... and apply it here instead of hand-rolling Move/Copy loops"), so the
collision-safe + journaled engine documented here is the intended substrate.
The two agree on the result; `file-ops` adds no-overwrite renaming and revert.

## 3. Logic / algorithm

### Selection-flag translation

`/img-save` passes the user's selection straight through to `image-find` - the
flag surface is identical to `/img` (`-Count`, `-Minutes`, `-Today`,
`-Yesterday`, `-Since`, `-Until`, `-Within`, `-Name`, `-Dir`, `-Recurse`). The
defining default: with NO filter and no `-Dir`, `image-find` sets `Count = 1`
and returns only the newest image (`$anyFilter` false -> `$Count = 1`). The
skill is instructed to confirm before saving a single file, because a bare
`/img-save <folder>` would otherwise copy just one.

### Destination resolution

1. An explicit path/folder in the arguments WINS: relative resolves against cwd,
   absolute is taken as-is.
2. Otherwise the runes outbox: `$RUNES_SAVE_DIR` if set, else
   `%USERPROFILE%\Downloads\runes\imageverse-<stamp>` (Windows) /
   `~/Downloads/runes/imageverse-<stamp>` (macOS/Linux).
3. Create the dir if missing. (`file-ops` also `mkdir -p`s each dest dir itself,
   so the directory is guaranteed before the first copy regardless.)

### Copy vs move

Always `copy`. The manifest op word is `copy`; `file-ops` runs `Copy-Item`
(`.ps1`) / `cp` (`.sh`). Source is never touched. This is the structural
difference from `/img-organize`, which emits `move` ops over the same engine.

### Collision-safe naming

`file-ops` never overwrites. For a target `dest`, it splits stem + extension and,
while the target exists, appends ` (2)`, ` (3)`, ... until a free name is found:

```
final = dest; k = 2
while exists(final): final = <dir>/<stem> (k)<ext>; k++
```

So copying `shot.png` into a folder that already holds `shot.png` writes
`shot (2).png`. The check is per-target and pre-flight (it tests the live
filesystem, not the in-run manifest), so two manifest lines that both target
`shot.png` are resolved sequentially: the first writes `shot.png`, the second
sees it and becomes `shot (2).png`.

## 4. Data contracts

### `file-ops` manifest (input)

Tab-separated, one op per line; blank lines and `#` comments ignored:

```
copy<TAB><abs-src><TAB><abs-dest>
move<TAB><abs-src><TAB><abs-dest>
```

`img-save` emits only `copy` lines. `<dest>` is the full target PATH (folder +
final filename), not just the folder - `file-ops` derives the dest dir via
`Split-Path -Parent` / `dirname`. A line with fewer than 3 fields is reported
`OPS_BAD=`; an op word other than `move`/`copy` is `OPS_BAD_OP=`.

### `file-ops` per-op output

| Line | Meaning |
|---|---|
| `PLAN<TAB>op<TAB>src<TAB>final` | dry run (no `-Apply`): what WOULD happen, incl. the collision-resolved `final`. |
| `DONE<TAB>op<TAB>src<TAB>final` | applied: file copied to `final`. |
| `SKIP_MISSING<TAB>src` | source path absent; skipped, counted in `OPS_SKIP`. |
| `OPS_ERR<TAB>src<TAB>msg` | the copy threw (`.ps1` only catches per-op; `.sh` increments `errs`). |
| `OPS_DIR<TAB>dir<TAB>new\|existing<TAB>added<TAB>total<TAB>subs` | per-dest-dir rollup: was the dir new, files added this run, total files now, subfolder count. |

### Journal (revert log)

Written by `-Apply` (and `-Restore`) when at least one op succeeded. Location is
DURABLE per-plugin app-data, never the temp workspace:

- Windows: `%LOCALAPPDATA%\runes\<plugin>\journals\apply-<yyyyMMdd-HHmmss>-<PID>.tsv`
  (falls back to `%APPDATA%`, then `%XDG_DATA_HOME%`, then `~/.local/share`).
- macOS: `~/Library/Application Support/runes/<plugin>/journals/...`.
- Linux: `${XDG_DATA_HOME:-$HOME/.local/share}/runes/<plugin>/journals/...`.

`<plugin>` is `imageverse` (passed as `-Plugin imageverse`); the default is
`misc` if omitted. The journal is the REVERSE manifest. For a `move` it stores
`move<TAB><dest><TAB><src>` (a real reverse op). For a `copy` it stores a COMMENT
line only:

```
# copy - to undo, delete: <final>
```

Because a copy left the original in place, there is nothing to move back - undo
means deleting the copy, which the journal documents but does NOT execute. The
emitted key is `OPS_JOURNAL=<path>`.

### KEY=value summary outputs

- `image-find`: `IMG_DIR=`, `IMG_COUNT=`, `IMG_OUTFILE=`, `IMG_TSVFILE=`,
  `IMG_SKIPPED=` (path with tab/newline).
- `file-ops`: `OPS_JOURNAL=`, `OPS_MODE=apply|restore|dry-run`,
  `OPS_DIRS_NEW=N OPS_DIRS_EXISTING=N OPS_PRUNED=N`,
  `OPS_DONE=N OPS_SKIP=N OPS_ERR=N`.

## 5. Correctness + edge cases

- Destination creation: `file-ops` runs `New-Item -Force` / `mkdir -p` on each
  dest dir before the first copy, so the folder always exists; the skill's own
  pre-create is belt-and-suspenders.
- No overwrite: enforced by the ` (k)` rename loop. An existing file in the dest
  is never clobbered.
- Missing source: a manifest src that no longer exists is `SKIP_MISSING`, counted
  in `OPS_SKIP`, never fatal. The run continues.
- Empty selection: if `image-find` returns `IMG_COUNT=0`, the skill has nothing
  to copy. (A zero-line manifest run yields `OPS_DONE=0`, writes no journal -
  the journal is gated on `done > 0`.)
- Source folder is NEVER mutated. `-Prune` (which removes emptied SOURCE dirs) is
  only meaningful for `move` runs; an all-`copy` run leaves every source dir
  non-empty, so even an accidental `-Prune` removes nothing.
- Undo: `copy` ops are not auto-revertible - the journal records the copies as
  comments and `journal revert` re-applies only the `move` lines (there are
  none). To undo a save, delete the destination folder. This is a deliberate
  asymmetry: a copy is non-destructive, so its "undo" is a user delete, recorded
  but never executed for you.
- Path safety: `image-find` skips and warns on any path containing a tab or
  newline (`IMG_SKIPPED`) so the TSV / manifest field-splitting can never be
  poisoned. Impossible on NTFS; defensive for cross-platform.

## 6. Parity (.ps1 vs .sh)

Verified platform is Windows; the `.ps1` backend is authoritative. Behavioural
notes on the `.sh` mirror:

- Copy + collision logic match: both split stem/ext and append ` (k)`; both
  `mkdir -p` the dest; both copy verbatim (`Copy-Item` / `cp`).
- Journal location differs by OS by design (app-data root resolution), but the
  reverse-manifest FORMAT is identical, including the `# copy - to undo, delete:`
  comment line.
- `image-find.sh` reads EXIF/GPS via `exiftool` if present and degrades to mtime
  otherwise; `image-find.ps1` uses System.Drawing (GDI+). For `img-save` this is
  immaterial - it consumes only column 4 (the path) and the recency sort, both
  of which work without EXIF.
- `journal.sh` list uses `find -printf '%T@'` (GNU find) for the newest-first
  sort, with a non-`-printf` fallback for BSD/macOS find. The `.ps1` sorts by
  `LastWriteTime` natively. Cosmetic difference in ordering robustness only.

## 7. Gotchas

Real issues found in the source (documented, NOT changed):

- `file-ops.sh` reads the manifest with `while IFS=$'\t' read -r op src dest
  rest`. A `copy<TAB>src<TAB>dest` line with a TRAILING tab, or any field that is
  itself empty, folds under `IFS=$'\t'` field-splitting and lands columns in the
  wrong variables. This empty-field-folding class has bitten this codebase
  repeatedly (build-manifest.sh pass-2 among them); for `img-save` the risk is
  low because dest paths are non-empty and tab-free (image-find already filters
  tabs), but a hand-built manifest with a stray trailing tab would mis-parse. The
  `.ps1` `-split "\`t"` is positional and does not fold, so the two backends can
  disagree on a malformed line.
- Cross-shell temp path: the manifest/scan workspace lives under
  `%TEMP%\runes\imageverse\...` on Windows (`workspace.ps1`) but
  `${TMPDIR:-/tmp}/runes/imageverse/...` on Unix (`workspace.sh`). A path minted
  by one shell is not where the other shell looks - never hand a Windows
  `C:\...\Temp\runes` path to the `.sh` backend or a `/tmp/runes` path to the
  `.ps1` one. The journal root has the same split (`%LOCALAPPDATA%` vs
  `~/.local/share` / `~/Library/Application Support`).
- PowerShell variable case-insensitivity: a future edit to `file-ops.ps1` that
  introduces a second variable differing only in case from an existing one (e.g.
  `$dest` vs `$Dest`) silently aliases to the same slot. None present today, but
  the named bug class to watch when extending the `.ps1` backend.
- The collision check is filesystem-live, not manifest-aware: it tests
  `Test-Path final` against disk. Correct for normal use, but if two runs apply
  overlapping manifests concurrently into the same dest, the ` (k)` numbering can
  race (both probe `shot.png` free, both try to write it). Single-run use is the
  contract; concurrency is not.
- `OPS_JOURNAL` for an all-`copy` run lists only comment lines, so `journal
  revert` on an `img-save` journal performs ZERO moves (`moves.Count = 0`) - it
  is effectively a no-op that prints the reverse-manifest header and prunes
  nothing. This is correct (a copy has nothing to move back) but can read as a
  failed undo if the operator expects files to disappear.

## 8. Status

SHIPPED. Verified platform: Windows (`.ps1`). The copy engine (`file-ops`), the
finder (`image-find`), the temp host (`workspace`), and the undo surface
(`journal`) are all in place and shared with `/img-organize` and `/img-dedup`.
The `.sh` backend mirrors the behaviour but is not the verified path; treat the
`IFS=$'\t'` field-folding and the temp/journal path split as the live
cross-platform caveats.
