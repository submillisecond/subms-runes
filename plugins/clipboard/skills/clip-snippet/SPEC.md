# clip-snippet SPEC

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

A named, curated library of reusable clipboard snippets - license headers, config templates, command recipes, canned replies, a logo or signature image - recallable onto the clipboard on demand.

- Goal: save a payload (text or image) under a human name and put it back on the clipboard later, unchanged.
- Goal: a stable, owner-only store that does not expire and has no count cap - it changes only when the user saves or deletes.
- Non-goal: an automatic chronological log. That is `/clip-history`; this is a deliberate, named library. There is no enable flag - it is always available.
- Non-goal: a secret vault. Text snippets that hold credentials are refused, not stored.

## Scripts + data flow

- `scripts/clip-snippet.ps1` / `.sh` - the library backend. Verbs `save`, `get`, `list`, `search`, `rm`, `clear`. Owns the store under `%LOCALAPPDATA%\runes\clipboard\snippets` (`$XDG_DATA_HOME/runes/clipboard/snippets` on POSIX): an `index.tsv` plus one `<name>.<ext>` payload per snippet.
- `scripts/secret-scan.ps1` / `.sh` - dot-sourced by `save` to scan text payloads; on a hit `save` emits `SNIPPET_REFUSED=secret:<types>` and stores nothing.
- `scripts/clipboard-io.ps1` / `.sh` `write` - invoked by `get` (under `-STA`) to re-copy the payload onto the clipboard; emits `SNIPPET_RECOPIED=clipboard`.

Pipeline (save): capture source (`clipboard-io read` -> temp text file, or `CLIP_PATH` for an image, or explicit content) -> `clip-snippet save` -> sanitize name, scan-or-refuse text, replace any prior payload, append/sort the index. Pipeline (get): `clip-snippet get` -> resolve key -> `clipboard-io write` -> stream text body (or emit `SNIPPET_KIND=image` + `SNIPPET_PATH`).

For the snippet index schema (6 columns: name, ts, kind, subtype, bytes, preview) and the per-verb `SNIPPET_*` output keys, see ../../contract/CONTRACTS.md. This SPEC does not re-define them.

## Logic / algorithm

1. Pick the verb from the request: save, recall (get), list, search, delete (rm/clear).
2. save:
   - Source defaults to the current clipboard (`clipboard-io read`): for text, write the BEGIN/END body to a temp file; for an image, use `CLIP_PATH`. The user may instead point at explicit content.
   - Call `save -Name <name> -Kind <text|image> -Subtype <t> -Path <file>`. The script sanitizes the name to kebab-case (`Safe-Name`: lowercase, non-`[a-z0-9._-]` runs -> `-`, trimmed), so `MIT Header` -> `mit-header`. An image is detected by `-Kind image` or by extension (`.png/.jpg/.jpeg/.bmp/.gif/.tiff`).
   - Text is secret-scanned; a hit emits `SNIPPET_REFUSED=secret:<types>` and aborts the save. Images are stored as-is, unscanned.
   - Any prior payload for that key (`<key>.*`) is deleted first so save OVERWRITES, including a kind change (text->image). The index row for the key is dropped, a fresh row appended, and the index re-sorted by name. Emits `SNIPPET_SAVED=<key>`.
3. get: resolve `<key>.*`, `clipboard-io write` it (`-STA`), emit `SNIPPET_NAME`/`SNIPPET_RECOPIED=clipboard`; for `.txt` stream the body between the markers, else emit `SNIPPET_KIND=image` + `SNIPPET_PATH` (Read that path to show it). Unknown name -> `SNIPPET_ERROR`; fall back to `list` + closest-match suggestions.
4. list / search / delete: `list` prints `SNIPPET_COUNT` then `name<TAB>kind/subtype<TAB>bytesB<TAB>preview` per row; `search -Query <q>` matches name/preview and (for text) payload content, emitting `SNIPPET_MATCHES` + hit rows; `rm -Name <n>` deletes one; `clear` deletes all.
5. Report in the rune banner format - a compact named list for `list`, never dumping payloads.

