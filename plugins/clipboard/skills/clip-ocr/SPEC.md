# clip-ocr SPEC

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

## Purpose

Transcribe the text inside an image and, by default, print it back in the reply.

- Goal: turn a clipboard image (or an attached image, or a file path) into faithful, verbatim text the user can read and copy.
- Goal: keep the default side-effect-free - print only, no file written, no clipboard touched.
- Non-goal: an installable OCR engine. The transcription is vision-based (the Read tool renders the image; the model reads it). There is no Tesseract/engine dependency.
- Non-goal: placing the text anywhere. Copy-to-clipboard and save-to-file are opt-in, triggered only when the request asks for them.

## Scripts + data flow

The skill drives at most two scripts, both only on the clipboard path or when placing output:

- `scripts/clipboard-io.ps1` / `.sh` `read` - capture the clipboard. Emits the `CLIP_KIND` summary; for an image it writes a PNG and emits `CLIP_PATH`. Only used when the image source is the clipboard (not for an attached image or an explicit file path).
- `scripts/clipboard-io.ps1` / `.sh` `write` - set the clipboard to the transcribed text, only when the user asked to "copy it".
- `scripts/clip-history.ps1` / `.sh` `add` - best-effort record, only when the text actually went to the clipboard.

Pipeline: resolve image source (attachment | file path | clipboard) -> Read/render the image -> transcribe -> by default print; on request also write a temp `.txt` and `clipboard-io write`, and/or save a file -> history `add` only if it was copied -> report.

For `CLIP_KIND`, `CLIP_PATH`, `CLIP_WRITE`, and the history index schema, see ../../contract/CONTRACTS.md. This SPEC does not re-define those shapes.

## Logic / algorithm

1. Find the image, checking sources in this order (clipboard is just the default):
   - Image attached to the prompt -> transcribe it directly, no script call.
   - Explicit path(s) in arguments (`/clip-ocr C:\shots\err.png`) -> Read each path. A folder or several paths transcribe each.
   - Otherwise the clipboard -> `clipboard-io read`.
2. On the clipboard path, branch on `CLIP_KIND`:
   - `image` -> proceed with `CLIP_PATH` (the captured PNG).
   - `files` -> if a single image file, transcribe it; else report what was copied.
   - `text` -> nothing to OCR, point at `/clip`.
   - `empty` -> ask for an image / path / attachment.
3. Read the image and transcribe faithfully: verbatim wording/casing/punctuation/numbers; preserve line breaks, code, and table layout; join wrapped prose into paragraphs; transcribe all of it unless the arguments scope it; mark unreadable spans `[illegible]` rather than guessing.
4. Decide the destination from the request (default PRINT):
   - Default: print the full transcription in a fenced block. No temp file, no clipboard write.
   - "copy it" / "onto my clipboard": also write the text to `%TEMP%\runes\clipboard\ocr-<stamp>.txt` then `clipboard-io write` that file; expect `CLIP_WRITE=ok`.
   - "save it" / "to <path>": also write to the given path, or default `%USERPROFILE%\Downloads\runes\clips\ocr-<YYYYMMDD-HHMMSS>.txt`, extension chosen by content as in `/clip-save`.
   - Copy and save can both be requested; only create files for the destinations asked.
5. Record to history only if the text reached the clipboard (best-effort, run standalone).
6. Report in the rune banner format.

## Correctness + edge cases

- Default is print-only: a transcription with no copy/save request leaves the clipboard and disk untouched.
- Illegible text is marked, never invented.
- Multiple paths / a folder transcribe each image rather than silently picking one.
- `files` with more than one entry, or a non-image file, is reported rather than mis-transcribed.
- `text` and `empty` are dead ends for OCR and are redirected, not forced.
- History is recorded only on the copy path; a print-only or save-only run records nothing.

## Parity

Verified platform: Windows. `clipboard-io.ps1` runs under `-STA` (required for clipboard image and file-drop access). `clipboard-io.sh` mirrors it on macOS/Linux via `pbpaste`/`pngpaste` (macOS) and `wl-paste`/`xclip`/`xsel` (Linux), and is marked needs-verification. Gaps on the `.sh` side: clipboard image capture on macOS needs `pngpaste` (a brew install); clipboard file lists are Linux-only (`text/uri-list`), not macOS. The vision transcription itself is platform-independent - it does not depend on either backend.

## Gotchas

- The system-clipboard read/write are not exercised by the automated contract test (they touch the live clipboard) and vision-based OCR is not script-testable - so the OCR path has no executable assertion; correctness rests on the SKILL prose plus the shared `clipboard-io` contract.
- STA matters: `clipboard-io.ps1` must be launched with `-STA` or `Get-Clipboard -Format Image`/`FileDropList` returns nothing - an image silently looks `empty`.
- Copy path only: history records a clip only when the text went to the clipboard; do not record on print-only or save-only runs (it would log a phantom clipboard event).
- Do not chain the `clip-history add` call with shell syntax (`2>$null`, `; ...`) - a `.ps1` invoked through the Bash tool chokes on PowerShell redirects. Run it standalone and ignore failures.

## Status

SHIPPED. Verified platform: Windows.
Verified by: ../../contract/contract-test.sh (the clipboard-io system-clipboard ops are not asserted by the automated test, and vision-based OCR is not script-testable).
