# img-dedup - design spec

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

Status: SHIPPED. Verified platform: Windows (`image-find.ps1` + `file-ops.ps1`
are the verified backends). The `.sh` mirror exists and is behaviourally
equivalent but is not the verified path (see section 6).

img-dedup finds EXACT duplicate images in a folder and, on confirmation, removes
or archives the extra copies while keeping one of each. It owns no script of its
own - it composes two existing scripts (`image-find -Hash` to find, `file-ops`
to archive) plus a skill-driven recycle/delete step.

## 1. Goal / non-goals

Goal: given a folder, surface every set of byte-identical images, pick one copy
to keep per set, and (after a dry-run + explicit confirmation) reclaim the space
held by the redundant copies. The motivating case is a phone-photo dump where
the same shot was copied several times across imports.

Non-goals (stated as non-claims on the skill page):

- NOT near-duplicate detection. Re-encoded, resized, recompressed, cropped, or
  slightly edited versions of "the same picture" have DIFFERENT bytes, hence a
  different SHA1, hence are NOT grouped. Only bit-for-bit identical files
  collapse. Perceptual-hash (`phash`/dHash) near-dup grouping lives in the
  `image-index` arc (img-search), is computed-but-not-consumed there, and is
  deliberately out of scope here. img-dedup makes the strong, defensible claim
  (identical bytes) and refuses the soft one.
- NOT a content-aware "best copy" picker. The keep decision is a cheap
  deterministic path/date heuristic (section 3), not a quality judgement - all
  copies are byte-identical, so there is no "better" pixel-wise copy to choose.
- NOT a non-destructive query. This rune MUTATES the folder. A dry-run preview
  and an explicit per-run confirmation are mandatory before anything is removed.

## 2. Scripts and data flow

```
image-find -Hash  ->  TSV (date, size, sha1, path, lat, lon, camera)
                         |
                  group rows by the sha1 column (col 3)
                         |
            per group: pick 1 KEEP, the rest are EXTRAS
                         |
            DRY-RUN SUMMARY (sets / extras / wasted bytes)  -> confirm
                         |
        archive extras  ->  file-ops -Apply  (move, journaled, revertible)
        delete  extras  ->  skill-driven recycle bin / hard delete (no script)
```

Step 1 - find. The skill runs `image-find` with `-Hash` over the target folder
(`-Recurse` when asked):

```
powershell ... image-find.ps1 -Dir "<folder>" [-Recurse] -Hash
bash         image-find.sh   --dir "<folder>" [--recurse] --hash
```

`image-find` enumerates the image extensions (`.jpg .jpeg .png .heic .heif .gif
.bmp .tif .tiff .webp`), computes a SHA1 per file, and prints `IMG_DIR=`,
`IMG_COUNT=`, then one TSV row per file. The hash is computed only because
`-Hash` was passed; without it column 3 is empty.

Step 2 - group. The skill (not a script) groups the TSV rows by the sha1 column
(the 3rd tab field). Any hash that appears on more than one row is a duplicate
set. Singletons are ignored.

Step 3/4 - keep decision + dry run. Within each set the skill picks one row to
KEEP (section 3); the remaining rows are EXTRAS. It then prints the dry-run
summary - number of sets, total extras, wasted bytes - and asks the user to
confirm AND to choose disposal mode (recycle/delete vs archive-move).

Step 5 - apply. Only the EXTRAS are removed; the kept copy is never touched.
Disposal is one of:

