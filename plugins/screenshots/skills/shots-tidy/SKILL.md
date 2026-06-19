---
name: shots-tidy
description: This skill should be used when the user asks to "/shots-tidy", "rename my last N screenshots by what they show", "delete screenshots older than X days", "clean up my screenshots folder", "archive last week's screenshots to <folder>", or otherwise wants recent/selected screenshots renamed, deleted, or archived in place.
version: 0.1.0
---

# shots-tidy - rename / delete / archive screenshots in place

Select screenshots (same selection as `shots`) and modify the folder per the
user's instruction: rename by content, delete, or archive (move) elsewhere. This
MUTATES the Screenshots folder, so it runs as a dry run and confirms before any
change.

## Steps

1. Select with the host OS finder (same flags as `shots`).
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.ps1" <selection flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.sh" <selection flags>`
2. Determine the operation from the arguments:
   - **rename** -> propose a meaningful name per file from what it shows (Read each image first), keeping the extension and avoiding collisions.
   - **delete** -> the selected files.
   - **archive / move** -> to a destination folder (resolve like the save outbox if none is given).
3. ALWAYS print the planned actions first (old -> new, or the delete/move list) and ask for confirmation. Nothing changes until the user confirms - this is a dry run by default.
4. On confirmation, perform it (`Rename-Item` / `Remove-Item` / `Move-Item`, or `mv` / `rm` / `mv`). Prefer the recycle bin / an archive folder over a hard delete; do not hard-delete without an explicit ask.
5. Report exactly what changed (counts + paths).

## Notes

- MUTATES the source folder. Dry run + explicit confirmation are required before any delete / rename / move.
- When "clean up" is vague, prefer archiving to a folder over deleting.
