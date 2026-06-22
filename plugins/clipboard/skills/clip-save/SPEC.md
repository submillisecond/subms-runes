# clip-save SPEC

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

Write the current clipboard contents to a file or folder on disk.

- Goal: persist whatever is on the clipboard - text to a text file, an image to a PNG, copied file(s) into a folder.
- Goal: pick a sensible extension and a collision-safe filename when the user does not give one.
- Non-goal: transforming the content. The saved file is the RAW clipboard payload, never reformatted; any rich answer the user also asks for goes in the chat reply, not the artifact.
- Non-goal: silently saving credentials. A secret-bearing text clip stops for confirmation first.

## Scripts + data flow

- `scripts/clipboard-io.ps1` / `.sh` `read` - capture the clipboard. Emits `CLIP_KIND` and, depending on kind, `CLIP_BYTES`/`CLIP_LINES`, a streamed text body between `-----BEGIN/END CLIP TEXT-----`, `CLIP_PATH` (image), a `CLIP_COUNT` + path list (files), or `CLIP_SECRETS`/`CLIP_SECRET_COUNT` when the text scan trips.
- `scripts/secret-scan.ps1` / `.sh` - invoked transitively by `clipboard-io read` to flag credentials; may be called directly with `-Redact` to produce a redacted body if the user accepts a redacted save.
- `scripts/clip-history.ps1` / `.sh` `add` - best-effort record of the saved artifact.

Pipeline: `clipboard-io read` -> secret guard -> resolve destination + extension -> Write (text) or Copy-Item/cp (image/files) -> history `add` (best-effort) -> confirm absolute path(s).

For `CLIP_KIND`, `CLIP_BYTES`, `CLIP_PATH`, `CLIP_COUNT`, `CLIP_SECRETS`, the BEGIN/END CLIP TEXT framing, and the history index schema, see ../../contract/CONTRACTS.md. This SPEC does not re-define them.

## Logic / algorithm

1. Capture the clipboard with the host backend (`-STA` on Windows).
2. Secret guard: if the capture reports `CLIP_SECRETS=<types>`, STOP and name the credential types. Offer a redacted save (`secret-scan -Path <file> -Redact` -> save the `-----BEGIN/END REDACTED-----` body); save the raw secret only on explicit confirmation.
3. Resolve the destination:
   - Argument path/folder wins (relative -> cwd, absolute as-is).
   - Else the clipboard outbox: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes\clips` (or `~/Downloads/runes/clips`), created if missing.
   - Default filename `clip-<YYYYMMDD-HHMMSS>[-<short-slug>].<ext>` - always full date and time so saves sort and never collide; collision-safe ` (2)`, ` (3)` suffixing; never overwrite.
4. Act on `CLIP_KIND`:
   - `text` -> the body is streamed between the BEGIN/END markers (no `CLIP_PATH`). Write it, choosing the extension from what the content IS: `.txt` for plain prose (the default), `.md` only for genuine markdown, the language extension for source, `.json`/`.yaml`/`.toml`/`.xml`/`.csv`/`.tsv` for structured data, `.log` for logs/stack traces. An explicit extension in the arguments always wins.
   - `image` -> copy the PNG at `CLIP_PATH` (default `.png`).
   - `files` -> real file copy of each path into the destination folder (or to a single file destination), preserving binaries.
   - `empty` -> report nothing to save.
5. Record to history (best-effort, own command, ignore the result; never chain shell syntax onto it).
6. Confirm the absolute destination(s), kind, and size - reusing `CLIP_BYTES` or the bytes the Write/copy already reported, not a fresh `Get-Item .Length`.

## Correctness + edge cases

- Extension is chosen by content; plain text defaults to `.txt`, not `.md`. Explicit user extension overrides.
- Filenames carry full date+time to the second, so concurrent saves never collide; an existing name still gets ` (2)`/` (3)` rather than an overwrite.
- `image` and `files` use a real binary copy (`Copy-Item`/`cp`), so binaries are not corrupted by text encoding.
- A secret-bearing text clip never reaches disk without an explicit confirm; the redacted path is offered first.
- The saved file is raw content only; an analysis the user also requested lives in the chat reply, keeping artifact and answer separate.
- `empty` is reported, not written as a zero-byte file.

## Parity

Verified platform: Windows. `clipboard-io.ps1` runs under `-STA` (required for image and file-drop capture). `clipboard-io.sh` mirrors it via `pbpaste`/`pngpaste` (macOS) and `wl-paste`/`xclip`/`xsel` (Linux) and is needs-verification. Gaps: macOS clipboard image capture needs `pngpaste`; clipboard file lists are Linux-only (`text/uri-list`), not macOS. `secret-scan` and `clip-history` have `.ps1`/`.sh` mirrors with the same KEY=value contract.

## Gotchas

- STA: without `-STA`, `Get-Clipboard -Format Image`/`FileDropList` returns nothing - an image or file copy silently degrades to `empty`.
- The system-clipboard read (and therefore the whole save path) is not asserted by the automated contract test - it touches the live clipboard and is out of scope. The history `add` it calls IS contract-tested.
- Do not chain the `clip-history add` call: a `.ps1` invoked through the Bash tool chokes on appended `2>$null`, `; (Get-Item ...)`, or other PowerShell/shell mixing. Run it standalone; if it fails, the save already succeeded.
- Size comes from the value you already have (`CLIP_BYTES` or the Write/copy result); a separate `Get-Item ... .Length` is wasted work and can disagree on encoding.

## Status

SHIPPED. Verified platform: Windows.
Verified by: ../../contract/contract-test.sh (the clipboard-io system-clipboard ops are not asserted by the automated test; the history `add` path it invokes is).
