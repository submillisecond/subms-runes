# <img src="https://www.submillisecond.com/products/icons/subms-runes.svg" width="40" height="40" alt=""> subms-runes

<!-- badges:start -->
[![checks](https://img.shields.io/github/actions/workflow/status/submillisecond/subms-runes/release.yml?branch=main&label=checks&labelColor=0d1117)](https://github.com/submillisecond/subms-runes/actions/workflows/release.yml)
[![live](https://img.shields.io/github/actions/workflow/status/submillisecond/subms-runes/live.yml?branch=main&label=live%20engine&labelColor=0d1117)](https://github.com/submillisecond/subms-runes/actions/workflows/live.yml)
![packs](https://img.shields.io/badge/packs-6-1f6feb?labelColor=0d1117)
![runes](https://img.shields.io/badge/runes-18-1f6feb?labelColor=0d1117)
![licence](https://img.shields.io/badge/licence-MIT-9d2235?labelColor=0d1117)
<!-- badges:end -->

Claude Code plugins from submillisecond. Each plugin is a pack: a skill that tells
the agent how to do one job, and usually the MCP server it does the job with. The
three that are live draw diagrams (deltagraph) and pictures (deltadraw) as links,
and put an agent in a live DeltaLab document or board (deltalab).

## Install

With the `claude` CLI on your PATH:

```bash
claude plugin marketplace add submillisecond/subms-runes
claude plugin install subms-runes@subms-runes  # deltagraph, deltadraw and deltalab
```

The `subms-runes` bundle has nothing of its own. It installs the three packs, and
each keeps its own version. To take one pack only, install it by name, for example
`claude plugin install deltagraph@subms-runes`.

Then turn on auto-update once: in Claude Code, `/plugin`, Marketplaces,
`subms-runes`, Enable auto-update. Claude Code leaves it off for third-party
marketplaces and no plugin can switch it on for you. Without it, Update marketplace
on the same screen updates every installed pack, or from a terminal:

```bash
claude plugin marketplace update subms-runes   # refreshes the catalog only
claude plugin update deltalab@subms-runes      # then each pack you have
```

A pack that falls behind keeps working for the most part. The deltalab pack
fetches its client at every start and the DeltaGraph and DeltaDraw engines are
hosted, so only the skill text and the deltalab loader wait for an update. When one is behind, its
server tells you through the agent and gives these steps.

A team can switch auto-update on for everyone in the project's
`.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "subms-runes": { "source": { "source": "github", "repo": "submillisecond/subms-runes" }, "autoUpdate": true }
  },
  "enabledPlugins": { "subms-runes@subms-runes": true }
}
```

Restart Claude Code and ask for something: "draw how an order flows through our
gateway as a diagram", or paste a DeltaLab share link and ask the agent to join.

## Packs

Packs keep context small. A flat pile of 30 skills would put every description in
every session; a pack loads only when you install it.

<!-- inventory:start -->
| Pack | Version | Runes | Runs on | Tests |
|---|---|---|---|---|
| `clipboard` (unlisted, not released yet) | 0.1.0 | `/clip` `/clip-copy` `/clip-edit` `/clip-history` `/clip-ocr` `/clip-save` `/clip-snippet` | Windows (4 .ps1), macOS + Linux (4 .sh) | contract, functional |
| `deltadraw` | 1.1.0 | `/deltadraw` | Windows (3 .ps1), macOS + Linux (3 .sh), hosted MCP | contract, live nightly |
| `deltagraph` | 1.0.0 | `/deltagraph` | Windows (2 .ps1), macOS + Linux (2 .sh), hosted MCP | contract, live nightly |
| `deltalab` | 0.5.1 | `/deltalab` | local MCP (Node 22) | contract |
| `imageverse` (unlisted, not released yet) | 0.1.0 | `/img` `/img-dedup` `/img-edit` `/img-montage` `/img-organize` `/img-save` `/img-search` `/img-settings` | Windows (17 .ps1), macOS + Linux (17 .sh) | contract, functional |
| `subms-runes` | 1.0.0 | bundle: installs deltagraph, deltadraw, deltalab | - | - |
<!-- inventory:end -->

clipboard and imageverse are held back until they are ready. Their code is here,
but `claude plugin install` does not offer them; an `UNLISTED` file in a pack's
folder holds it back, and CI checks that against `marketplace.json`.

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
| <img src="https://www.submillisecond.com/products/icons/deltagraph.svg" width="20" height="20" alt=""> `deltagraph` | `deltagraph` | Hand over a diagram as a `deltagraph.submillisecond.com` link instead of a Mermaid fence; the source rides in the URL fragment. The hosted MCP server checks, renders and debugs it first. Offline, `dg-url` builds the link and `dg-debug` calls the debugger over HTTP. |
| <img src="https://www.submillisecond.com/products/icons/deltadraw.svg" width="20" height="20" alt=""> `deltadraw` | `deltadraw` | Hand over a picture (a scene, an illustration, a sketch) as a `deltadraw.submillisecond.com` link that also opens in DeltaLab as a painting. The hosted MCP server compiles it and returns a PNG to look at first. Offline, `dd-url` builds the link and `dd-png` fetches the picture. |
| <img src="https://www.submillisecond.com/products/icons/subms-runes.svg" width="20" height="20" alt=""> `subms-runes` | - | A bundle: installs `deltagraph`, `deltadraw` and `deltalab` in one step. No skills or servers of its own. |
| <img src="https://www.submillisecond.com/products/icons/deltalab.svg" width="20" height="20" alt=""> `deltalab` | `deltalab` | Join a live DeltaLab document or board from a share link and work beside the people there: write, suggest changes in Review, add stickies, votes and comments, edit the board diagram, answer messages. A local MCP server; the share key stays on the machine. |

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
| `validate` | pull requests | structure, ASCII, inventory; PowerShell functional tests; contract tests with both backends on Windows and the `.sh` backends on Ubuntu; `claude plugin validate` |
| `live` | nightly | packs that call a hosted service check it still serves what their skills name |

Run any of it locally: `bash .github/scripts/contracts.sh` (add `--live` for the hosted checks), `bash .github/scripts/inventory.sh`.

## Agents in DeltaLab rooms

The `deltalab` pack puts an agent you run into a shared room, beside other people
and their agents. You run it, on your machine, with your AI provider, so what it
does in the room is your responsibility, and so is what you let it touch on your
machine and what your provider does with the room content it reads.

An agent can be wrong. With edit access it can change or delete what is in a room,
post messages and pictures, and ask for code to run in the browser of someone in
the room. Anyone in the room can write instructions it may follow, including ones
meant to misuse it; the pack's rules guide the model and guarantee nothing. Its
diagram, drawing and board-picture actions send the board's content to the
DeltaGraph and DeltaDraw services, unencrypted, to be drawn.

The packs come as is, with no warranty and no liability, under the licence below.
The [DeltaLab terms](https://deltalab.submillisecond.com/terms) (section 7) and
[privacy page](https://www.submillisecond.com/deltalab/privacy) also apply.

## Licence

MIT. See [LICENSE](LICENSE).
