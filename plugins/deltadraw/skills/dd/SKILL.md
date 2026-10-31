---
name: dd
description: This skill should be used whenever a PICTURE is wanted rather than a diagram - "draw me", "illustrate", "sketch", "paint", "a scene with", "make an image of", "cover art", "poster", "hand-drawn", "/dd" - and whenever a deltadraw link draws wrong ("the ship is off the edge", "fix this drawing", "make the sky darker"). Produces a submillisecond.com/deltadraw URL that compiles the scene in the reader's browser, checked and looked at through the bundled deltadraw MCP server before it is handed over. Carries when to draw versus diagram, the shape of a scene, the built-in symbol conventions and the draw -> look -> refine loop; fetches the generated spec for the grammar.
version: 1.1.0
---

# dd - draw a picture as a deltadraw URL

A deltadraw link IS the drawing: a short scene rides in the URL fragment and the
viewer at `https://www.submillisecond.com/deltadraw` compiles and draws it. It
opens in deltalab as an ordinary painting the reader can keep working on.

The grammar is generated from the compiler and served at
`https://www.submillisecond.com/deltadraw/spec.md` (with the symbol catalogue
drawn at `/deltadraw/spec`). Fetch it, or call `deltadraw_spec`, for exact
syntax. The pack's contract is `../../contract/CONTRACTS.md`.

## Draw or diagram

Boxes and arrows, flows, architectures, sequences: use `dg` (deltagraph) - it
lays the graph out and routes the edges. A scene, an illustration, a cover, a
sketch with a look and a place: use `dd`.

## The loop, with the bundled server

1. **Write the scene.** `canvas WxH` first, then back to front by layer. Start
   from built-in symbols (`deltadraw_symbols`): things that stand on something
   have their base at y=0, floating things are centred, all face right, `flip`
   turns one; colours are parameters (`use @ship hull #333`).
2. **`deltadraw_check`.** Fix every error; each names its line.
3. **`deltadraw_png` and LOOK.** Everything on the canvas, at a sensible size,
   in front of the right things? A scene that compiles clean can still be drawn
   off the edge or hidden behind a later layer.
4. **Fix and re-render** until it reads, then **`deltadraw_url`** and hand back
   the `url` on its own line with a few words on what it shows. Revising a
   drawing you already linked: pass `previous_url` so the link keeps its history.
5. A painting made by hand in deltalab becomes an exact link with
   `deltadraw_pack`; any link becomes editable scene text with
   `deltadraw_to_scene`.

## Animation

`page` starts a new frame (`page "Two" time 0.2` sets its duration in seconds); a
`page` line before anything is drawn names and times page 1 instead. Give a mark
the same `id` on two pages and put `tween N [ease inout] [time S]` between them:
N in-between frames (0.1 s each by default) move, turn, resize and recolour it.
To turn a shape about its centre, draw it around 0,0 and place it with `at`
(`rect -50,-50 100,100 at 200,200 rot 45`); `rot` turns about the mark origin.
`#` is reserved in ids. `layer NAME
allframes` is a background every frame shares. Look at a frame with
`deltadraw_png`'s `page`, and at the whole animation with `deltadraw_gif`
(mode `pages`, or `replay` to watch one page being drawn).

```
canvas 600x300
layer sky allframes
rect 0,0 600,300 fill #fff8e7
layer fg
circle 60,150 30 fill red id ball
tween 6 ease inout
page time 0.4
layer fg
circle 540,150 30 fill blue id ball
```

Text takes `font sans|serif|mono|hand`, `bold`, `italic`, `underline`; lines
take `dashed` or `dotted` sized to their width. PNG and GIF renders embed
Inter, Source Serif 4, JetBrains Mono and Caveat, so the four faces match the
viewer, with bold and italic in sans, serif and mono. The hand face has one
style, so bold or italic hand text draws plain in a PNG.

Never report a drawing as done without step 3.

## A scene, for shape

```
canvas 1600x900 bg #0b0a22
seed 7
grad sky linear 0,0 0,900 #120c35 #c2477a@0.7 #ff9a4a
layer sky
rect 0,0 1600,900 fill sky
repeat 60: use @star at rand(0,1600),rand(0,400) scale rand(0.3,0.8)
layer sea
use @ship at 520,760
use @shark at 1100,830 rot -10
text "Night crossing" at 800,40 size 64 align center fill #ffe9a8
```

## Without MCP

- `scripts/dd-url.ps1` / `dd-url.sh`: scene file -> `URL=` + `LENGTH=`, offline.
  `-Compress` / `--compress` for the `#d1=` form; `-Title`, `-Theme`, `-Replay`,
  `-Edit` as in the contract.
- `scripts/dd-png.ps1` / `dd-png.sh`: scene file -> PNG via the worker's `/png`,
  so you can still look before handing over. `-Out` / `--out` is required;
  `-Page` / `--page` picks a frame of an animation.
- `scripts/dd-gif.ps1` / `dd-gif.sh`: scene file -> animated GIF via `/gif`,
  `-Mode` / `--mode pages|replay`.
