# img-edit - design spec

Follows skills/SPEC-TEMPLATE.md (REFERENCE kind).
Canonical data contracts: ../../contract/CONTRACTS.md.

Status: SHIPPED. The `img-edit` script (`.ps1` + `.sh`) and the `img-edit`
skill are built. Verified platform: Windows (`System.Drawing` backend). The
`.sh` backend (ImageMagick / sips) is mirrored but NOT yet verified.

## 1. Purpose / non-goals

Goal: a `/img-edit` rune that takes ONE source image, applies a deterministic
pixel transform the model decides by LOOKING at the image, and writes the
result to a NEW file. The model's job is to look at the rendered pixels and
compute exact coordinates (which region holds the secret, where the crop box
is, where a label goes); the script does the pixels. There is no
image-generation model behind it.

The supported transforms are deterministic only: crop, resize/scale,
redact (solid fill), annotate (outline box / drawn text), rotate, flip,
grayscale, and format/quality conversion.

Non-goals (stated as non-claims on the skill page):

- Not generative editing. Inpainting, object removal, restyle, and AI/detail
  upscaling are explicit non-claims - they would need an external
  image-generation backend the rune does not have.
- Not a source mutator. The output is always a NEW file. The source is left
  byte-for-byte untouched unless the user explicitly asks to edit in place
  (and even then the read-into-memory design makes `-Out == -In` a safe
  overwrite, not a self-lock).
- Not a blur/pixelate redactor. Redaction is a SOLID fill - the covered
  pixels are destroyed, which is the point for safe sharing. There is no
  reversible obfuscation mode.

## 2. Operations

Every operation the script implements, with the real flag name and default.
PowerShell uses `-PascalCase`; the `.sh` mirror uses the `--lower-case`
equivalent. Both take the same value syntax.

| Operation | PS flag | sh flag | Value | Default |
|---|---|---|---|---|
| Redact (solid-fill rectangle) | `-Redact` (repeatable, `string[]`) | `--redact` (repeatable) | `"X,Y,W,H"` | - |
| Redact fill colour | `-RedactColor` | `--redact-color` | `"#RRGGBB"` | `#000000` (black) |
| Box (outline rectangle) | `-Box` (repeatable) | `--box` (repeatable) | `"X,Y,W,H[,#RRGGBB[,T]]"` | colour `#FF0000` red, thickness `3` px |
| Text (drawn label) | `-Text` (repeatable) | `--text` (repeatable) | `"X,Y,SIZE,#RRGGBB,the text"` | colour `#FF0000` red; font Segoe UI (PS) |
| Crop | `-Crop` | `--crop` | `"X,Y,W,H"` | - |
| Resize (keep aspect via 0/auto) | `-Resize` | `--resize` | `"WxH"` (e.g. `800x0`, `0x600`, `800xauto`) | - |
| Scale by factor | `-Scale` (`double`) | `--scale` (float) | e.g. `0.5` | `0` (off); ignored when `-Resize` is set |
| Rotate clockwise | `-Rotate` (`double`) | `--rotate` | degrees | `0` (off) |
| Flip / mirror | `-Flip` | `--flip` | `h` or `v` | - |
| Grayscale | `-Grayscale` (switch) | `--grayscale` (flag) | - | off |
| JPEG quality | `-Quality` (`int`) | `--quality` | `1-100` | `90` |
| Source / dest | `-In` / `-Out` | `--in` / `--out` | path | required |

Operation semantics as implemented:

- Redact: fills the rectangle `(X,Y)` top-left, `W` wide, `H` tall, with
  `-RedactColor` (default black). Repeatable - each flag value is one box.
- Box: outlines the rectangle. Optional 5th field is a `#RRGGBB` stroke
  colour, optional 6th is stroke thickness in px (PS default 3). The box is
  drawn, not filled.
- Text: draws `the text` at `(X,Y)` at pixel font `SIZE` in colour
  `#RRGGBB`. The string is split on the FIRST four commas only, so the label
  text itself may contain commas. PS renders in Segoe UI; ImageMagick uses its
  default font.
