# Changelog

All notable changes to this repository are documented here. Per-pack releases
also appear as GitHub Releases (tag `<pack>--vX.Y.Z`). Format follows
[Keep a Changelog](https://keepachangelog.com/); packs use semver.

## [Unreleased]

### Added

- `deltalab` names a share that is full (200 people, close 4010) in `deltalab_status`.
- `deltalab` 0.2.0: `deltalab_board` gains `move` (ref, x, y) and `resize` (ref, w, h), and `sticky` takes `x`/`y`. A sticky with no placement now lands in two columns right of the board's content; below it, the notes ended up under the diagram the next time it grew.
- `deltalab_join` takes a code in either field and refuses a document key (`f_...`) by name, saying to ask for the code or the full link. A session lost three round trips to a pasted document key.
- The `deltalab` skill joins on whatever the user pasted ("join deltalab <code>", a bare code) and asks only when the tool refuses, tells the user at once when the agent is waiting in the lobby, and has a "Laying out a board" section: the engine stacks subgraphs in bands, side-by-side sections are `@(x,y)` positions, `relayout` drops them, equal-width bands are spread arithmetic, and a render is checked before a layout is called done. A worked section covers iterating a diagram live with the room: join by code, first draft as top-down bands, own the DSL file (the board copy flattens `<br/>`), one edit per request, positions once layout matters, user names replace generic ones, stickies beside.
- The `dg` skill documents `direction: auto`, which asks the engine to keep whichever direction scores better.
- `deltagraph` 1.0.0: the scripts, their output and the MCP tool names the skill relies on are now a stable contract, held by the offline contract test on every push and the live test every night. `plugin.json` carries `privacyPolicyUrl` (https://www.submillisecond.com/deltagraph/privacy). The other packs stay 0.x until their macOS and Linux backends are verified.
- The `deltagraph` plugin sends `X-Runes-Pack: deltagraph/<version>` to the hosted server, which tells users of an outdated copy to run `/plugin marketplace update subms-runes`. The release script moves the header with the version and the contract test fails if they differ.
- Every push to main runs the full check suite before `release` tags a pack; tags were cut after the structure check alone, even when a contract test failed.
- Contract tests are found by glob (`.github/scripts/contracts.sh`), so a new pack's test runs with no CI edit. The deltagraph test ran nowhere for a day because the list was hand-kept.
- The `.sh` backends run on Ubuntu; they had only ever run under Git Bash on Windows. macOS is not in CI: its first runs passed, then a GitHub macOS runner shortage held a release for 15 minutes and blocked tagging.
- `claude plugin validate` runs on the marketplace and every pack, and an ASCII check covers scripts, contracts and manifests.
- Nightly `live` workflow: `plugins/deltagraph/contract/live-test.sh` checks the hosted engine still serves every tool the pack names and renders the links `dg-url` builds.
- README badges and a generated inventory of packs, runes, backends and tests (`.github/scripts/inventory.sh`); CI fails when it is stale or a rune is missing from the Packs table, which was missing 7 of 17.
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
- Script comments cut to at most two lines each (1,143 lines out, 376 in). Headers that restated a pack's verbs, store and output now point at `CONTRACTS.md`, which ADR-0001 makes the one source; scripts the contract does not cover keep a one-line usage.

### Fixed

- `secret-scan.ps1 -Redact` leaked part of a secret when text held two kinds: matches were found in the original text but cut from a copy earlier replacements had already resized, so later cuts landed at the wrong offset. Spans are now merged and cut right to left.
- `secret-scan.sh --redact` used `sed -i -E ... gI`, which BSD sed reads as a backup suffix and an unknown flag, and `|| true` hid the failure, so on macOS the redacted copy kept its secrets. It now uses perl, and a failed rewrite blanks the copy.
