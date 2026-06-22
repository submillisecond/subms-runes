Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

# clip-history - SPEC

## Purpose

A durable, typed, searchable log of clipboard operations. This rune views,
searches, recalls (re-copies), and manages that store. Recall is the headline:
pick the entry the user means in natural language and put it back on the
clipboard.

Goal: privacy-first recall + management of past clipboard payloads.

Privacy posture (all enforced by the backend, not the rune):

- OFF by default - the user opts in (`enable`, or `RUNES_CLIP_HISTORY=1`).
- Secrets are NEVER stored (every text entry is scanned on `add`).
- Entries live owner-only under the per-user app-data dir.
- Size/count caps bound the store.

Non-goals:

- Does NOT name/curate a reusable library (that is /clip-snippet - automatic
  chronological log here vs a named library there).
- Does NOT capture anything while disabled (no retroactive logging).

## Scripts + data flow

One script: `scripts/clip-history.{ps1,sh}`. It owns the store and, on `get`,
delegates to `clipboard-io write` to re-copy a text entry.

```
Store: %LOCALAPPDATA%\runes\clipboard\history\   (XDG_DATA_HOME/... on *nix)
  index.tsv    one TSV row per entry (newest appended last)
  <id>.txt|.png|.files.txt   the payload
  .enabled     presence = recording on

add   -> HISTORY_ADDED=<id> | HISTORY_SKIPPED=<reason>
list  -> HISTORY_COUNT + newest-first #n rows
search-> HISTORY_MATCHES + matching rows
get   -> HISTORY_ID/KIND, re-copies text (clipboard-io write), HISTORY_RECOPIED=clipboard
rm/clear -> HISTORY_REMOVED / HISTORY_CLEARED
status/enable/disable -> HISTORY_ENABLED (+ DIR/COUNT)
```

The `index.tsv` column layout (7 cols: id, ts, kind, subtype, bytes, source,
preview) is canonical in ../../contract/CONTRACTS.md and
../../contract/history.columns - NOT re-defined here.

## Logic / algorithm

1. Read the request and pick the verb:
   - view -> `list [-Count N]` (default 20), newest first.
   - search -> `search -Query <text>` (literal substring, regex-escaped).
   - recall -> see step 2.
   - enable / disable / status.
   - delete one / all -> `rm -Id <id|#n>` / `clear`.
2. Recall (headline; natural-language match is the rune's job): run `list` (or
   `search`), read the TYPED rows, pick the entry - "the last url" -> newest
   `url` subtype; "that python function" -> newest `code` row that looks
   Python; "#2" -> that index. Then `get -Id <id|#n>`: the backend prints the
   content AND re-copies it (`HISTORY_RECOPIED=clipboard`). Confirm what is now
   on the clipboard. No match -> say so + show the closest rows.
3. Enabling: if history is wanted but off (`HISTORY_ENABLED=0`), run `enable`,
   say recording is now on (future ops only; nothing was logged while off),
   note owner-only storage + secret skipping.
4. Report in the rune reply shape; never dump payloads in a list.

Backend internals worth pinning:

- `add` order of guards: disabled -> missing path -> over MAX_BYTES ->
  EXCLUDE regex -> secret scan -> write payload + append row -> prune to
  MAX_ENTRIES (drop oldest). Any guard emits `HISTORY_SKIPPED=<reason>`.
- `list` numbers newest=#1 by walking the append-ordered index in reverse.
- `get -Id #n` maps n to `rows[count - n]`; a bare id matches column 1.
- `clear` removes everything EXCEPT `.enabled` (recording stays on).

## Correctness + edge cases

- `enable`/`disable` toggle a persisted `.enabled` flag; `RUNES_CLIP_HISTORY=1`
  forces on regardless of the flag.
- Caps: `RUNES_HISTORY_MAX_ENTRIES` (default 200), `RUNES_HISTORY_MAX_BYTES`
  per entry (default 1 MB). Over-cap entries are skipped (bytes) or pruned
  oldest-first (count). NOTE the SKILL.md `Notes` cites a 200 default; the
  `add`-path default is also 200 - the store layout comment's "200" governs.
- `RUNES_HISTORY_EXCLUDE` (regex) drops matching payloads before storing.
- `get` on a missing payload file -> `HISTORY_ERROR=payload missing`; unknown
  id -> `HISTORY_ERROR=no such entry`.
- Only text entries are re-copied to the clipboard on `get`; image/files
  entries return a `HISTORY_PATH` instead.

## Parity (.ps1 vs .sh)

Verified platform: Windows (`clip-history.ps1`; store under `%LOCALAPPDATA%`;
owner-only via `icacls /inheritance:r /grant:r`).

macOS/Linux (`clip-history.sh`, needs verification): store under
`${XDG_DATA_HOME:-$HOME/.local/share}`; owner-only via `chmod 700`; flags are
`--count`/`--query`/`--id`/`--kind`/`--subtype`/`--source`/`--path`. Re-copy on
`get` delegates to `clipboard-io.sh write`. The verb set and KEY=value output
contract are asserted identical across both backends by the contract test.

## Gotchas

- Secret REFUSAL on save: `add` runs `secret-scan` over the text body and
  returns `HISTORY_SKIPPED=secret:<types>` rather than writing it - secrets are
  never persisted to history. (clip-copy relies on this.)
- STA requirement: `get` re-copies a text entry by spawning
  `clipboard-io.ps1 ... -STA write`; the system-clipboard write needs STA.
- `IFS=$'\t' read` empty-field fold (bitten elsewhere in this repo): the `.sh`
  backend slices rows with `cut`/`awk -F'\t'`, NOT a bare `read` split on
  `IFS=$'\t'`. A bare tab-split `read` collapses consecutive/trailing empty
  fields, which would misalign columns when a `preview` or `subtype` is empty.
  Keep using `cut -f`/`awk -F'\t'` for any new row parsing.
- PowerShell case-insensitive param/variable collisions: `-Kind`, `-Subtype`,
  `-Source`, `-Id`, `-Query`, `-Count` bind case-insensitively, and local
  variable names collide the same way - a differently-cased duplicate silently
  clobbers. Use the documented casing.
- `get -Id` index path is order-sensitive: `#n` is resolved only when `$Id`
  starts with `#`; a bare numeric id is matched as a literal id (column 1),
  not as an index. Pass `#2` to mean "the 2nd newest".
- Sibling note (clip-snippet, same store family): its `index.tsv` is 6 columns
  (name, ts, kind, subtype, bytes, preview) but the `clip-snippet.ps1` header
  comment lists only 5 (it omits `kind`). The canonical
  ../../contract/snippet.columns (6 cols) governs; the stale comment is a
  documentation bug, not a schema change. clip-history's own index is 7 cols.

## Status

SHIPPED. Verified platform: Windows. macOS/Linux backend present, unverified.
Verified by: ../../contract/contract-test.sh - it asserts the store verbs
(add/list/search/status/clear) KEY=value output and the 7-column index row on
BOTH backends against an isolated temp store. Note: the `get`/recall path and
the underlying clipboard-io system-clipboard write are NOT exercised by the
automated test (they touch the live clipboard).