- Crop: in PS the box is CLAMPED to image bounds (`X = max(0,X)`, then `W`/`H`
  capped to what remains); a fully out-of-bounds or zero-area crop is silently
  skipped (no crop op recorded). ImageMagick uses `-crop WxH+X+Y +repage` with
  no pre-clamp (it clips at the edge itself).
- Resize: `"WxH"` with `0` or `auto` on a side means "compute that side to keep
  aspect ratio". `800x0` -> width 800, height scaled proportionally; `0x600` ->
  height 600, width scaled. If both sides are given, aspect is NOT preserved
  (exact `WxH`). PS uses HighQualityBicubic; ImageMagick uses Lanczos.
- Scale: multiplies both dimensions by the factor (rounded). Ignored if
  `-Resize` is also present (resize wins).
- Rotate: PS treats 90/180/270 (after normalising the angle into `[0,360)`) as
  lossless `RotateFlip`; any other angle does a bicubic affine rotation with
  the canvas expanded to fit (`ceil(w*cos + h*sin)` etc.). ImageMagick passes
  the angle straight to `-rotate` with `-background none`.
- Flip: `h` mirrors horizontally, `v` vertically.
- Grayscale: PS applies a luma `ColorMatrix` (0.299 R, 0.587 G, 0.114 B - Rec.
  601). ImageMagick uses `-colorspace Gray`.
- Quality: clamped to `[1,100]` in PS; only applied to JPEG output. For JPEG,
  PS flattens any alpha onto WHITE before encoding (JPEG has no alpha, so
  transparent pixels would otherwise go black).

## 3. Logic / algorithm

Request -> operations mapping (driven by the skill, executed by the script):

1. Resolve the source: explicit path in args wins; otherwise the `image-find`
   finder is run (same flags as `/img`) and the most-recent screenshot is the
   default (confirm before editing it).
2. READ the source image (the Read tool renders it). This is the point of the
   rune - look at the actual pixels to decide WHICH edit and compute exact
   coordinates in ORIGINAL-image pixel space.
3. Translate the request into flags. The script applies operations in a FIXED
   ORDER regardless of flag order: redact -> box -> text -> crop ->
   resize/scale -> rotate -> flip -> grayscale -> save. Because every
   coordinate op (redact/box/text/crop) runs BEFORE the geometric ops, all
   coordinates are reasoned against the same original pixels the model saw.
4. Choose the output path: explicit `-Out`/`--out` wins; otherwise the skill
   writes next to the source as `<stem>-edited.<ext>` (the skill appends
   ` (2)`, ` (3)` to avoid clobbering). The destination EXTENSION sets the
   output format. NEVER overwrite the source unless asked.
5. Run the backend, parse `EDIT_OUT` (and `EDIT_SIZE` / `EDIT_OPS` /
   `EDIT_BYTES`), or `EDIT_ERROR` on failure.
6. Read the produced image BACK to confirm the edit landed (redaction actually
   covers the secret, crop kept the right region); adjust coordinates and
   re-run if off.

Imaging backend:

- `.ps1`: `System.Drawing` (GDI+), loaded via `Add-Type -AssemblyName
  System.Drawing`. Zero-dependency on Windows. Full op set in a single
  in-memory pipeline. The source is read with `File.ReadAllBytes` into a
  `MemoryStream` and detached into a standalone `Bitmap`, so the source file
  handle is released immediately (GDI+ `Image.FromFile` would otherwise lock
  it and block an in-place overwrite).
- `.sh`: prefers ImageMagick (`magick`, else `convert`) for the full op set
  in a single `magick` invocation; falls back to `sips` (macOS built-in) for
  the geometric / format subset only.

Output directory is created if missing (`New-Item -Force` / `mkdir -p`).

## 4. Data contracts

Input formats: png, jpg/jpeg, bmp, gif, tiff (what GDI+ / ImageMagick decode).

