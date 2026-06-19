---
name: save
description: This skill should be used when the user asks to "/save" images, "save my last N screenshots to <folder>", "bundle my recent screenshots", "copy the images from <folder> to <dest>", or otherwise wants a selection of image files copied to a destination (for sharing or a bug report).
version: 0.1.0
---

# save - copy a selection of images to a folder

Select images (recent screenshots by default, or any `--dir`) and COPY them to a
destination, leaving the originals in place.

## Steps

1. Select with the finder (same flags as `ask`):
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.ps1" <flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.sh" <flags>`
   If no selection was given it returns only the most recent one - confirm that is intended before saving just one.
2. Resolve the destination:
   - An explicit path/folder in the arguments wins (relative -> cwd; absolute as-is).
   - Otherwise the runes outbox: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes\images-<stamp>` (Windows) / `~/Downloads/runes/images-<stamp>` (macOS/Linux). Create if missing.
3. Copy each listed path (`Copy-Item` / `cp`), preserving filenames. Never move or delete originals.
4. Report the absolute destination + count and total size copied.