## Correctness + edge cases

- Names are sanitized before use as both the index key and the on-disk filename, so `MIT Header`, `mit header`, and `mit-header` all resolve to one snippet.
- save overwrites: re-saving a name replaces payload, kind, and index row in place - it does not accumulate duplicates.
- A kind change is handled: deleting `<key>.*` first means a text->image (or image->text) re-save leaves exactly one payload file.
- Text secrets are refused (`SNIPPET_REFUSED`), nothing is written; image snippets bypass the scan and are stored verbatim.
- Empty/invalid name -> `SNIPPET_ERROR=missing/invalid -Name`; missing/unreadable path -> `SNIPPET_ERROR=missing -Path`.
- get on an unknown name -> `SNIPPET_ERROR`, not a silent no-op.
- The store is owner-only (`icacls /inheritance:r` on Windows, `chmod 700` on POSIX) and has no expiry or cap.

## Parity

Verified platform: Windows. The `.ps1` is the verified backend; `clip-snippet.sh` mirrors it. The contract test runs BOTH backends against an isolated store and asserts the same `SNIPPET_*` outputs and the 6-column index row. `get`/recall calls `clipboard-io write` under `-STA`. POSIX gaps: macOS/Linux backends are needs-verification, and setting an IMAGE clipboard on recall needs `wl-copy`/`xclip` - macOS `pbcopy` cannot set an image clipboard (a stated non-claim), so an image-snippet recall is text-clipboard-only there.

## Gotchas

- Index schema drift, doc vs code: the canonical snippet index is 6 columns - `name, ts, kind, subtype, bytes, preview` (`contract/snippet.columns`) - and `clip-snippet.ps1`/`.sh` both WRITE and LIST 6 columns. But the HEADER COMMENT in `clip-snippet.ps1` (and `.sh`) wrongly documents 5 - `name \t iso-ts \t subtype \t bytes \t preview`, omitting `kind`. This is a doc-vs-code drift in the script comment; the code is correct, the comment is stale. `contract-test.sh` now pins the row at 6 columns, so the drift is caught rather than trusted.
- Secret REFUSAL on save: a text snippet that scans positive is refused outright (`SNIPPET_REFUSED=secret:<types>`); the library is for boilerplate, not credentials. Images are never scanned - do not stash a screenshot of a token expecting a refusal.
- System-clipboard STA: `get` re-copies via `clipboard-io.ps1 write` launched with `-STA`; an image recall in particular needs STA to set the clipboard. The recall (system-clipboard write) is NOT asserted by the automated contract test - it touches the live clipboard and is out of scope.
- `IFS=$'\t' read` empty-field fold (POSIX backend class): splitting the TSV with a `read`/`IFS` pattern collapses adjacent tabs, so an empty preview (or any empty trailing field) silently shifts columns. The `.sh` backend reads rows with `awk -F'\t'` (which preserves empty fields) precisely to avoid this; do not "simplify" it to `IFS=$'\t' read`.
- PowerShell case-insensitive variable/param collision: PowerShell treats `$Path`/`$path`, `$Name`/`$name`, `$Kind`/`$kind` as the same variable, and dot-sourcing a script with a `param()` block would rebind the caller's vars. `secret-scan.ps1` deliberately omits `param()` and parses `$args` so a dot-source does not clobber the caller's `$Path`/`$Text`. Keep that shape - adding a param block to a dot-sourced helper reintroduces the collision.

## Status

SHIPPED. Verified platform: Windows.
Verified by: ../../contract/contract-test.sh (runs both backends; asserts the per-verb `SNIPPET_*` contract and the 6-column index row. The `get`/recall system-clipboard write is not asserted - it touches the live clipboard and is out of scope).
