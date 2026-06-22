#!/usr/bin/env bash
# img-edit - apply deterministic edits to an image, writing a NEW image.
# Cross-platform backend, mirroring the Windows System.Drawing path.
#
# Two backends, picked per op set:
#   * ImageMagick (magick / convert) - full op set; preferred when present.
#   * sips (built into macOS) - zero-dep fast path for the geometric / format
#     ops (resize, scale, rotate, flip, convert, quality). The draw-based ops
#     (redact, box, text, grayscale) and arbitrary-offset crop need ImageMagick;
#     if only sips is available and one of those is requested, we say so.
#
# Coordinate ops (--redact/--box/--text/--crop) use ORIGINAL pixel space and are
# emitted BEFORE the geometric ops, matching the Windows backend's fixed order.
#   --in PATH --out PATH
#   --redact "X,Y,W,H"  (repeatable)   --redact-color "#RRGGBB"
#   --box    "X,Y,W,H[,#RRGGBB[,T]]"  (repeatable)
#   --text   "X,Y,SIZE,#RRGGBB,the text"  (repeatable; text may contain commas)
#   --crop "X,Y,W,H"  --resize "WxH"  --scale F  --rotate DEG  --flip h|v
#   --grayscale  --quality N
# --resize/--scale are shrink-only: a target above the source is clamped (never upscales).
# --out format is taken from the extension (png/jpg/jpeg/bmp/gif/tif/tiff, plus webp on the
# ImageMagick backend); an unsupported extension is a hard error, not a silent PNG.
# Prints EDIT_OUT / EDIT_FROM / EDIT_SIZE / EDIT_OPS / EDIT_BYTES, or EDIT_ERROR.
set -euo pipefail

IN=""; OUT=""; CROP=""; RESIZE=""; SCALE=""; ROTATE=""; FLIP=""; GRAY=0
QUALITY=90; REDACT_COLOR="#000000"
REDACT=(); BOX=(); TEXT=()

while [ $# -gt 0 ]; do
  case "$1" in
    --in) IN="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --redact) REDACT+=("$2"); shift 2;;
    --box) BOX+=("$2"); shift 2;;
    --text) TEXT+=("$2"); shift 2;;
    --redact-color) REDACT_COLOR="$2"; shift 2;;
    --crop) CROP="$2"; shift 2;;
    --resize) RESIZE="$2"; shift 2;;
    --scale) SCALE="$2"; shift 2;;
    --rotate) ROTATE="$2"; shift 2;;
    --flip) FLIP="$2"; shift 2;;
    --grayscale) GRAY=1; shift;;
    --quality) QUALITY="$2"; shift 2;;
    *) echo "EDIT_ERROR=unknown arg: $1"; exit 1;;
  esac
done

[ -n "$IN" ] && [ -f "$IN" ] || { echo "EDIT_ERROR=input not found: $IN"; exit 1; }
[ -n "$OUT" ] || { echo "EDIT_ERROR=missing --out"; exit 1; }
mkdir -p "$(dirname "$OUT")"

MAGICK="$(command -v magick || true)"
[ -z "$MAGICK" ] && MAGICK="$(command -v convert || true)"
SIPS="$(command -v sips || true)"

# Does the request need a draw-capable backend (ImageMagick)?
needs_im=0
{ [ "${#REDACT[@]}" -gt 0 ] || [ "${#BOX[@]}" -gt 0 ] || [ "${#TEXT[@]}" -gt 0 ] \
  || [ -n "$CROP" ] || [ "$GRAY" = 1 ]; } && needs_im=1

report() {
  local size
  if [ -n "$MAGICK" ]; then size="$("$MAGICK" identify -format '%wx%h' "$OUT" 2>/dev/null || echo '?')"
  elif [ -n "$SIPS" ]; then size="$("$SIPS" -g pixelWidth -g pixelHeight "$OUT" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w"x"h}')"
  else size='?'; fi
  echo "EDIT_OUT=$OUT"
  echo "EDIT_FROM=$IN"
  echo "EDIT_SIZE=$size"
  echo "EDIT_OPS=$1"
  echo "EDIT_BYTES=$(wc -c < "$OUT" | tr -d ' ')"
}

# ---- ImageMagick path (full op set, single pass) ----
run_magick() {
  local args=("$IN") ops=() x y w h col t pct
  for r in "${REDACT[@]:-}"; do
    [ -z "$r" ] && continue
    IFS=',' read -r x y w h <<< "$r"
    args+=(-fill "$REDACT_COLOR" -stroke none -draw "rectangle $x,$y $((x + w)),$((y + h))"); ops+=("redact")
  done
  for b in "${BOX[@]:-}"; do
    [ -z "$b" ] && continue
    IFS=',' read -r x y w h col t <<< "$b"; col="${col:-#FF0000}"; t="${t:-3}"
    args+=(-fill none -stroke "$col" -strokewidth "$t" -draw "rectangle $x,$y $((x + w)),$((y + h))"); ops+=("box")
  done
  for tx in "${TEXT[@]:-}"; do
    [ -z "$tx" ] && continue
    IFS=',' read -r x y t col txt <<< "$tx"; col="${col:-#FF0000}"
    args+=(-stroke none -fill "$col" -pointsize "$t" -annotate "+$x+$y" "$txt"); ops+=("text")
  done
  if [ -n "$CROP" ]; then IFS=',' read -r x y w h <<< "$CROP"; args+=(-crop "${w}x${h}+${x}+${y}" +repage); ops+=("crop"); fi
  # Shrink-only: the trailing '>' tells ImageMagick to resize ONLY if the image is
  # larger than the geometry, so a target/percent above the source is a no-op (never upscales).
  if [ -n "$RESIZE" ]; then args+=(-filter Lanczos -resize "${RESIZE}>"); ops+=("resize")
  elif [ -n "$SCALE" ]; then pct="$(awk "BEGIN{print $SCALE*100}")"; args+=(-filter Lanczos -resize "${pct}%>"); ops+=("resize"); fi
  [ -n "$ROTATE" ] && { args+=(-background none -rotate "$ROTATE"); ops+=("rotate$ROTATE"); }
  [ "$FLIP" = "h" ] && { args+=(-flop); ops+=("flipH"); }
  [ "$FLIP" = "v" ] && { args+=(-flip); ops+=("flipV"); }
  [ "$GRAY" = "1" ] && { args+=(-colorspace Gray); ops+=("grayscale"); }
  args+=(-quality "$QUALITY" "$OUT")
  "$MAGICK" "${args[@]}"
  report "$( IFS=,; echo "${ops[*]:-}" )"
}

