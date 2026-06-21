# Changelog

All notable changes to this repository are documented here. Per-pack releases
also appear as GitHub Releases (tag `<pack>--vX.Y.Z`). Format follows
[Keep a Changelog](https://keepachangelog.com/); packs use semver.

## [Unreleased]

### Added

- `subms-runes` marketplace scaffolding: 3-tier layout (marketplace -> pack ->
  rune), `.github/scripts/validate.sh` CI structural checks (bash + jq), and
  `validate` / `release` CI workflows. The operator dispatcher (`runes` - deploy
  / status / dev / validate / etc.) lives in the `subms-infra` repo at
  `automation/runes/` and folds the same checks in for `runes validate`.
- `clipboard` pack v0.1.0 with three runes over a shared
  `scripts/clipboard-io.ps1` (read + write):
  - `clip` - read the clipboard (text, image/screenshot, or copied files) and answer questions about it.
  - `clip-edit` - transform the clipboard text and write the result back, paste-ready (reformat, to-table, redact, translate, tighten, fix code).
  - `clip-save` - save the clipboard (text / image / files) to a file or folder on disk.
- `imageverse` pack v0.1.0 (the image organiser - any folder of images, not just
  screenshots) with five runes over shared scripts: `image-find` (find image
  files: recency/name/recurse + EXIF/mtime dates + optional SHA1; merges the
  former recent-shots + photo-scan), `thumbs` (downscale for cheap vision reads),
  `build-manifest` (classification -> move/copy plan), `file-ops` (apply/restore
  with a durable revert journal), `workspace` (per-run temp), `prefs` (remember a
  folder's scheme), `journal` (history + undo). Per-plugin temp/app-data under
  `runes/imageverse/`:
  - `img` - questions about recent screenshots or any folder of images.
  - `img-edit` - edit an image into a new file (crop / resize / redact / box / text / rotate / flip / grayscale / convert); deterministic, not generative. Windows `System.Drawing`, macOS `sips`, ImageMagick for draw ops + Linux.
  - `img-save` - copy a selected set of images to a folder (outbox: `$RUNES_SAVE_DIR` else `~/Downloads/runes`).
  - `img-organize` - restructure (content albums / `yyyy/mm` / nested / flat) / rename / archive / delete, in place; thumbnail-first parallel classification; remembers the per-folder scheme; durable journal so any run is undoable + redoable; dry-run + confirm.
  - `img-dedup` - find exact-duplicate images by SHA1 and remove/archive the extras, keeping one.
- macOS/Linux backends (`clipboard-io.sh`, `image-find.sh`, and the imageverse
  script set) so the runes work cross-platform (pbpaste/pngpaste on macOS;
  xclip/xsel or wl-clipboard on Linux; macOS/Linux Screenshots-folder detection).
  SKILLs select the backend by OS; `.github/scripts/validate.sh` adds `bash -n` of
  the shell scripts. Windows remains the verified path; the shell backends need
  verification on macOS/Linux.
