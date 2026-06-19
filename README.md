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
| `images` | `ask` | Questions about recent screenshots (last N / today / since / name) or any `--dir` of images. |
| | `save` | Copy a selected set of images to a folder (bug-report bundle / share set). |
| | `organize` | Restructure (year/month, albums) / rename / archive / delete images in a folder, in place (dry-run + confirm; `--copy`). |
| | `dedup` | Find exact-duplicate images and remove/archive the extras, keeping one (dry-run + confirm). |

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

## Install

Windows, with the `claude` CLI on PATH:

```bat
scripts\deploy.bat            :: installs all packs (official, from GitHub)
scripts\runes.bat deploy clipboard   :: or a single pack
```

Restart the Claude Code session, then use a rune, e.g.:

```
/clip summarize what I copied
/clip-edit reformat this as pretty JSON
/clip-save stash this screenshot as notes/shot.png
```

Before the first GitHub push, bootstrap from the working tree:
`scripts\runes.bat deploy -Local`.

## Develop

```bat
scripts\runes.bat dev clipboard     :: live-load the pack (edits reflected, no install)
scripts\runes.bat test clipboard clip   :: run the rune's capture script standalone
scripts\runes.bat validate          :: structural checks (same as CI)
scripts\runes.bat status            :: working-tree vs installed version per pack
```

Run `scripts\runes.bat` with no arguments for the full command list. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the skill development lifecycle and how to
add a rune or a pack.

## Licence

MIT. See [LICENSE](LICENSE).