# ---- sips path (macOS built-in; geometric / format subset) ----
run_sips() {
  local ops=() ext fmt w h cw ch
  cp "$IN" "$OUT"
  # sips' --resample* flags WILL enlarge; ImageMagick's '>' qualifier has no sips
  # equivalent, so clamp each requested axis to the source dimension by hand to
  # preserve the shrink-only contract (never upscales).
  cw="$("$SIPS" -g pixelWidth "$OUT" | awk '/pixelWidth/{print $2}')"
  ch="$("$SIPS" -g pixelHeight "$OUT" | awk '/pixelHeight/{print $2}')"
  if [ -n "$RESIZE" ]; then
    w="${RESIZE%x*}"; h="${RESIZE#*x}"
    [ "$w" = "auto" ] && w=0; [ "$h" = "auto" ] && h=0
    [ "${w:-0}" -gt 0 ] && [ "$w" -gt "$cw" ] && w="$cw"
    [ "${h:-0}" -gt 0 ] && [ "$h" -gt "$ch" ] && h="$ch"
    if [ "${w:-0}" -gt 0 ] && [ "${h:-0}" -gt 0 ]; then "$SIPS" --resampleHeightWidth "$h" "$w" "$OUT" >/dev/null
    elif [ "${w:-0}" -gt 0 ]; then "$SIPS" --resampleWidth "$w" "$OUT" >/dev/null
    elif [ "${h:-0}" -gt 0 ]; then "$SIPS" --resampleHeight "$h" "$OUT" >/dev/null; fi
    ops+=("resize")
  elif [ -n "$SCALE" ]; then
    w="$(awk "BEGIN{print int($cw*$SCALE+0.5)}")"
    [ "$w" -gt "$cw" ] && w="$cw"
    "$SIPS" --resampleWidth "$w" "$OUT" >/dev/null; ops+=("resize")
  fi
  [ -n "$ROTATE" ] && { "$SIPS" -r "$ROTATE" "$OUT" >/dev/null; ops+=("rotate$ROTATE"); }
  [ "$FLIP" = "h" ] && { "$SIPS" -f horizontal "$OUT" >/dev/null; ops+=("flipH"); }
  [ "$FLIP" = "v" ] && { "$SIPS" -f vertical "$OUT" >/dev/null; ops+=("flipV"); }
  ext="$(echo "${OUT##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    jpg|jpeg) fmt=jpeg;; png) fmt=png;; gif) fmt=gif;; tif|tiff) fmt=tiff;; bmp) fmt=bmp;;
  esac
  "$SIPS" -s format "$fmt" "$OUT" >/dev/null
  [ "$fmt" = "jpeg" ] && "$SIPS" -s formatOptions "$QUALITY" "$OUT" >/dev/null
  report "$( IFS=,; echo "${ops[*]:-}" )"
}

# Reject an unknown output extension loudly instead of silently writing one
# format's bytes under another name. The two backends differ on webp: ImageMagick
# encodes it when built with the webp delegate; sips has no webp encoder.
out_ext="$(echo "${OUT##*.}" | tr '[:upper:]' '[:lower:]')"
if [ -n "$MAGICK" ]; then
  case "$out_ext" in
    png|jpg|jpeg|bmp|gif|tif|tiff|webp) ;;
    *) echo "EDIT_ERROR=unsupported output extension '$out_ext' (supported: png, jpg, jpeg, bmp, gif, tif, tiff, webp)"; exit 1;;
  esac
  run_magick
elif [ -n "$SIPS" ]; then
  if [ "$needs_im" = 1 ]; then
    echo "EDIT_ERROR=redact/box/text/grayscale/offset-crop need ImageMagick; install it (brew install imagemagick). sips covers resize/scale/rotate/flip/convert."
    exit 1
  fi
  case "$out_ext" in
    png|jpg|jpeg|bmp|gif|tif|tiff) ;;
    *) echo "EDIT_ERROR=unsupported output extension '$out_ext' (supported: png, jpg, jpeg, bmp, gif, tif, tiff; webp needs the ImageMagick backend)"; exit 1;;
  esac
  run_sips
else
  echo "EDIT_ERROR=no image backend found. macOS has sips built in; on Linux install ImageMagick (e.g. apt install imagemagick or dnf install ImageMagick)."
  exit 1
fi
