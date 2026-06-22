Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

# clip-edit - SPEC

## Purpose

Read the clipboard TEXT, apply the transformation the user described, and write
the result BACK to the clipboard so the next paste is the edited version.

Goal: a faithful, non-generative transform (pretty-print JSON, markdown table,
strip rich-text, redact secrets/PII, translate, tighten/expand prose, fix
code) round-tripped clipboard -> transform -> clipboard.

Non-goals:

- TEXT only. Image / files / empty are rejected with a redirect to /clip.
- Does NOT invent content. If the request is ambiguous, ask one short question
  rather than guessing.
- Does NOT persist a named/durable copy (that is /clip-snippet, /clip-save).

## Scripts + data flow

```
clipboard-io read            -> CLIP_KIND + inline text (BEGIN/END markers)
[secret-scan -Redact]        -> deterministic redaction when asked
Write tool -> temp result file (e.g. edit-result.txt)
clipboard-io write -Path f   -> CLIP_WRITE=ok
```

- `scripts/clipboard-io.{ps1,sh}` `read` then `write`.
- `scripts/secret-scan.{ps1,sh}` `-Path <file> -Redact` (`--path`/`--redact`)
  is the deterministic engine for the "redact secrets" transform: it returns
  the text with each credential replaced by `[REDACTED:<type>]` between
  BEGIN/END REDACTED markers.

Output keys (`CLIP_KIND`, `CLIP_SECRETS`, `CLIP_WRITE`) and the redacted-marker
format are defined in ../../contract/CONTRACTS.md.

## Logic / algorithm

1. Run `clipboard-io read` (Windows STA).
2. Guard on `CLIP_KIND`: not `text` -> stop, tell the user clip-edit
   transforms text (image/files -> /clip); `empty` -> ask them to copy
   something. If `CLIP_SECRETS=<types>` and the request is "redact"/"remove
   secrets", prefer `secret-scan -Redact` over eyeballing.
3. Take the source text INLINE between the `-----BEGIN CLIP TEXT-----` /
   `-----END CLIP TEXT-----` markers (it is streamed, never a file). Apply the
   transform from the arguments. No transform given -> ask one question.
4. Write the transformed text to a new file under `%TEMP%\runes\clipboard\`
   (e.g. `edit-result.txt`). This is the only file clip-edit touches; the
   source text was never on disk.
5. Load it: `clipboard-io write -Path <result>` (Windows STA). Expect
   `CLIP_WRITE=ok`.
6. Confirm: on the clipboard, paste-ready; show a short before -> after preview.

## Correctness + edge cases

- The source clipboard text is never written to disk by this rune; only the
  transformed RESULT is (the result file is the new clipboard content).
- "Replaces the clipboard" is the intended side effect; the original capture is
  not separately persisted by clip-edit (the read streams it inline), so there
  is no read `CLIP_PATH` for text to fall back to - call out that the original
  is gone once overwritten.
- Redaction of secrets should use the deterministic `secret-scan` engine, not a
  hand transform, so no credential slips through.

## Parity (.ps1 vs .sh)

Verified platform: Windows (`clipboard-io.ps1`, STA). macOS/Linux
(`clipboard-io.sh`, needs verification): read via pbpaste / wl-paste / xclip /
xsel, write via pbcopy / wl-copy / xclip / xsel; `secret-scan.sh
--path --redact` mirrors the `.ps1` redact output.

## Gotchas

- STA requirement (Windows): the documented read/write invocations pass `-STA`.
- The transform is NON-generative: faithful only. Inventing or rewording beyond
  the request is a correctness break, not a feature.
- Secret REFUSAL applies on the read flag (`CLIP_SECRETS`), and the redact path
  is deterministic - prefer it so secrets are not surfaced or mis-redacted.
- Marker collision: if the clipboard text literally contains a BEGIN/END marker
  line, treat the outermost envelope as the stream boundary.

## Status

SHIPPED. Verified platform: Windows. macOS/Linux backend present, unverified.
Verified by: ../../contract/contract-test.sh (note: clipboard-io
system-clipboard read/write is NOT asserted by the automated test - it does not
touch the live clipboard).
