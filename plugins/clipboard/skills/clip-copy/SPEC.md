Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

# clip-copy - SPEC

## Purpose

Take a clean deliverable from YOUR own recent output, strip the conversational
scaffolding, and load it onto the system clipboard so the user can paste it
straight away. This is the Claude-output -> clipboard direction (inverse of
/clip).

Goal: faithful copy of one artifact (code / command / url / email / path /
json / yaml / plain), paste-ready.

Non-goals:

- Does NOT read the existing clipboard (it REPLACES it - see Gotchas).
- Does NOT reformat, prettify, re-wrap, sort, or "clean up" the artifact. Copy
  is faithful, not opinionated (the "copy faithful" rule, below).
- Does NOT transform content (that is /clip-edit) or save to a named/durable
  location (that is /clip-save, /clip-snippet).

## Scripts + data flow

```
Write tool -> temp file (copy-<stamp>.txt)
clipboard-io write -Path <temp>   -> CLIP_WRITE=ok (+ CLIP_BYTES)
clip-history add (best-effort)    -> HISTORY_ADDED=<id> | HISTORY_SKIPPED=...
```

- `scripts/clipboard-io.{ps1,sh}` `write` mode: loads the clipboard from the
  temp file's UTF-8 text. A file (not an inline arg) avoids any
  command-length limit on large payloads.
- `scripts/clip-history.{ps1,sh}` `add`: records the same temp file as a typed
  entry. Best-effort; a no-op when history is disabled, and a hard skip when
  the body is secret-bearing.

Output keys (`CLIP_WRITE`, `CLIP_BYTES`, `HISTORY_ADDED`, `HISTORY_SKIPPED`)
are defined in ../../contract/CONTRACTS.md.

## Logic / algorithm

1. Pick the deliverable from the recent conversation - by default the single
   most useful artifact from the last substantive message, or the target the
   arguments name (`the code`, `the command`, `the url`, `the email`,
   `the path`, `the json`/`yaml`/`config`, `the answer`, `as plain text`). If
   ambiguous among several blocks, pick the most recent and say which.
2. Strip scaffolding, preserve the payload EXACTLY: remove fences, language
   tags, leading prompts (`$ `, `> `, `PS> `), explanatory sentences, trailing
   commentary. A command is one paste-ready line with no trailing newline. For
   CODE: keep exact indentation, blank lines, tabs-vs-spaces; do NOT reformat;
   keep a trailing newline only if the file form would have one.
3. Write the clean text to `%TEMP%\runes\clipboard\copy-<stamp>.txt`
   (`$TMPDIR/runes/clipboard/` on macOS/Linux) with the Write tool. For a long
   or whitespace-sensitive block, re-read the temp file and confirm it matches
   the source before loading the clipboard (guards transcription drift).
4. Load it: `clipboard-io write -Path <temp>` (Windows STA). Expect
   `CLIP_WRITE=ok`.
5. Record to history (best-effort, its OWN command - do NOT chain `;`/`2>$null`
   /`(Get-Item ...)` onto a `.ps1` invoked through Bash). Classify the artifact
   via `-Kind text -Subtype <code|command|url|email|path|json|plain> -Source
   clip-copy -Path <temp>`. Ignore any error; the copy already succeeded.
6. Report: what was copied + a short preview + size.

## Correctness + edge cases

- The "copy faithful, not opinionated" rule is load-bearing: a silent
  re-indent or prettify pastes broken code. The optional re-read in step 3 is
  the check.
- A command must be a single line with no trailing newline and no prompt glyph.
- History add is strictly best-effort: disabled / excluded / too-large /
  secret-bearing all return a `HISTORY_SKIPPED=...` that the rune ignores.
- The artifact comes from Claude's output, so the source is the user's own
  content; the history store still refuses to persist a secret-bearing body.

## Parity (.ps1 vs .sh)

Verified platform: Windows (`clipboard-io.ps1` write under STA; Set-Clipboard).

macOS/Linux (`clipboard-io.sh write`, needs verification): text set via
`pbcopy` / `wl-copy` / `xclip` / `xsel`. With no clipboard tool the write
returns `CLIP_WRITE=error` naming the tools to install. History add parity
mirrors clip-history (`--kind`/`--subtype`/`--source`/`--path`).

## Gotchas

- This rune REPLACES the clipboard (side effect): the previous contents are
  gone. If the user might want them, suggest `/clip` first.
- STA requirement (Windows): image writes need STA; text via Set-Clipboard is
  fine, but the documented invocation passes `-STA` uniformly.
- Secret REFUSAL on the history add: `clip-history` scans the body and skips
  any secret-bearing payload, so secrets reach the clipboard (the user's own
  output) but are NEVER persisted to the durable store.
- Do NOT chain shell operators onto the `.ps1` history call through the Bash
  tool - PowerShell chokes on `;`/`2>$null`/`(Get-Item ...)`; run it as its
  own command.
- `clip-history.ps1` is case-insensitive on params: PowerShell binds `-Kind`,
  `-Subtype`, etc. case-insensitively, so a stray casing variant of a param or
  variable name can collide silently. Use the documented casing.

## Status

SHIPPED. Verified platform: Windows. macOS/Linux backend present, unverified.
Verified by: ../../contract/contract-test.sh (note: clipboard-io
system-clipboard write is NOT asserted by the automated test; the history add
contract IS).
