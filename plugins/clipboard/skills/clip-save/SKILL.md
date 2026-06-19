---
name: clip-save
description: This skill should be used when the user asks to "/clip-save", "save my clipboard to <path>", "stash this screenshot", "write what I copied to a file", "save the copied files to <folder>", or otherwise wants the clipboard contents written to a file or folder on disk.
version: 0.1.0
---

# clip-save - save the clipboard to disk

Read the clipboard and write it to a destination on disk: text to a text file, an
image/screenshot to a PNG, or copied file(s) into a folder.

## Steps

1. Capture the clipboard, using the host OS backend. Windows (PowerShell, STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`
2. Resolve the destination:
   - If the arguments give a path or folder, use it (relative paths resolve to the current working directory; absolute paths as-is).
   - Otherwise use the runes outbox: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes` (Windows) or `~/Downloads/runes` (macOS/Linux). Create it if missing.
3. Act on `CLIP_KIND`:
   - `text` -> write the text at `CLIP_PATH` to the destination file (default extension `.txt`, or `.md` if the content is markdown).
   - `image` -> copy the PNG at `CLIP_PATH` to the destination (default extension `.png`).
   - `files` -> copy each listed path into the destination folder (or, for a single file and a file destination, to that path). Use a real file copy (`Copy-Item` / `cp`) so binaries are preserved.
   - `empty` -> tell the user there is nothing on the clipboard to save.
4. Confirm the **absolute** destination path(s) written, and the kind/size saved.

## Notes

- Windows (verified) under STA; macOS/Linux via `clipboard-io.sh` (verify there).
- Do not overwrite an existing file without confirming, unless the user's path clearly means to replace it.