Output format: inferred from the `-Out` extension. PS dispatches:
`jpg`/`jpeg` -> JPEG (with quality + white flatten), `bmp` -> BMP, `gif` ->
GIF, `tif`/`tiff` -> TIFF, anything else (incl. `png`) -> PNG (PNG is the
default fallback). The `.sh` sips path maps the same extensions to a `-s
format` value, defaulting to png.

Output KEY=value lines (the house contract, same shape as `image-find` /
`image-index`):

```
EDIT_OUT=<absolute output path>
EDIT_FROM=<resolved source path>
EDIT_SIZE=<finalW>x<finalH>
EDIT_OPS=<comma-joined op tags applied, in execution order>
EDIT_BYTES=<output file size in bytes>
```

On any failure a single line is printed and the script exits 1:

```
EDIT_ERROR=<message>
```

Op tags emitted in `EDIT_OPS`: `redact`, `box`, `text`, `crop`, `resize`
(covers both `-Resize` and `-Scale`), `rotate<deg>` (e.g. `rotate90`),
`flipH`, `flipV`, `grayscale`. One tag per op actually applied; ops that were
requested but skipped (e.g. an out-of-bounds crop in PS) emit no tag.

Coordinate / geometry conventions:

- Origin top-left. `X` increases right, `Y` increases down.
- Units are PIXELS, in ORIGINAL-image space (the pixels the Read tool showed),
  not percent. There is no percent mode.
- Rectangles are `X,Y,W,H`: `(X,Y)` is the top-left corner, `W`/`H` the
  width/height. Internally ImageMagick draws `rectangle X,Y (X+W),(Y+H)`, so
  `W`/`H` are extents from the corner.
- Colours are `#RRGGBB` hex (6 digits). PS parses the three byte pairs; a
  malformed/short value falls back to the op's default colour.
- `-Resize` value is `WxH` (lowercase `x` separator); `0` or `auto` on a side
  means derive it from aspect.

## 5. Correctness + edge cases

- Never overwrite the source by default. The skill writes `<stem>-edited.<ext>`
  with ` (2)`/` (3)` disambiguation; in-place is explicit-opt-in only. The PS
  read-into-memory design makes even an explicit `-Out == -In` safe (no
  self-lock).
- Missing / unreadable input: both backends emit `EDIT_ERROR=input not found:
  <path>` and exit 1. Missing `-Out`: `EDIT_ERROR=missing -Out` / `missing
  --out`.
- Crop is bounds-clamped in PS (`max(0,...)` on origin, dimensions capped to
  remaining image); a zero-area or fully-out-of-bounds crop is dropped
  silently with no `crop` tag. ImageMagick relies on its own edge clipping
  via `-crop ... +repage`.
- Multi-op ordering is FIXED (redact -> box -> text -> crop -> resize/scale ->
  rotate -> flip -> grayscale -> save) independent of the order flags are
  passed. This is deliberate: all coordinate ops run on the pre-geometry
  pixels so the model's measured coordinates stay valid.
- Resize never preserves aspect when both sides are explicit (that is the
  caller asking for an exact size). There is NO never-upscale guard in either
  backend - a `-Resize`/`-Scale` larger than the source WILL upscale
  (bicubic/Lanczos). If "never grow" matters it is the skill's responsibility,
  not the script's.
- Redaction is irreversible by construction - a solid fill destroys the
  underlying pixels. There is no undo and no recoverable layer. This is the
  intended property for sharing a screenshot safely.
- Rotate angle is normalised into `[0,360)` before the lossless-vs-affine
  decision, so `-Rotate -90` == `270` and `-Rotate 450` == `90`.
- JPEG output flattens transparency onto white (PS) so alpha does not encode
  as black; quality is clamped to `[1,100]`.

## 6. Parity (.ps1 vs .sh)

Verified platform is Windows (`.ps1` / `System.Drawing`). The `.sh` path is
mirrored but NOT yet verified.

`.sh` requirements:

- macOS: `sips` is built in and covers resize / scale / rotate / flip /
  convert / quality with zero install.
