---
name: clip
description: This skill should be used when the user asks to "read my clipboard", "what's on my clipboard", "/clip", "ask about what I copied", "summarize what I copied", "what does this screenshot say", or otherwise wants the contents of the clipboard (text, an image, or copied files) inspected and questions answered about them.
version: 0.1.0
---

# clip - ask questions about your clipboard

Capture whatever is on the Windows clipboard - copied text, an image (screenshot
or picture), or copied file(s) - and answer the user's question about it.

## Steps

1. Capture the clipboard, using the host OS backend. On Windows (PowerShell, STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`
   On macOS/Linux:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`
2. Read `CLIP_KIND` from the output and act:
   - `text` -> Read the file at `CLIP_PATH` for the full content (a preview is already shown).
   - `image` -> Read the file at `CLIP_PATH` (the Read tool renders the image).
   - `files` -> Read each listed path. The Read tool handles text, code, markdown, JSON/YAML, images, PDFs, and notebooks. For unsupported binaries (.docx, .xlsx, .zip), say so and suggest copying the contents as text instead.
   - `empty` -> Tell the user the clipboard is empty and to copy something first.
3. Answer the user's question (the skill arguments). If none was given, briefly summarize what was captured and ask what they want to know.

## Notes

- Windows (verified) uses `Get-Clipboard` under STA. macOS/Linux use the
  `clipboard-io.sh` backend (pbpaste / xclip / wl-paste) - verify on those OSes.
- Captured payloads go to the OS temp dir (`%TEMP%\runes-clip\` or `$TMPDIR/runes-clip`). Clipboard contents may be sensitive - they are pulled into the conversation.
