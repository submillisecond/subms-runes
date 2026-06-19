---
name: shots-save
description: This skill should be used when the user asks to "/shots-save", "save my last N screenshots to <folder>", "bundle my recent screenshots", "collect the screenshots from the last X minutes", or otherwise wants recent screenshot files copied to a destination (for sharing or a bug report).
version: 0.1.0
---

# shots-save - collect recent screenshots into a folder

Select recent screenshots (same selection as `shots`) and COPY them to a
destination, leaving the originals in place. Useful for bundling a bug report or
a share set.

## Steps

1. Select the screenshots with the host OS finder (same flags as `shots`).
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.ps1" <selection flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.sh" <selection flags>`
   Selection: count, minutes, today, yesterday, since, until, name, dir. If the user gave no selection it returns only the most recent one - confirm that is intended before saving just one.
2. Resolve the destination folder:
   - If the arguments name a folder, use it (relative -> cwd; absolute as-is).
   - Otherwise use the runes outbox: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes\shots-<stamp>` (Windows) or `~/Downloads/runes/shots-<stamp>` (macOS/Linux). Create it if missing.
3. Copy each listed path into the destination with a real file copy (`Copy-Item` / `cp`), preserving filenames. Do NOT move or delete the originals.
4. Report the absolute destination folder and the count + total size copied.

## Notes

- Read-only on the source folder; it only copies out.
- If a single file destination is given but several match, copy into a folder instead and say so.
