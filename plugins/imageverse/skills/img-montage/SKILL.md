---
name: img-montage
description: This skill should be used when the user asks to "/img-montage", "generate a montage for album <name>", "montage this folder <path>", "show me everything in <album> as one image", "make a contact sheet of <folder>", or otherwise wants a single compact overview image of what an album/folder contains. Builds a DEDUPED, densely-packed montage (one cell per distinct shot) so even a 100+ image album fits in a sheet or two.
version: 0.2.0
---

# img-montage - one compact picture of what's in an album / folder

Turns an album or any folder into a small set of **montage sheets** you can open at a
glance - to see what an album holds, or to match stray images to the album they
belong to. Smarter than a raw contact sheet:

- **Perceptual DEDUP**: near-identical/burst shots collapse to ONE cell, so cells show
  DISTINCT shots, not 12 copies of the same moment.
- **RANDOM order**: distinct shots are shuffled so similar ones don't sit in blocks.
- **ONE sheet, gapless**: crop-to-fill square tiles, no index badges, a FIXED column
  count (default 8 - readable, not over-dense), grid trimmed to fill exactly (no blanks).
- **IMAGES ONLY**: videos are excluded (a single still is unreliable - black for night clips).
- **Self-contained output**: one folder with `sheet001.png` + a `list.txt` (cell ->
  source file) INSIDE it. Default `%TEMP%\runes\imageverse\montages\<name>\`; point
  `-OutDir` somewhere durable like `<Downloads>\runes\imageverse\montages\` to keep it.

The engine is `${CLAUDE_PLUGIN_ROOT}/scripts/montage.ps1` (`.sh` mirror) - it reuses
`phash` (dedup) + `thumbs -Sheet` (tiling); videos need ffmpeg. Do NOT hand-roll tiling.

## Preflight: check dependencies

Before rendering, run the dependency check and surface anything missing to the user
(don't let a feature silently no-op): `deps` (`${CLAUDE_PLUGIN_ROOT}/scripts/deps.ps1`
on Windows / `deps.sh` elsewhere). If it prints `DEPS_MISSING=...`, tell the user the
missing tools and the `DEPS_FIX=...` command (e.g. `winget install -e --id Gyan.FFmpeg`,
or `sudo apt-get install -y imagemagick ffmpeg`), plus the `DEPS_DEGRADED=...` note for
what won't work until they install it. On Windows the `.ps1` montage only needs nothing
extra (System.Drawing is built in); the `.sh` montage needs ImageMagick.

## How to run

- **Album by name**: resolve the album to its folder under the user's library, then
  `montage.ps1 -Dir "<album folder>"`. If the album name is ambiguous, list matches and ask.
- **Folder by path**: `montage.ps1 -Dir "<path>"` (the user gave the path).
- **A selection / list**: `montage.ps1 -List "<paths file>"`.

  **Configurable flags** (expose these when the user asks, e.g. "montage album X in 6
  columns", "montage folder Y, bigger tiles", "less aggressive dedup"):
  - `-Cols N` - grid COLUMNS (default 8). Fewer = bigger tiles/less dense; more = denser.
  - `-Cell N` - max per-cell px (default 300; tiles shrink to fit width).
  - `-Dist N` - dedup strictness (default 10; higher collapses more similar shots, lower keeps more).
  - `-Max N` - cap to N distinct shots (0 = all).
  - `-Indexed` - stamped + padded cells for cell-by-cell reference (e.g. "move cells 4-7"),
    instead of the default dense gapless view.
  - `-OutDir <dir>`. (`.sh`: `--dir/--list/--cols/--cell/--dist/--max/--indexed/--out`.)

Report `MONTAGE_CELLS=<kept> (from <N> images -> <distinct> shots, + <V> videos)` and
the sheet paths so the user knows the compression and where to open them. Show a sheet
inline when helpful.

## Reply format

Shared rune shape: cast banner `ᚱ imageverse › /img-montage v0.1.0` on its own line,
then the montage folder path in backticks, then `🖼 **Montage:**` heading + bullets
(first bullet `📌 **What:**`). Vetted full-width emoji + one space (`📷 📁 🖼 📊 📌 🔍`).

```
ᚱ imageverse › /img-montage v0.1.0
📁 `C:\Users\you\Downloads\runes\imageverse\montages\Trentham`
🖼 **Montage:**
- 📌 **What:** 1 sheet, 92 cells from 110 images (81 distinct shots) + 11 videos.
- 📁 **Open:** sheet001.png  (map: list.txt)
```

## Notes

- Read-only: never moves or modifies the source images.
- Dedup tag `xN` in `list.txt` shows how many near-duplicates a cell represents.
- For organising/relocating images use `/img-organize`; this skill only VISUALISES.