- Archive (move to a folder): a `move<TAB>src<TAB>dest` manifest fed to
  `file-ops -Apply -Plugin imageverse`. This writes a durable reverse-manifest
  journal under `%LOCALAPPDATA%\runes\imageverse\journals\`, so the archive is
  revertible via `journal revert`. file-ops is collision-safe (an existing dest
  gets ` (2)`, ` (3)`, ... rather than an overwrite).
- Recycle bin (preferred delete): a soft delete to the OS trash. NO script
  performs this - `file-ops` has only `move` and `copy` ops, no delete. The
  skill drives the recycle itself (on Windows via the shell/`Microsoft.VisualBasic`
  recycle API; on macOS/Linux via the platform trash). This is the recommended
  default disposal because it is reversible by the user.
- Hard delete: last resort, unreversible, only on explicit user choice.

Step 6 - report: sets resolved, files removed/archived, space reclaimed.

## 3. Logic / algorithm

1. Group all `-Hash` TSV rows by sha1 (col 3). Keep only groups of size >= 2.
2. Per group, choose the single KEEP row by this priority (first rule that
   discriminates wins):
   a. a copy already living in an ORGANIZED path (a structured album folder,
      e.g. `2026/06. Paris/...`) is preferred over a copy sitting loose in a
      dump - the file the user already filed is the canonical one;
   b. else the SHORTEST path (fewest segments / chars) - the copy nearest the
      folder root, not buried in a nested subtree;
   c. else the OLDEST by the date column (col 1) - the original capture, not a
      later re-copy.
   The other rows in the group are EXTRAS.
3. Dry-run summary: count duplicate sets, sum the extras, sum the extra SIZES
   (col 2) for the wasted-space figure. List a few example sets, summarize the
   rest. The summary IS the preview - no mutation has happened yet.
4. Ask for confirmation and disposal mode (recycle/delete vs move-to-archive).
5. On confirmation, remove or move ONLY the extras. Hard invariants: never the
   kept copy, and never the last surviving copy of an image (the keep is always
   retained, so a set of N collapses to exactly 1, never 0).

The keep heuristic is path/date only and deliberately cheap: every copy in a set
is byte-identical, so "which copy to keep" is a question of WHERE it lives and
HOW OLD it is, never of pixel quality.

## 4. Data contracts

### `image-find -Hash` TSV (the input)

Seven tab-separated columns, one row per file, newest first:

| col | field | dedup use |
|---|---|---|
| 1 | date `yyyy-MM-dd HH:mm:ss[.fff]` (EXIF DateTimeOriginal else file mtime; sub-second appended when present) | tie-break: oldest wins (keep rule c) |
| 2 | size in bytes (`$f.Length` / `wc -c`) | wasted-space math (sum of extra sizes) |
| 3 | **sha1** (`Get-FileHash -Algorithm SHA1` / `shasum -a1`/`sha1sum`), empty without `-Hash` | **the grouping key** |
| 4 | absolute path | keep-priority (organized / shortest); the thing moved or removed |
| 5 | lat (EXIF GPS, blank for screenshots) | unused by dedup |
| 6 | lon | unused by dedup |
| 7 | camera (EXIF make/model) | unused by dedup |

The hash is the 3rd field. The size is the 2nd field and is the only number
that feeds the wasted-space total (sum of col 2 across all extras). Date is col
1 (the oldest-copy tie-break).

### file-ops manifest (the archive path)

Tab-separated `op<TAB>src<TAB>dest`, op is `move` or `copy`; blank lines and
`#` comments ignored. img-dedup emits `move` rows (one per extra) when archiving.
file-ops prints `PLAN`/`DONE` rows + an `OPS_*` summary block
(`OPS_DONE` / `OPS_SKIP` / `OPS_ERR`, `OPS_JOURNAL=<path>`).

## 5. Correctness and edge cases

- Never remove the last copy. The KEEP row is selected before any extra is
  touched and is excluded from the disposal set, so a set of N always collapses
  to exactly 1. There is no code path that empties a set.
- Dry-run is mandatory. The summary (sets / extras / wasted bytes) is shown and
  confirmed before a single file moves. For the archive path this maps onto
  file-ops' own default: omitting `-Apply`/`-Restore` makes file-ops a pure
  dry-run that prints `PLAN` lines and performs nothing.
- Prefer reversible disposal. Recycle bin (user-reversible) and archive-move
  (journal-reversible via `journal revert`) are preferred over hard delete.
  Hard delete is opt-in and final.
- Archive collisions are safe. file-ops never overwrites an existing dest; it
  appends ` (2)`, ` (3)`, so two extras archiving to the same name both survive.
- A path containing a tab or newline is dropped by `image-find` before it can
  poison the TSV (it would split a row into the wrong number of columns and
  corrupt grouping). Reported as `IMG_SKIPPED`.
