# Changelog

All notable changes to this repository are documented here. Per-pack releases
also appear as GitHub Releases (tag `<pack>--vX.Y.Z`). Format follows
[Keep a Changelog](https://keepachangelog.com/); packs use semver.

## [Unreleased]

### Added

- `deltalab` pack v0.1.0 with one rune, `deltalab`: join a live deltalab document or board from a share link or code and work in it as a named robot participant. Its MCP server is bundled in the pack (`server/deltalab-mcp.mjs`, Node 22, nothing to install) and runs locally, because the link's fragment is the room key and the relay only ever sees ciphertext. Nine tools: join, status, read, write, suggest, board, inbox, reply, leave. A direct write is refused unless the agent may edit; in Review it suggests instead. The contract test starts the bundle and checks it against `CONTRACTS.md`.
- `deltagraph` pack v0.2.0 registers the hosted deltagraph MCP server in
  `.mcp.json`, so installing the pack gives the ten engine-backed tools
  (check, debug, url, svg, png, edit, diff, merge, from_code, spec) and the
  `draw`, `evolve` and `tidy` prompts with no `claude mcp add` step.
- `dg-debug.{ps1,sh}`: posts a source to the hosted `/debug` route and prints
  why it does not render or reads badly; exit 1 when it does not render,
  `--review` writes the diagram with its problems marked.
- `dg-url` takes `bg` (transparent, black, white, auto or a hex colour) and
  `compress`, which writes the shorter `#d1=` form the viewer reads.
- `deltagraph` pack v0.1.0 with one rune, `dg`: draw any diagram as a
  `submillisecond.com/deltagraph#dsl=` URL instead of a mermaid fence. The
  `scripts/dg-url.{ps1,sh}` encoder is hand-rolled over UTF-8 bytes so both
  backends print identical bytes (`[uri]::EscapeDataString` and `jq @uri`
  disagree on `! * ' ( )` across runtimes); the contract test asserts the
  parity, the round-trip decode, option order and the error paths. The grammar
  is NOT in the pack: it is generated from the engine in `subms-ui` and
  served at `/deltagraph/spec.md`, which the rune fetches when it needs more
  than the essentials it carries.
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

### Changed

- The `dg` rune's loop is now check, look at the PNG, debug when it fails or
  reads badly, then link. The skill documents every script option, and the
  contract test fails when it does not; 0.1.0 described `&bg=` while neither
  script accepted it.
