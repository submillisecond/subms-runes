Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

# clip - SPEC

## Purpose

Read the system clipboard and answer the user's question about whatever is on
it - copied text, an image (screenshot / picture), or copied file(s).

Goal: surface the clipboard payload into the conversation and answer ONLY what
was asked, in the shared rune reply shape.

Non-goals:

- Does NOT write the clipboard. Read-only; no transform, no re-copy, no save.
  Writing back is /clip-edit; re-copying from history is /clip-history.
- Does NOT generate or critique content on a bare `/clip` - it summarises the
  salient detail and asks what the user wants to know.
- Does NOT echo secret values verbatim (see Gotchas).

## Scripts + data flow

One script: `scripts/clipboard-io.{ps1,sh}` in `read` mode.

```
clipboard-io read  ->  CLIP_KIND={files|image|text|empty} (+ CLIP_* keys)
                       text   : streamed inline between BEGIN/END CLIP TEXT markers
                       image  : CLIP_PATH=<png in temp dir>
                       files  : CLIP_COUNT + one original path per line
```

The rune branches on `CLIP_KIND`, reads the payload (inline text, or via the
Read tool for an image / each file), then answers.

Output keys (`CLIP_KIND`, `CLIP_PATH`, `CLIP_COUNT`, `CLIP_BYTES`, `CLIP_LINES`,
`CLIP_SECRETS`, `CLIP_SECRET_COUNT`) and the text-stream marker format are
defined in ../../contract/CONTRACTS.md - not re-specified here.

## Logic / algorithm

1. Run `clipboard-io read` (Windows: `powershell.exe -NoProfile
   -ExecutionPolicy Bypass -STA -File clipboard-io.ps1 read`; macOS/Linux:
   `bash clipboard-io.sh read`).
2. Read `CLIP_KIND` and act:
   - `text` -> the full content is INLINE between the
     `-----BEGIN CLIP TEXT-----` / `-----END CLIP TEXT-----` markers. Use it
     directly; there is no `CLIP_PATH` (text is never written to disk).
   - `image` -> Read the file at `CLIP_PATH` (the Read tool renders it).
   - `files` -> Read each listed path; ALWAYS state each file's FULL path in
     the reply. Unsupported binaries (.docx/.xlsx/.zip) are named with their
     path and a suggestion to copy the contents as text.
   - `empty` -> tell the user to copy something first.
3. Secret guard: if `CLIP_SECRETS=<types>` is present, LEAD with a `🚩`
   warning naming the types, mask any secret values (e.g. `ghp_****`), and
   offer to redact via `secret-scan` or `/clip-edit redact the secrets`.
4. Answer the user's question (the skill arguments). For a bare `/clip`,
   give the two header lines + 2-3 salient bullets and ask what they want.

## Correctness + edge cases

- Read priority is files -> image -> text -> empty; a clipboard holding several
  representations resolves to the highest-priority one the OS exposes.
- `text` whitespace-only collapses to `empty` (the read trims before deciding).
- A bare `/clip` must NOT inventory the whole clipboard or volunteer critique;
  a specific question is answered directly and only it.
- Image is the only kind that yields a file path; text and files never put the
  text on disk.

## Parity (.ps1 vs .sh)

Verified platform: Windows (`clipboard-io.ps1`, STA, `Get-Clipboard`).

macOS/Linux (`clipboard-io.sh`, needs verification on those OSes):

- text/set: macOS `pbpaste`/`pbcopy`; Wayland `wl-paste`/`wl-copy`; X11
  `xclip` (or `xsel`, text-only).
- image: macOS `pngpaste` (brew, optional); Wayland/X11 via wl-paste / xclip
  `image/png`.
- files: Linux only, via `text/uri-list`; NOT on macOS (stated non-claim).
- With no clipboard tool present the read returns `CLIP_KIND=empty` +
  `CLIP_NOTE` naming the tools to install.

## Gotchas

- STA requirement (Windows): `Get-Clipboard` for image/filedrop needs an STA
  apartment - the `-STA` flag is mandatory. Without it image/file reads fail.
- Secret REFUSAL is upstream of the rune: the read scans text via
  `secret-scan` and flags it with `CLIP_SECRETS`; the rune must not echo the
  raw value. (clip is read-only, so nothing is persisted regardless.)
- The text stream can contain the BEGIN/END marker strings as content; treat
  the FIRST `-----BEGIN CLIP TEXT-----` and the trailing END as the envelope.

## Status

SHIPPED. Verified platform: Windows. macOS/Linux backend present, unverified.
Verified by: ../../contract/contract-test.sh (note: clipboard-io system-clipboard
read/write ops are NOT asserted by the automated test - it does not touch the
live clipboard).