- Full op set on `.sh` needs ImageMagick (`magick` or `convert`;
  `brew install imagemagick` / `apt install imagemagick` / `dnf install
  ImageMagick`). With neither tool present the script emits
  `EDIT_ERROR=no image backend found`.

Operations one backend supports that the other does not:

- sips-only environments CANNOT do the draw-based ops (redact, box, text,
  grayscale) NOR an arbitrary-offset crop. The script detects this up front
  (`needs_im`) and, if only sips is available, refuses with a clear
  `EDIT_ERROR=redact/box/text/grayscale/offset-crop need ImageMagick...`
  rather than silently dropping the op.
- Backend rendering differs in ways that are NOT byte-identical: PS resize uses
  HighQualityBicubic, ImageMagick uses Lanczos; PS text is Segoe UI, ImageMagick
  uses its default font; PS grayscale is a Rec. 601 luma matrix, ImageMagick is
  `-colorspace Gray`. Same intent, different pixels. The contract is behavioural
  parity (same op set, same `EDIT_*` lines), not pixel-identical output.
- `EDIT_SIZE` on `.sh` is read back from the output file via `magick identify`
  or `sips -g`, printing `?` if neither can report; PS computes it from the
  in-memory bitmap. PS `EDIT_FROM` is the RESOLVED absolute source path; `.sh`
  echoes the raw `--in` argument as given.

## 7. Gotchas

Real issues found in the code (documentation only - not changed):

- `.sh` `IFS=',' read -r x y w h <<< "$r"`: a redact/box/crop value with FEWER
  than four comma fields leaves the trailing variables empty, and the `$((x +
  w))` arithmetic then evaluates an empty string as 0 - so a malformed
  rectangle silently draws a degenerate (zero-extent) shape instead of being
  rejected. PS guards this with `Get-Ints` returning `$null` (and skipping the
  op) when there are fewer than N fields; the `.sh` path has no equivalent
  guard.
- `.sh` `for r in "${REDACT[@]:-}"`: the `:-` default makes an EMPTY array
  expand to a single empty string. The `[ -z "$r" ] && continue` inside the
  loop absorbs it, so this is harmless here, but it is the classic
  empty-array-folds-to-one-blank pattern - any future loop body that does not
  guard the empty case would process a phantom element.
- `.sh` `--text` is split with `IFS=','` into exactly 5 fields (`x y t col
  txt`), so the trailing `txt` keeps any remaining commas - matching the PS
  `-split ',', 5`. Good, but note the FONT-SIZE field is named `t` here and the
  box THICKNESS field is also `t` in its loop; they are separate loop locals so
  there is no collision, but the reused name is a readability trap.
- PS `-Text` size uses `[single]$p[2].Trim()` for the font but casts the x/y to
  `[single]([int]...)` - a fractional `SIZE` would be accepted for the font yet
  any fractional coordinate is floored via the `[int]` cast first. Minor
  asymmetry, not a bug.
- No never-upscale guard anywhere (section 5) - a resize/scale beyond native
  resolution will interpolate up and produce a soft, larger image. Callers
  expecting "shrink only" must enforce that in the skill.
- `.sh` `--scale` with sips re-reads the width via `sips -g pixelWidth` and
  resamples by WIDTH only (`--resampleWidth`), relying on sips to preserve
  aspect for the height; the ImageMagick path uses a true percentage resize.
  Equivalent intent, different mechanism.
- Output format is driven purely by the `-Out` extension; an unrecognised
  extension silently produces a PNG (PS default branch / sips `*) fmt=png`),
  not an error. A typo'd extension yields a PNG with the wrong suffix.

## 8. Status

SHIPPED. Verified platform: Windows (`img-edit.ps1`, `System.Drawing` / GDI+,
zero-dependency, full op set). The `.sh` backend (ImageMagick full op set;
sips geometric/format subset) is implemented and mirrors the same `EDIT_*`
contract and fixed op order, but is NOT yet verified on macOS or Linux.
