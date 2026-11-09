---
name: img-edit
description: This skill should be used when the user asks to "/img-edit", "crop this screenshot", "redact the secrets/emails in this image", "resize my screenshot to 800px", "blank out / black-box this part", "add a red box around the error", "rotate / flip this photo", "convert this png to jpg", "make this image grayscale", or otherwise wants an image TRANSFORMED into a new image file. Deterministic edits only (crop / resize / redact / annotate / rotate / convert) - NOT generative edits.
version: 0.2.0
---

# img-edit - edit an image into a new image

Take a source image, apply a deterministic transform decided by looking at the
image, and write the result to a NEW file. The original is left untouched.

This rune does DETERMINISTIC pixel edits: crop, resize/scale, redact (fill a
region), annotate (outline box / text), rotate, flip, grayscale, and format /
quality conversion. It does NOT do generative edits (inpainting, object removal,
style change, detail upscaling) - there is no image-generation model behind it;
the model decides WHAT to do and WHERE, and the backend script does the pixels.

## Steps

1. Resolve the source image:
   - An explicit path in the arguments wins.
   - Otherwise locate it with the finder (same flags as `img` - count / within / name / `--dir`):
     Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.ps1" <flags>`
     macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.sh" <flags>`
     With no selection it returns the most recent screenshot - confirm that is the one to edit.
2. **Read the source image** (the Read tool renders it). This is the point of the rune: look at the actual pixels to decide the edit and compute exact coordinates - which region holds the secrets to redact, the crop box around the chart, where to place a label. Coordinates are in ORIGINAL-image pixel space (top-left origin, x right, y down).
3. Translate the request into flags for the backend. Operations are applied in a fixed order regardless of flag order: redact -> box -> text -> crop -> resize/scale -> rotate -> flip -> grayscale -> save. All coordinate ops use original-image space, so a redact box and a crop box can be reasoned about against the same pixels you see.
4. Choose the output path: an explicit `--out` in the arguments wins; otherwise write next to the source as `<stem>-edited.<ext>` (append ` (2)`, ` (3)` to avoid clobbering). NEVER overwrite the source unless the user explicitly asks to edit in place. The extension sets the format (`.png` / `.jpg` / `.bmp` / `.gif` / `.tiff`).
5. Run the backend:
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/img-edit.ps1" -In "<src>" -Out "<dst>" [ops]`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/img-edit.sh" --in "<src>" --out "<dst>" [ops]`
   Expect `EDIT_OUT=` (plus `EDIT_SIZE` / `EDIT_OPS` / `EDIT_BYTES`); on failure it prints `EDIT_ERROR=`.
6. **Read the produced image back** to confirm the edit landed as intended (the redaction actually covers the secret, the crop kept the right region). If it is off, adjust the coordinates and re-run. Then report in the format below.

## Operations

PowerShell flags (the `.sh` uses the `--lower-case` equivalents):

| Intent | Flag |
|---|---|
| Black-box a region (redact) | `-Redact "X,Y,W,H"` (repeatable), `-RedactColor "#RRGGBB"` |
| Outline a region (highlight) | `-Box "X,Y,W,H[,#RRGGBB[,T]]"` (repeatable) |
| Draw a label | `-Text "X,Y,SIZE,#RRGGBB,the text"` (repeatable) |
| Crop | `-Crop "X,Y,W,H"` |
| Resize (keep aspect: 0/auto a side) | `-Resize "800x0"` |
| Scale by factor | `-Scale 0.5` |
| Rotate clockwise (90/180/270 lossless) | `-Rotate 90` |
| Mirror | `-Flip h` or `-Flip v` |
| Desaturate | `-Grayscale` |
| Convert format / quality | set the `-Out` extension; `-Quality 1-100` for JPEG |

Flags combine in one call (e.g. crop then resize then redact). Redaction is a
solid fill, not a blur - the covered pixels are gone, which is the point for
sharing a screenshot safely.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img-edit` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📷` `📁` `📦` `📊` `📝` `📌` `🔖` `📄` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the edit.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 is `📷 ` + the **new** image path (`EDIT_OUT`). Line 2 is the heading
`📝 **Edited:**`. Then the `📌 What` bullet, the ops applied, and an `📦 **Size:**`
bullet. Mention the source path so it is clear the original was kept.

```
ᚱ imageverse › /img-edit v0.1.0
📷 `C:\Users\you\Pictures\Screenshots\Screenshot 2026-06-20 115825-edited.png`
📝 **Edited:**
- 📌 **What:** redacted the API key and cropped to the stats ticker.
- 📝 **Ops:** redact (1180,64,300,28) -> crop (0,56,2560,48).
- 📦 **Size:** 2560x48 PNG, 22 KB. Source kept at `...115825.png`.
```

## Notes

- Backends (the rune picks per OS + op set; all produce the same `EDIT_*` output):
  - **Windows:** `System.Drawing` (built in; zero-dep) - full op set. Verified.
  - **macOS:** `sips` (built in) covers resize / scale / rotate / flip / convert / quality with no install. The draw-based ops (redact / box / text / grayscale) and arbitrary-offset crop need ImageMagick (`brew install imagemagick`); the script says so if asked for one without it. Not yet verified.
  - **Linux:** ImageMagick (`magick`/`convert`; `apt install imagemagick`) for the full op set. Not yet verified.
- Coordinates are original-image pixels; read the image first and measure against what you see. Re-read the output and correct if a box or crop is off.
- Deterministic edits only. Generative edits (inpainting, object removal, restyle, AI upscale) are a stated non-claim - they would need an external image-generation backend.
