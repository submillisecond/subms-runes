---
name: organize
description: This skill should be used when the user asks to "/organize", "organize my photos by year/month", "sort this folder into albums", "rename my last N screenshots by content", "delete screenshots older than X days", "archive last week's screenshots to <folder>", "tidy up my phone photo dump", or otherwise wants images in a folder restructured, renamed, archived, or deleted in place.
version: 0.1.0
---

# organize - restructure / rename / archive / delete images in place

The single in-place curator for an image folder. The operation is whatever the
arguments ask for:
- **structure** -> sort into `YYYY/MM` (EXIF date, file-time fallback) and/or content **albums** (decided by looking at the images).
- **rename** -> by content (what each image shows), keeping extensions.
- **archive / move** -> selected images to a destination folder.
- **delete** -> selected images.

Source is any `--dir` (a phone dump, the Screenshots folder, anywhere); for
screenshot-style requests the recent-selection flags work too. This MUTATES the
folder, so it runs as a dry run and confirms before any change.

## Steps

1. Pick the scan that fits the job (Windows `powershell.exe ... -File "${CLAUDE_PLUGIN_ROOT}/scripts/<script>"`; macOS/Linux `bash "${CLAUDE_PLUGIN_ROOT}/scripts/<script>"`):
   - structure / dates: `photo-scan.ps1 -Dir "<folder>" [-Recurse]` (`.sh`: `--dir` / `--recurse`) - gives `<date>\t<size>\t<hash>\t<path>`.
   - selection for rename/delete/archive of recent screenshots: `recent-shots.ps1 <flags>` (count / today / since / name / dir).
2. Determine the operation from the arguments (structure / rename / archive / delete). For albums or content-rename, Read a sample of the images to learn categories / names, reading more as needed.
3. Show a DRY-RUN SUMMARY and ask for confirmation: counts per target bucket (e.g. `2024/03 -> 412`), or the rename/delete/move list as `old -> new`. Summarize for large sets - do not print thousands of lines. Collision-safe: append ` (2)`, ` (3)`; never overwrite.
4. On confirmation, perform it: MOVE into the structure by default (`Move-Item` / `mv`), or `--copy` to duplicate; `Rename-Item` / `Remove-Item` / `Move-Item` (or `mv` / `rm` / `mv`) for rename / delete / archive. Prefer recycle bin / an archive folder over a hard delete; never hard-delete without an explicit ask.
5. Report exactly what changed (counts + paths), and the folder's new shape.

## Notes

- MUTATES the folder. Dry-run + explicit confirmation are required for any move / rename / delete. `--copy` preserves originals when structuring.
- EXIF-first dates, file-time fallback (HEIC without readable EXIF uses file time). Non-image files are ignored. Never overwrite.
- Large libraries: summarize buckets, work in batches, report progress.
