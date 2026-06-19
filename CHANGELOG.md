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
- `screenshots` pack v0.1.0 with the `shots` rune: pulls recent screenshots
  (last N, or within the last X minutes) from the auto-detected Windows
  Screenshots folder (+ OneDrive-redirected variants) and answers questions
  about them.
- `shots` selection extended: `today` / `yesterday` / `since` / `until` / `name`
  (filename contains), combinable with `count` / `minutes` / `dir`.
- `screenshots` runes `shots-save` (copy a selected set to a folder) and
  `shots-tidy` (rename / delete / archive selected screenshots in place, dry-run
  + confirm). Default save outbox: `$RUNES_SAVE_DIR` else `~/Downloads/runes`.
- macOS/Linux backends (`clipboard-io.sh`, `recent-shots.sh`) so the runes work
  cross-platform (pbpaste/pngpaste on macOS; xclip/xsel or wl-clipboard on
  Linux; macOS/Linux Screenshots-folder detection). SKILLs select the backend by
  OS; `validate.ps1` adds `bash -n` of the shell scripts. Windows remains the
  verified path; the shell backends need verification on macOS/Linux.
