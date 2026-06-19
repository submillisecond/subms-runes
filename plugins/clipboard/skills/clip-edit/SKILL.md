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
2. If `CLIP_KIND` is not `text`, stop and tell the user clip-edit transforms text - for an image or files use `/clip`. If `empty`, ask them to copy something first.
3. Read the file at `CLIP_PATH`. Apply the transformation described in the arguments. If no transformation was given, ask the user what to do (one short question) rather than guessing.
4. Write the transformed text to a new file in the same folder as `CLIP_PATH` (for example `...\runes-clip\edit-result.txt`).
5. Load it onto the clipboard. Windows:
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" write -Path "<result file>"`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" write "<result file>"`
   Expect `CLIP_WRITE=ok`.
6. Confirm: the result is on the clipboard, ready to paste. Show a short before -> after preview.

## Notes

- Windows (verified) under STA; macOS/Linux via `clipboard-io.sh` (verify there).
  Replaces the clipboard contents (side effect).
- Keep transforms faithful - do not invent content; if the request is ambiguous, ask.
