---
name: clip-edit
description: This skill should be used when the user asks to "/clip-edit", "reformat my clipboard", "fix what I copied and put it back", "clean up the clipboard", "convert my clipboard to ...", "redact my clipboard", "translate my clipboard", "make this paste-ready", or otherwise wants the clipboard text TRANSFORMED and written back so it is ready to paste.
version: 0.1.0
---

# clip-edit - transform the clipboard, paste-ready

Read the clipboard text, apply the transformation the user described, and write
the result BACK to the clipboard so the next paste is the edited version. The
transform is whatever the arguments ask for: pretty-print JSON, convert to a
markdown table, strip rich-text formatting, redact secrets/PII, translate,
tighten or expand prose, fix code, and so on.

This rune REPLACES the clipboard. The original capture is kept at the read
`CLIP_PATH` in case it is needed again.

## Steps

1. Capture the clipboard, using the host OS backend. Windows (PowerShell, STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`
2. If `CLIP_KIND` is not `text`, stop and tell the user clip-edit transforms text - for an image or files use `/clip`. If `empty`, ask them to copy something first. If the capture reports `CLIP_SECRETS=<types>` and the request is "redact"/"remove secrets", prefer the deterministic engine - `secret-scan.ps1 -Path <file> -Redact` (`.sh`: `--path`/`--redact`) returns the text with each credential replaced by `[REDACTED:<type>]` - rather than eyeballing it.
3. Take the source text from the script output, between the `-----BEGIN CLIP TEXT-----` and `-----END CLIP TEXT-----` markers (it is streamed inline, not a file). Apply the transformation described in the arguments. If no transformation was given, ask the user what to do (one short question) rather than guessing.
4. Write the transformed text to a new file under `%TEMP%\runes\clipboard\` (e.g. `edit-result.txt`) - the clipboard `write` mode loads from a file. (This is the only file clip-edit touches; the source text was never on disk.)
5. Load it onto the clipboard. Windows:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" write -Path "<result file>"`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" write "<result file>"`
   Expect `CLIP_WRITE=ok`.
6. Confirm: the result is on the clipboard, ready to paste. Show a short before -> after preview.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-edit` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📋` `📁` `📦` `💾` `📊` `📝` `📌` `🔖` `📄` `🔑` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the transform applied.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 is `📋 ` + the result file path (the new clipboard content on disk). Line 2
is the heading `📝 **Edited:**`. Then the `📌 What` bullet, a short before -> after
preview, and a `📋 **Clipboard:**` bullet confirming it is ready to paste.

```
ᚱ clipboard › /clip-edit v0.1.0
📋 `C:\...\runes\clipboard\edit-result.txt`
📝 **Edited:**
- 📌 **What:** pretty-printed the JSON (2-space indent, keys sorted).
- 📋 **Clipboard:** ready to paste; original kept at the read path.
```

## Notes

- Windows (verified) under STA; macOS/Linux via `clipboard-io.sh` (verify there).
  Replaces the clipboard contents (side effect).
- Keep transforms faithful - do not invent content; if the request is ambiguous, ask.
