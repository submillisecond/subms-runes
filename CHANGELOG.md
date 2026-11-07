# Changelog

All notable changes to this repository are documented here. Per-pack releases
also appear as GitHub Releases (tag `<pack>--vX.Y.Z`). Format follows
[Keep a Changelog](https://keepachangelog.com/); packs use semver.

## [Unreleased]

### Changed

- `deltalab` skill: a session asked to draw a diagram loaded this skill (the request said deltalab) and asked the user to create and share a board, because nothing here said a diagram needs no room. The description now says a standalone diagram or picture is not this skill's job, and the body opens with where to go instead: the deltagraph pack (hosted MCP, `dg-url`, the `#dsl=` link and `/png?dsl=` picture) or deltadraw for pictures, with a by-hand fallback when neither is installed. Share links in the description now include `/join/#/room/...`.
- `deltalab` contract: `move_diagram` and the `diagram` argument were in the client but missing from CONTRACTS.md, which the contract test caught against the live client.
- `deltalab` skill and contract: `rich_table`, the `cell`, `chart` and `run` board actions, and `deltalab_read`'s `within` and `picture`.
- README: an agents section on the runner's responsibility, linking the deltalab terms (section 7) and privacy page.

- `deltalab` contract: boards' newer content is described and reachable. `deltalab_read` shows a sheet's name and formula values, a coding workspace's files and last output, a drawing's stroke count and a linked file; `shape` adds `workspace` and named, grid-sized `table` sheets; a new `write_file` action writes a workspace file; `set_diagram` takes mermaid state, sequence, ER and class diagrams; `deltalab_draw` paints drawings on a board (`ref`, `x`, `y`, `w`). `set_text` refuses workspaces, drawings and linked files with the right tool to use. Ships in the signed client, so CONTRACTS.md and the client deploy land together; required arguments are unchanged.
- `deltalab` skill and SPEC: drawings were listed as unsupported while `deltalab_draw` existed; both now list drawings, spreadsheets, workspaces and linked files by kind.
- `deltagraph` skill: `classDiagram` moves from the not-drawn list to the supported kinds, matching the engine (UML compartments, relationship ends, cardinalities, namespaces, notes). The hosted MCP serves the engine's generated spec, so it reflects the change once the deltagraph worker is deployed; no script or contract changed.
- `deltalab` loader: knows its own pack version (`PACK_VERSION`, held equal to `plugin.json` by the contract test, now 91 checks) and, when the signed manifest names a newer pack, logs the update commands to stderr and hands both versions to the client, which asks the model to pass the commands to the user. Loaders before 0.4.0 carry no such check; their users need the one manual update below.
- `deltalab` contract: `deltalab_inbox` marks what it returns as seen (people see "Seen by <agent>"), and an asked message it has not returned within 2 minutes shows the agent as away. Ships in the signed client; the pack is unchanged.
- `deltalab` 0.4.0: the pack no longer carries the deltalab client. `server/deltalab-mcp.mjs` is a dependency-free loader that fetches the client from `https://deltalab.submillisecond.com/runes/deltalab/` at each start, checks the Ed25519 signature on its manifest against the public key built into the loader, checks the client's size and SHA-256 against the manifest, refuses a client older than the loader's minimum build date, and runs it from memory, naming the build and the deltalab deploy it came from on stderr. Nothing is written to disk unless `DELTALAB_CLIENT_CACHE` asks for a verified offline copy. The share key still never leaves the machine, because the client still runs there. This keeps proprietary subms-ui code out of the public pack. The skill's frontmatter version had been left at 0.2.0 under a 0.3.0 pack, which the release check rejects; both are 0.4.0.
- `deltalab` contract: `deltalab_draw` and the board actions `image`, `card`, `frame`, `shape`, `embed`, `connect`, `link`, `delete` and `check` are documented; the client had them and the contract had drifted behind the old bundle. CONTRACTS.md, SPEC.md, SPEC-TEMPLATE.md, plugin and marketplace descriptions and contract-test.sh swept together; 90 checks, including a changed client and a changed manifest both refused.
- The deltagraph and deltadraw runes are cast as `/deltagraph` and `/deltadraw` (were `/dg` and `/dd`), matching `/deltalab`: two-letter names said nothing and `dd` is a Unix command. Skill folders, `name:`, headings, trigger lists, descriptions, contract tests and README follow; the `dg-url` / `dd-png` / `dd-gif` scripts keep their names. After updating the packs, `/dg` and `/dd` no longer exist.
- clipboard and imageverse are held back from the marketplace until they are ready to ship: removed from `marketplace.json`, code kept, and an `UNLISTED` file in each pack says why. `validate.sh` accepts an unlisted pack on disk and fails one that is both marked `UNLISTED` and listed. The README and install examples now lead with deltagraph.

### Added

- `deltalab` skill: "Writing in the room": plain English, one point per message in two or three sentences, no praise, thanks, sign-offs or self-introductions, work shared only through the room (viewer links, the board, the document) and never as a file on disk, even between agents on the same machine, confirm work is final before building on it, and no repeat paints. Taken from the messages of a two-agent session (900-1200 character messages, compliments, closing rituals, an assembly from a stale file). The bundled server's instructions say the same; the contract test checks it (72 checks).
- `deltagraph` and `deltadraw` packs: the viewers moved to `https://deltagraph.submillisecond.com/` and `https://deltadraw.submillisecond.com/`. `dg-url` / `dd-url` (both backends) default to the new base, the skills, SPECs, CONTRACTS, live tests and plugin descriptions say so, and the contract tests check the new form (106 and 101 checks, all passing). Old `www.submillisecond.com/deltagraph#...` links still open: www redirects with the fragment. The `deltalab` bundle is rebuilt for its new deltagraph link (70 checks passing). Pack versions move with the next release.
- `deltalab` 0.3.0: the room's chat is a first-class surface. Inbox lines say who a message was for (`to you`, `to every agent`, `to everyone`, `to @Handle`, `open, no tag`) after the unchanged `[rN mK] author` prefix; text documents' chat and comment replies now arrive; new tool `deltalab_say` posts in the chat; agents are named `Agent-Smith-<X>` and tagged as `@Agent-Smith-B`, every agent as `@Agent-Smith-All` or `@agents`, everyone as `@all`. CONTRACTS.md, SKILL.md, SPEC.md and contract-test.sh swept together; bundle rebuilt.
- `deltalab` skill: a new step, agree the plan in the room (say what you intend in the board discussion or a reply, ask for objections, disagree with a reason and a proposal, settle who takes which part with other agents, then work in small steps), and a "By kind of file" section for boards, text documents, code files, and the kinds the tools do not work in. The bundled server is rebuilt with the matching `initialize` instructions; the contract test checks both new rules are in them (65 checks, all passing). SPEC records that the skill restates the server's guidance and names the supported kinds.
- `deltadraw` `dd` skill: PNG and GIF renders now embed the serif, mono and hand faces plus italics, so the note that they drew everything as Inter is replaced with the one remaining gap (hand text has no bold or italic in a PNG).
- `deltalab` `plugin.json` licence is `MIT`, matching the repo `LICENSE` and README; it said `MIT OR Apache-2.0` with no Apache text in the repo.
- `deltalab` `plugin.json` carries `privacyPolicyUrl` (https://www.submillisecond.com/deltalab/privacy), which the other hosted-service packs already had.
- README pack rows for `dg`, `dd` and `deltalab` cut to what each does; the install line names every pack instead of clipboard and imageverse only. CONTRIBUTING's lifecycle lost its bold step labels, the "AISkill-DLC" name and the emoji copied from the release workflow's title.
- `deltadraw` 1.1.0: `dd-gif` (both backends) saves an animated GIF from the worker's `/gif` (`--mode pages|replay`, `--width`); `dd-png` takes `--page` / `-Page` for one frame of an animation. The `dd` skill documents the animation grammar (`page`, `tween`, `id`, `allframes`), text styles and `deltadraw_gif`. Contract test 101 checks, all passing; the live test gains a page render and a GIF.
- `deltadraw` 1.0.0, rune `dd`: draw a picture as a `submillisecond.com/deltadraw` URL. Installs the hosted deltadraw MCP server (check, url, png, svg, pack, to_scene, symbols, spec; prompts draw, refine). `dd-url` builds the link offline and `dd-png` fetches the picture over HTTP, in .ps1 and .sh, both held by the contract test (79 checks). The nightly live test applies once `deltadraw.submillisecond.com` is deployed.
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

- `deltalab`: the bundled server carries no diagram engine; `set_diagram`, `edit_diagram`, `relayout` and reading the diagram go to the deltagraph worker (`POST /board`, `DELTALAB_DG_HOST`), so those tools need the network. Bundle 545 KB to 348 KB. CONTRACTS.md and SPEC.md say so (73 checks).
- `deltalab`: agents are `agent-valkyrie-<rune>` (40 runes, then `-2`), tagged together as `@agent-valkyrie-all` or `@agents`; `@Agent-Smith-All` still reaches every agent. CONTRACTS.md, SKILL.md, plugin description, contract test and bundled server swept together (73 checks).
- The `dg` rune's loop is now check, look at the PNG, debug when it fails or
  reads badly, then link. The skill documents every script option, and the
  contract test fails when it does not; 0.1.0 described `&bg=` while neither
  script accepted it.
- Script comments cut to at most two lines each (1,143 lines out, 376 in). Headers that restated a pack's verbs, store and output now point at `CONTRACTS.md`, which ADR-0001 makes the one source; scripts the contract does not cover keep a one-line usage.

### Fixed

- `deltalab`: another agent's message now reaches `deltalab_inbox` when it tags this agent by name; open and group-tagged agent talk is still held back, and people's messages reach every agent as before. Before, agents never received each other's messages. CONTRACTS.md, SKILL.md, SPEC.md and the bundled server's instructions swept together; contract test 71 checks, one new.
- `deltagraph` live test fetched `//skill.md` from the viewer host and failed: the new `VIEWER` base ends in `/`, the old www path did not. It now joins without the extra slash; 22 checks pass against the hosted worker.
- `secret-scan.ps1 -Redact` leaked part of a secret when text held two kinds: matches were found in the original text but cut from a copy earlier replacements had already resized, so later cuts landed at the wrong offset. Spans are now merged and cut right to left.
- `secret-scan.sh --redact` used `sed -i -E ... gI`, which BSD sed reads as a backup suffix and an unknown flag, and `|| true` hid the failure, so on macOS the redacted copy kept its secrets. It now uses perl, and a failed rewrite blanks the copy.
