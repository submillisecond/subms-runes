# subms-runes

<!-- badges:start -->
[![checks](https://img.shields.io/github/actions/workflow/status/submillisecond/subms-runes/release.yml?branch=main&label=checks&labelColor=0d1117)](https://github.com/submillisecond/subms-runes/actions/workflows/release.yml)
[![live](https://img.shields.io/github/actions/workflow/status/submillisecond/subms-runes/live.yml?branch=main&label=live%20engine&labelColor=0d1117)](https://github.com/submillisecond/subms-runes/actions/workflows/live.yml)
![packs](https://img.shields.io/badge/packs-4-1f6feb?labelColor=0d1117)
![runes](https://img.shields.io/badge/runes-17-1f6feb?labelColor=0d1117)
![licence](https://img.shields.io/badge/licence-MIT-9d2235?labelColor=0d1117)
<!-- badges:end -->

A Claude Code skill marketplace. Each plugin is a themed pack; each skill is a
rune you cast.

```
marketplace  subms-runes        (this repo)
  -> plugin  <pack>             (a themed group: clipboard, ...)
       -> skill <rune>          (e.g. clip)
```

Skills are grouped into packs so you install only what you use - a flat pile of
20-50 skills would load every description into context permanently.

## Inventory

Generated from `plugins/` by `.github/scripts/inventory.sh`; CI fails when it is stale.

<!-- inventory:start -->
| Pack | Version | Runes | Runs on | Tests |
|---|---|---|---|---|
| `clipboard` | 0.1.0 | `/clip` `/clip-copy` `/clip-edit` `/clip-history` `/clip-ocr` `/clip-save` `/clip-snippet` | Windows (4 .ps1), macOS + Linux (4 .sh) | contract, functional |
| `deltagraph` | 0.2.0 | `/dg` | Windows (2 .ps1), macOS + Linux (2 .sh), hosted MCP | contract, live nightly |
| `deltalab` | 0.1.0 | `/deltalab` | local MCP (Node 22) | contract |
| `imageverse` | 0.1.0 | `/img` `/img-dedup` `/img-edit` `/img-montage` `/img-organize` `/img-save` `/img-search` `/img-settings` | Windows (17 .ps1), macOS + Linux (17 .sh) | contract, functional |
<!-- inventory:end -->

## Packs

| Pack | Rune | What |
|---|---|---|
| `clipboard` | `clip` | Ask questions about whatever is on your clipboard - text, an image/screenshot, or copied files. |
| | `clip-copy` | Put a clean piece of the last answer on the clipboard: the code, the command, a URL, or the answer as plain text. |
| | `clip-edit` | Transform the clipboard text and write it back, paste-ready - reformat, to-table, redact, translate, tighten, fix code. |
| | `clip-history` | Opt-in, searchable history of what you copied; recall an entry back onto the clipboard. |
| | `clip-ocr` | Transcribe the text in a clipboard image, an attachment or an image path; copy or save only when asked. |
| | `clip-save` | Save the clipboard (text / image / files) to a file or folder on disk. |
| | `clip-snippet` | Named, reusable snippets (text or image) you save once and paste back by name. |
| `imageverse` | `img` | Questions about recent screenshots (last N / today / since / name) or any `--dir` of images. |
| | `img-search` | Search a folder of images by what they show and by date, place or size, from a cached index. |
| | `img-montage` | One deduplicated contact sheet of an album or folder, so a 100-image album fits on a page or two. |
| | `img-settings` | View or change imageverse settings: home location, people and objects to recognise, defaults. |
| | `img-edit` | Edit an image into a new file: crop / resize / redact / annotate / rotate / flip / grayscale / convert (deterministic, not generative). |
| | `img-save` | Copy a selected set of images to a folder (bug-report bundle / share set). |
| | `img-organize` | Restructure (year/month, albums) / rename / archive / delete images in a folder, in place (dry-run + confirm; `--copy`). |
| | `img-dedup` | Find exact-duplicate images and remove/archive the extras, keeping one (dry-run + confirm). |
| `deltagraph` | `dg` | Draw any diagram as a `submillisecond.com/deltagraph` URL instead of a mermaid fence - the source rides in the URL fragment and the viewer lays it out. Installs the hosted deltagraph MCP server (check, debug, png, url, edit, diff, merge and more), so a diagram is checked and looked at before it is handed over, and a broken or tangled one is debugged to the line and rule. Without MCP, `dg-url` encodes a source file offline and `dg-debug` reaches the debugger over HTTP; the generated spec at `/deltagraph/spec.md` is the grammar. |
| `deltalab` | `deltalab` | Join a live deltalab document or board from a share link and work in it beside the people there: read, write a section, suggest changes in Review, stickies / votes / comments / the diagram on a board, and reply to what people write to the agent. A local MCP server; the share key never leaves the machine. |

## Platforms

Windows is the verified path (PowerShell, built-in clipboard + Screenshots
folder). macOS and Linux backends ship alongside (`*.sh`) and the runes pick the
right one by OS, but they need verification on those systems and these tools:

| OS | clipboard text | clipboard image | screenshots folder |
|---|---|---|---|
| Windows | built in | built in | built in |
| macOS | `pbpaste`/`pbcopy` | `pngpaste` (brew) | `screencapture` location / `~/Desktop` |
| Linux (X11) | `xclip`/`xsel` | `xclip` | `~/Pictures[/Screenshots]`, `$XDG_PICTURES_DIR` |
| Linux (Wayland) | `wl-clipboard` | `wl-clipboard` | same |

Clipboard file-lists are Windows + Linux (uri-list) only; not macOS.

`img-edit` writes edited images with a built-in backend where possible: Windows
`System.Drawing`, macOS `sips` (resize/rotate/flip/convert). Its draw-based ops
(redact/box/text) and Linux use ImageMagick (`brew`/`apt install imagemagick`).

## Install

With the `claude` CLI on PATH:

```bash
claude plugin marketplace add submillisecond/subms-runes
claude plugin install clipboard@subms-runes   # and/or imageverse@subms-runes
```

Restart the Claude Code session, then use a rune, e.g.:

```
/clip summarize what I copied
/clip-edit reformat this as pretty JSON
/clip-save stash this screenshot as notes/shot.png
```

## Develop

The operator dispatcher `runes` (deploy / dev / status / validate / plugins /
release / ...) lives in the private `subms-infra` repo at `automation/runes/`
and drives this marketplace as a sibling under the umbrella. Run
`automation\runes\runes.bat` with a command, or with none in a terminal for an
interactive menu (`--help` or piped prints the command list):

```bat
runes dev clipboard         :: live-load the pack (edits reflected, no install)
runes test clipboard clip   :: run the rune's capture script standalone
runes validate              :: structural checks (CI runs .github/scripts/validate.sh)
runes status                :: marketplace source + per-pack install state + per-rune list
runes plugins               :: all Claude Code plugins on this machine + img-edit backend status
runes deploy -Local         :: install/refresh from the working tree (e.g. before the first push)
```

`status` shows whether the marketplace is wired to the local working tree or the
official GitHub source, each pack's installed version + commit, and every rune
under it. `deploy -Local` force-refreshes the install cache from the working
tree in one step (re-pointing the source if it was set to official). CI runs the
bash validator at `.github/scripts/validate.sh`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the skill development lifecycle and how to
add a rune or a pack.

## CI

| Workflow | When | Runs |
|---|---|---|
| `release` | every push to main | all of `validate`, then tags each pack at its `plugin.json` version |
| `validate` | pull requests | structure, ASCII, inventory; PowerShell functional tests; contract tests with both backends on Windows and the `.sh` backends on Ubuntu and macOS; `claude plugin validate` |
| `live` | nightly | packs that call a hosted service check it still serves what their skills name |

Run any of it locally: `bash .github/scripts/contracts.sh` (add `--live` for the hosted checks), `bash .github/scripts/inventory.sh`.

## Licence

MIT. See [LICENSE](LICENSE).
