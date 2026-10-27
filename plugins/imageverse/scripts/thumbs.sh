#!/usr/bin/env bash
# thumbs: .sh port of thumbs.ps1 (sips on macOS, else ImageMagick; videos need ffmpeg and ImageMagick).
# thumbs.sh --path p | --list f [--max 1600] [--sheet N [--sheet-cell px] [--cols N] [--dense]] [--video-frames 12] [--plugin p] [--out d]
set -uo pipefail

MAX=1600; VFRAMES=12; SHEET=0; SHEETCELL=360; COLS=0; DENSE=0; OUT=""; PLUGIN="misc"; SRCS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --path) SRCS+=("$2"); shift 2;;
    --list) while IFS= read -r l; do [ -n "$l" ] && SRCS+=("$l"); done < "$2"; shift 2;;
    --max) MAX="$2"; shift 2;;
    --sheet) SHEET="$2"; shift 2;;
    --sheet-cell) SHEETCELL="$2"; shift 2;;
    --cols) COLS="$2"; shift 2;;
    --dense) DENSE=1; shift;;
    --video-frames) VFRAMES="$2"; shift 2;;
    --plugin) PLUGIN="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    *) echo "THUMB_NOTE=unknown arg $1"; exit 1;;
  esac
done
[ -n "$OUT" ] || OUT="${TMPDIR:-/tmp}/runes/$PLUGIN/thumbs"
if [ ${#SRCS[@]} -eq 0 ]; then echo "THUMB_COUNT=0"; echo "THUMB_NOTE=no input (--path/--list)"; exit 0; fi
mkdir -p "$OUT"

MAGICK="$(command -v magick || command -v convert || true)"
SIPS="$(command -v sips || true)"
if [ -z "$MAGICK" ] && [ -z "$SIPS" ]; then
  echo "THUMB_COUNT=0"; echo "THUMB_NOTE=need sips (macOS) or ImageMagick (brew/apt install imagemagick)"; exit 1
fi
# Video sheets need ffmpeg plus ImageMagick montage (magick montage on IM7, montage on IM6).
# Without ffprobe for the duration, fall back to ffmpeg's thumbnail+tile filter.
FFMPEG="$(command -v ffmpeg || true)"; FFPROBE="$(command -v ffprobe || true)"
IM7=0; case "$(basename "${MAGICK:-x}")" in magick) IM7=1;; esac
MONTAGE="$(command -v montage || true)"
have_montage=0; { [ "$IM7" = 1 ] || [ -n "$MONTAGE" ]; } && have_montage=1
montage_cmd() { if [ "$IM7" = 1 ]; then "$MAGICK" montage "$@"; else "$MONTAGE" "$@"; fi; }
is_video() { case "$(printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]')" in mp4|mov|m4v|avi|mkv|webm|3gp|3g2|wmv|mpg|mpeg|mts|m2ts) return 0;; *) return 1;; esac; }
is_audio() { case "$(printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]')" in mp3|m4a|wav|aac|ogg|oga|opus|flac|wma|amr|aiff|aif) return 0;; *) return 1;; esac; }

echo "THUMB_DIR=$OUT"

