# Changelog

All notable changes to this repository are documented here. Per-pack releases
also appear as GitHub Releases (tag `<pack>--vX.Y.Z`). Format follows
[Keep a Changelog](https://keepachangelog.com/); packs use semver.

## [Unreleased]

### Added

- `subms-runes` marketplace scaffolding: 3-tier layout (marketplace -> pack ->
  rune), `scripts/runes.ps1` management dispatcher (+ `runes.bat`, `deploy.bat`,
  `update.bat`), `scripts/validate.ps1`, and `validate` / `release` CI workflows.
- `clipboard` pack v0.1.0 with three runes over a shared
  `scripts/clipboard-io.ps1` (read + write):
  - `clip` - read the clipboard (text, image/screenshot, or copied files) and answer questions about it.
  - `clip-edit` - transform the clipboard text and write the result back, paste-ready (reformat, to-table, redact, translate, tighten, fix code).
  - `clip-save` - save the clipboard (text / image / files) to a file or folder on disk.
- `images` pack v0.1.0 (one pack for image files in a folder - merges the earlier
  screenshots + photo-library ideas) with four runes over shared
  `recent-shots.{ps1,sh}` (recent / `--dir` selection: count / minutes / today /
  yesterday / since / until / name) and `photo-scan.{ps1,sh}` (EXIF
  `DateTimeOriginal` -> file-time fallback, optional SHA1):
  - `ask` - questions about recent screenshots or any folder of images.
  - `save` - copy a selected set of images to a folder (outbox: `$RUNES_SAVE_DIR` else `~/Downloads/runes`).
  - `organize` - restructure (year/month, content albums) / rename / archive / delete images in a folder, in place; move default or `--copy`; dry-run + confirm.
  - `dedup` - find exact-duplicate images by SHA1 and remove/archive the extras, keeping one.
- macOS/Linux backends (`clipboard-io.sh`, `recent-shots.sh`, `photo-scan.sh`) so the runes work
  cross-platform (pbpaste/pngpaste on macOS; xclip/xsel or wl-clipboard on
  Linux; macOS/Linux Screenshots-folder detection). SKILLs select the backend by
  OS; `validate.ps1` adds `bash -n` of the shell scripts. Windows remains the
  verified path; the shell backends need verification on macOS/Linux.
