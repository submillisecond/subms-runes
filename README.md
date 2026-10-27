# subms-runes

A Claude Code skill marketplace. Each plugin is a themed pack; each skill is a
rune you cast.

```
marketplace  subms-runes        (this repo)
  -> plugin  <pack>             (a themed group: clipboard, ...)
       -> skill <rune>          (e.g. clip)
```

Skills are grouped into packs so you install only what you use - a flat pile of
20-50 skills would load every description into context permanently.

## Packs

| Pack | Rune | What |
|---|---|---|
| `clipboard` | `clip` | Ask questions about whatever is on your clipboard - text, an image/screenshot, or copied files. |
| | `clip-edit` | Transform the clipboard text and write it back, paste-ready - reformat, to-table, redact, translate, tighten, fix code. |
| | `clip-save` | Save the clipboard (text / image / files) to a file or folder on disk. |
| `imageverse` | `img` | Questions about recent screenshots (last N / today / since / name) or any `--dir` of images. |
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

## Licence

MIT. See [LICENSE](LICENSE).