# triage: tile many stills into index-stamped contact sheets (--sheet N). Each cell
# carries its global 1-based index (= --list line) so it maps back unambiguously.
if [ "$SHEET" -gt 0 ]; then
  { [ -n "$MAGICK" ] && [ "$have_montage" = 1 ]; } || { echo "THUMB_NOTE=need ImageMagick for --sheet"; exit 1; }
  s_img_re='\.(jpg|jpeg|png|heic|heif|gif|bmp|tif|tiff|webp)$'
  # explicit --cols (default), else a near-square grid. (bash $(( )) / awk int()
  # already truncate, so no [int]-rounding pitfall like the .ps1 had.)
  if [ "${COLS:-0}" -gt 0 ]; then cols=$COLS; else cols=$(awk -v n="$SHEET" 'BEGIN{c=int(sqrt(n)); if(c*c<n)c++; print c}'); fi
  rows=$(( (SHEET + cols - 1) / cols ))
  geo="+4+4"; [ "$DENSE" = 1 ] && geo="+0+0"   # --dense: gapless
  total=${#SRCS[@]}; sheetno=0; st0="$(date +%s)"; slines=(); base=0
  while [ "$base" -lt "$total" ]; do
    last=$((base + SHEET - 1)); [ "$last" -ge "$total" ] && last=$((total - 1))
    tmpd="$(mktemp -d)"; cells=(); j=$base
    while [ "$j" -le "$last" ]; do
      s="${SRCS[$j]}"; idx=$((j + 1)); cf="$tmpd/$(printf '%05d' "$idx").png"
      if [ -f "$s" ] && printf '%s' "$s" | grep -qiE "$s_img_re"; then
        if [ "$DENSE" = 1 ]; then
          # cover + center-crop (gapless square tile), no index badge
          "$MAGICK" "$s" -resize "${SHEETCELL}x${SHEETCELL}^" -gravity center -extent "${SHEETCELL}x${SHEETCELL}" "$cf" 2>/dev/null || true
        else
          "$MAGICK" "$s" -resize "${SHEETCELL}x${SHEETCELL}" -background '#141414' -gravity center -extent "${SHEETCELL}x${SHEETCELL}" \
            -gravity NorthWest -fill yellow -undercolor '#000000dc' -pointsize 16 -annotate +2+2 " $(printf '%03d' "$idx") " "$cf" 2>/dev/null || true
        fi
      fi
      if [ ! -f "$cf" ]; then
        if [ "$DENSE" = 1 ]; then "$MAGICK" -size "${SHEETCELL}x${SHEETCELL}" "canvas:#141414" "$cf" 2>/dev/null || true
        else "$MAGICK" -size "${SHEETCELL}x${SHEETCELL}" "canvas:#141414" -gravity NorthWest -fill yellow -pointsize 16 -annotate +2+2 " $(printf '%03d' "$idx") " "$cf" 2>/dev/null || true; fi
      fi
      cells+=("$cf"); j=$((j + 1))
    done
    sheetno=$((sheetno + 1)); dest="$OUT/$(printf 'sheet%03d.png' "$sheetno")"
    montage_cmd "${cells[@]}" -tile "${cols}x${rows}" -geometry "${SHEETCELL}x${SHEETCELL}${geo}" -background '#141414' "$dest" 2>/dev/null || true
    slines+=("$dest"$'\t'"$((base + 1))-$((last + 1))"); rm -rf "$tmpd"; base=$((base + SHEET))
  done
  echo "SHEET_COUNT=$sheetno"; echo "SHEET_PERSHEET=$SHEET"; echo "SHEET_SECONDS=$(( $(date +%s) - st0 ))"
  for l in "${slines[@]:-}"; do [ -n "$l" ] && printf '%s\n' "$l"; done
  exit 0
fi

n=0; nv=0; i=0; lines=(); t0="$(date +%s)"
for s in "${SRCS[@]}"; do
  i=$((i + 1)); [ -f "$s" ] || continue
  base="$(basename "${s%.*}")"
  idx="$(printf '%03d' "$i")"
  dest="$OUT/${idx}_${base}.png"
  if is_audio "$s"; then printf 'THUMB_SKIP_AUDIO\t%s\n' "$s"; continue; fi
  if is_video "$s"; then
    if [ -z "$FFMPEG" ] || [ "$have_montage" = 0 ] || [ -z "$MAGICK" ]; then printf 'THUMB_SKIP_VIDEO\t%s\n' "$s"; continue; fi
    vtmp="$(mktemp -d)"
    dur=""; [ -n "$FFPROBE" ] && dur="$("$FFPROBE" -v error -show_entries format=duration -of csv=p=0 "$s" 2>/dev/null)"
    made=0
    if printf '%s' "$dur" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
      k=0
      while [ "$k" -lt "$VFRAMES" ]; do
        t="$(awk -v d="$dur" -v k="$k" -v n="$VFRAMES" 'BEGIN{printf "%.3f", d*(k+0.5)/n}')"
        fo="$vtmp/$(printf '%03d' "$k").png"
        "$FFMPEG" -nostdin -loglevel error -y -ss "$t" -i "$s" -frames:v 1 -q:v 3 "$fo" 2>/dev/null
        [ -f "$fo" ] && made=$((made + 1)); k=$((k + 1))
      done
    fi
    rows=$(( (VFRAMES + 3) / 4 )); grid="$vtmp/grid.png"
    if [ "$made" -gt 0 ]; then
      montage_cmd "$vtmp"/[0-9]*.png -tile "4x${rows}" -geometry "420x420+4+4" -background black "$grid" 2>/dev/null
    else
      "$FFMPEG" -nostdin -loglevel error -y -i "$s" -frames:v 1 -vf "thumbnail=100,tile=4x${rows}" "$grid" 2>/dev/null
    fi
    if [ -f "$grid" ]; then
      "$MAGICK" "$grid" -resize "${MAX}x${MAX}>" -gravity NorthWest -fill yellow -undercolor '#000000c0' -pointsize 30 -annotate +2+2 " $idx " "$dest" 2>/dev/null \
        && { lines+=("$dest"$'\t'"$s"); n=$((n + 1)); nv=$((nv + 1)); } || printf 'THUMB_SKIP_VIDEO\t%s\n' "$s"
    else
      printf 'THUMB_SKIP_VIDEO\t%s\n' "$s"
    fi
    rm -rf "$vtmp"; continue
  fi
  if [ -n "$MAGICK" ]; then
    # Stamp the index badge top-left so the model maps each thumbnail to its source
    # by the visible number, not read order (kills the bulk-read off-by-one mislabel).
    "$MAGICK" "$s" -resize "${MAX}x${MAX}>" \
      -gravity NorthWest -fill yellow -undercolor '#000000c0' -pointsize 30 -annotate +2+2 " $idx " \
      "$dest" 2>/dev/null && { lines+=("$dest"$'\t'"$s"); n=$((n + 1)); }
  else
    # sips (macOS-only fallback) can resize but NOT draw text - no index stamp; on a
    # sips-only box read smaller batches so order stays trackable. Install ImageMagick for stamps.
    cp "$s" "$dest" && "$SIPS" -Z "$MAX" "$dest" >/dev/null 2>&1 && "$SIPS" -s format png "$dest" >/dev/null 2>&1 && { lines+=("$dest"$'\t'"$s"); n=$((n + 1)); }
  fi
done
echo "THUMB_COUNT=$n"
echo "THUMB_VIDEOS=$nv"
echo "THUMB_SECONDS=$(( $(date +%s) - t0 ))"
for l in "${lines[@]:-}"; do [ -n "$l" ] && printf '%s\n' "$l"; done