- SHA1 collision risk is ignored. A SHA1 collision between two genuinely
  different images is not a practical concern for a personal photo library; the
  cost of a wrong group would be a same-hash file archived as a dup, which the
  journal makes recoverable.

## 6. Parity (.ps1 vs .sh)

The grouping, keep decision, dry-run, and disposal-mode choice all live in the
SKILL prose, so they are platform-independent by construction. The scripts only
supply the TSV and the move. Cross-platform notes:

- SHA1 over file BYTES is identical across platforms. Windows `Get-FileHash
  -Algorithm SHA1` and Unix `shasum -a1` / `sha1sum` produce the same 40-hex
  digest for the same content. So a folder's duplicate sets are computed the
  same on either backend - the load-bearing fact for cross-platform dedup.
- `.sh` requires `shasum` OR `sha1sum` on PATH for the `--hash` column; with
  neither, column 3 is silently empty and EVERY file groups under the empty
  hash - dedup would then see one giant bogus "set". The `.ps1` has no such
  dependency (GetFileHash is built in).
- `.sh` date/size differ in mechanism but not in meaning: dates come from
  `exiftool` (if present) else `stat` mtime; size from `wc -c`. The `.ps1` reads
  EXIF via System.Drawing and size via `.Length`.
- file-ops parity: `.ps1` uses `Move-Item`; `.sh` uses `mv`. Both write the
  reverse journal, both append ` (2)` on collision, both default to dry-run.
- The recycle-bin / hard-delete step has no script and is therefore whatever the
  skill issues per OS - the one place there is no shared backend to point at.

Verified platform is Windows; the `.sh` path is best-effort and gated on the
hashing tool being installed.

## 7. Gotchas

- `.sh` empty-hash fold (real failure mode). If neither `shasum` nor `sha1sum`
  is installed, `--hash` yields an empty col 3 for every file. Grouping by an
  empty key folds the entire folder into one "duplicate set" - a silent,
  dangerous mis-classification. The skill MUST verify the hash column is
  populated before trusting any group. The `.ps1` is immune (built-in hashing).
- `IFS=$'\t' read` empty-field folding (file-ops.sh). file-ops parses manifest
  rows with `while IFS=$'\t' read -r op src dest rest`. A blank intermediate
  field collapses under tab-IFS word-splitting; manifests must carry exactly
  three non-empty fields per `move` row. Trailing-tab or empty `dest` rows are
  caught (`OPS_BAD`) but a subtly mis-tabbed row can misalign src/dest.
- Case-insensitive PowerShell variable collision risk. PowerShell variable names
  are case-insensitive, so `$Hash` (the `-Hash` switch param) and any local
  `$hash` are the SAME variable. image-find.ps1 happens to use a different local
  (`$h`) for the per-file digest, sidestepping this - but any future edit that
  introduces a `$hash` local would silently clobber the switch. Keep the switch
  and per-file-digest names distinct.
- Exact-only is a feature, not a bug. Users asking "find duplicate photos" often
  mean "find similar photos". This rune answers ONLY the exact-bytes question
  and should say so in its reply, so a user does not assume re-encoded copies
  were also caught. Near-dup detection is explicitly parked.
- Recycle vs hard delete is OS-dependent and scriptless. There is no `delete` op
  in file-ops, so the skill issues the recycle/trash call itself. The behaviour
  (and reversibility) therefore varies by OS: Windows shell recycle bin vs a
  Unix trash command vs an outright `rm`. Default to the reversible recycle path
  and reserve hard delete for explicit opt-in.
- Archive is journaled, recycle is not. A move-to-archive can be undone with
  `journal revert` (file-ops wrote the reverse manifest). A recycle relies on
  the OS trash and a hard delete is unrecoverable - reflect this asymmetry when
  offering the disposal choice.

## 8. Status

SHIPPED. Composes `image-find -Hash` (find) + `file-ops -Apply` (archive) +
a skill-driven recycle/delete step. Verified platform: Windows. The `.sh`
backend is behaviourally equivalent for find + move but is gated on a SHA1 tool
(`shasum`/`sha1sum`) being installed and is not the verified path.
