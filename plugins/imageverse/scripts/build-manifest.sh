#!/usr/bin/env bash
# build-manifest - turn a CLASSIFICATION into a file-ops manifest. macOS/Linux
# backend (see build-manifest.ps1). The rune's only judgement call is "which
# album does each image belong to"; all mechanical naming/sequencing/dest paths
# are deterministic and live here - do NOT hand-roll manifest lines in the rune.
#   --class file|dir  tab-separated <album>\t<source> (source = full path OR a
#                     bare filename resolved via --shots). A DIRECTORY = concat all
#                     batch *.tsv name-sorted (no hand-rolled `cat batch*.tsv`).
#   --shots file      image-find --outfile full-path list; resolves bare filenames + index ranges
#   --meta file       image-find --tsvfile TSV; true EXIF capture time (incl.
#                     sub-second) for naming/ordering instead of filename/mtime
#   --base dir        dest base (default: parent folder of the first source)
#   --op move|copy    default move
#   --plugin name     calling plugin/pack; namespaces the default temp (default misc)
#   --manifest file   output (default $TMPDIR/runes/<plugin>/manifest.tsv)
# Writes <op>\t<src>\t<dest> (dest=<base>/<album>/<album>-<date>-NN.ext, date from
# the filename's YYYY-MM-DD else file mtime). Prints MANIFEST_FILE + MANIFEST_COUNT
# then the manifest. Feed the result to file-ops.
set -uo pipefail

CLASS=""; SHOTS=""; META=""; BASE=""; OP="move"; MANIFEST=""; PLUGIN="misc"
while [ $# -gt 0 ]; do
  case "$1" in
    --class) CLASS="$2"; shift 2;;
    --shots) SHOTS="$2"; shift 2;;
    --meta) META="$2"; shift 2;;
    --base) BASE="$2"; shift 2;;
    --op) OP="$2"; shift 2;;
    --plugin) PLUGIN="$2"; shift 2;;
    --manifest) MANIFEST="$2"; shift 2;;
    *) echo "MANIFEST_ERROR=unknown arg $1"; exit 1;;
  esac
done
[ -n "$CLASS" ] || { echo "MANIFEST_ERROR=missing --class"; exit 1; }
# --class may be a single file OR a DIRECTORY of batch *.tsv files (compaction-safe
# per-batch classification) - concatenate all of them, name-sorted, so there is no
# hand-rolled `cat batch*.tsv` step.
mtime() { date -r "$1" +%s 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
classfile="$CLASS"; batchinfo=""
if [ -d "$CLASS" ]; then
  classfile="$(mktemp)"
  bn=0; firstbatch=""
  for bf in "$CLASS"/*.tsv; do
    [ -f "$bf" ] || continue
    cat "$bf" >> "$classfile"
    [ -z "$firstbatch" ] && firstbatch="$(mtime "$bf")"
    bn=$((bn + 1))
  done
  if [ "$bn" -gt 0 ]; then
    # Classification wall-clock = thumbnails-done -> now (captures the vision phase,
    # unlike a batch-write span which is ~0 when batches are written at the end).
    start="$firstbatch"
    thumbs="$(dirname "$CLASS")/thumbs"
    if [ -d "$thumbs" ]; then
      newest="$(ls -t "$thumbs" 2>/dev/null | head -1)"
      [ -n "$newest" ] && start="$(mtime "$thumbs/$newest")"
    fi
    span=$(( $(date +%s) - start )); [ "$span" -lt 0 ] && span=0
    batchinfo="MANIFEST_BATCHES=$bn MANIFEST_CLASSIFY_SECONDS=$span"
  fi
fi
[ -f "$classfile" ] || { echo "MANIFEST_ERROR=unreadable --class"; exit 1; }
CLASS="$classfile"
[ -n "$MANIFEST" ] || MANIFEST="${TMPDIR:-/tmp}/runes/$PLUGIN/manifest.tsv"

# Optional basename -> full-path map from the shots list.
namemap="$(mktemp)"
if [ -n "$SHOTS" ] && [ -f "$SHOTS" ]; then
  while IFS= read -r line; do [ -n "$line" ] && printf '%s\t%s\n' "$(basename "$line")" "$line"; done < "$SHOTS" > "$namemap"
fi
# Optional EXIF metadata (image-find --tsvfile): path -> "date<TAB>time<TAB>subsec"
# from the true capture timestamp incl. sub-second. Preferred over filename/mtime.
metamap="$(mktemp)"
if [ -n "$META" ] && [ -f "$META" ]; then
  awk -F'\t' 'NF>=4 {
    d=$1; p=$4; ss="";
    if (match(d, /\.[0-9]+$/)) { ss=substr(d, RSTART+1); d=substr(d, 1, RSTART-1) }
    if (match(d, /^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}/)) {
      day=substr(d,1,10); t=substr(d,12,8); gsub(/:/,"",t);
      print p "\t" day "\t" t "\t" ss
    }
  }' "$META" > "$metamap"
fi
meta_lookup() { awk -F'\t' -v p="$1" '$1==p {print $2"\t"$3"\t"$4; exit}' "$metamap" 2>/dev/null; }

# Pass 1: expand each class line into (album, src) pairs. A line whose second
# field is an INDEX SPEC (e.g. "1-16,19,22-26") + --shots is the COMPACT grouped
# form: indices into the shots list. Else it is a per-image filename/path.
pairs="$(mktemp)"
while IFS=$'\t' read -r album val rest; do
  [ -z "${album:-}" ] && continue
  case "$album" in \#*) continue;; esac
  [ -n "${val:-}" ] || continue
  if [ -n "$SHOTS" ] && printf '%s' "$val" | grep -qE '^[0-9,[:space:]-]+$'; then
    # printf '%s\n' (NOT '%s'): without the trailing newline the final `read` gets
    # the value but returns EOF-false, so a single-index "1" would expand to nothing.
    printf '%s\n' "$val" | tr ',' '\n' | while IFS= read -r tok; do
      tok="$(printf '%s' "$tok" | tr -d '[:space:]')"; [ -z "$tok" ] && continue
      if printf '%s' "$tok" | grep -qE '^[0-9]+-[0-9]+$'; then
        a="${tok%-*}"; b="${tok#*-}"; i="$a"
        while [ "$i" -le "$b" ]; do p="$(sed -n "${i}p" "$SHOTS")"; [ -n "$p" ] && printf '%s\t%s\n' "$album" "$p"; i=$((i + 1)); done
      elif printf '%s' "$tok" | grep -qE '^[0-9]+$'; then
        p="$(sed -n "${tok}p" "$SHOTS")"; [ -n "$p" ] && printf '%s\t%s\n' "$album" "$p"
      fi
    done
  else
    case "$val" in
      */*|*\\*) : ;;
      *) full="$(awk -F'\t' -v n="$val" '$1==n{print $2; exit}' "$namemap" 2>/dev/null)"; [ -n "$full" ] && val="$full" ;;
    esac
    printf '%s\t%s\n' "$album" "$val"
  fi
done < "$CLASS" >> "$pairs"

# Pass 2: date/time(+subsec) + dest naming per EXPANDED pair (album<TAB>src).
tmp="$(mktemp)"
while IFS=$'\t' read -r album src rest; do
  [ -z "${album:-}" ] && continue
  [ -n "${src:-}" ] || continue
  subsec=""
  m="$(meta_lookup "$src")"
  if [ -n "$m" ]; then
    date="$(printf '%s' "$m" | cut -f1)"; time="$(printf '%s' "$m" | cut -f2)"; subsec="$(printf '%s' "$m" | cut -f3)"
  elif [[ "$src" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2})[\ _T-]([0-9]{6}) ]]; then date="${BASH_REMATCH[1]}"; time="${BASH_REMATCH[2]}"
  elif [ -e "$src" ]; then
    if [[ "$src" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then date="${BASH_REMATCH[1]}"; else date="$(date -r "$src" +%Y-%m-%d 2>/dev/null || stat -f %Sm -t %Y-%m-%d "$src" 2>/dev/null || echo undated)"; fi
    time="$(date -r "$src" +%H%M%S 2>/dev/null || stat -f %Sm -t %H%M%S "$src" 2>/dev/null || echo 000000)"
  else date="undated"; time="000000"; fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$album" "$date" "$time" "$subsec" "$src" >> "$tmp"
done < "$pairs"
[ -s "$tmp" ] || { echo "MANIFEST_ERROR=no usable lines in --class"; rm -f "$tmp"; exit 1; }
[ -n "$BASE" ] || BASE="$(dirname "$(head -1 "$tmp" | cut -f5)")"

: > "$MANIFEST"
prev=""; n=0
while IFS= read -r row; do
  [ -n "$row" ] || continue
  # cut, NOT `IFS=tab read`: subsec is often empty, and tab is IFS-whitespace, so
  # read would FOLD the empty field and shift src into subsec (path ends up in the
  # name, src goes blank). cut keeps empty fields; -f5- captures src incl. any tabs.
  album="$(printf '%s' "$row" | cut -f1)"
  date="$(printf '%s' "$row" | cut -f2)"
  time="$(printf '%s' "$row" | cut -f3)"
  subsec="$(printf '%s' "$row" | cut -f4)"
  src="$(printf '%s' "$row" | cut -f5-)"
  # album may be a NESTED path (yyyy/mm/album); use the LEAF for the file name.
  leaf="${album##*/}"
  # FOLDER keeps any chronological "MM. " month prefix; the FILE name drops it
  # (the date already orders files): "06. Paris-..." -> "Paris-...".
  fileleaf="$(printf '%s' "$leaf" | sed -E 's/^(0[1-9]|1[0-2])\.[[:space:]]+//')"
  [ -n "$fileleaf" ] || fileleaf="$leaf"
  if [ -n "$subsec" ]; then stem="${fileleaf}-${date}-${time}-${subsec}"; else stem="${fileleaf}-${date}-${time}"; fi
  key="${album}|${stem}"
  if [ "$key" = "$prev" ]; then n=$((n + 1)); else n=1; prev="$key"; fi
  ext=".${src##*.}"
  if [ "$n" -eq 1 ]; then name="${stem}${ext}"; else name="${stem}-${n}${ext}"; fi
  printf '%s\t%s\t%s\n' "$OP" "$src" "$BASE/$album/$name" >> "$MANIFEST"
done < <(sort -t$'\t' -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 "$tmp")
rm -f "$tmp"

echo "MANIFEST_FILE=$MANIFEST"
echo "MANIFEST_COUNT=$(wc -l < "$MANIFEST" | tr -d ' ')"
[ -n "$batchinfo" ] && echo "$batchinfo"

# Coverage check vs the shots list: catch DROPPED (no album) or DOUBLE-assigned
# images. Safety net for any format, main guard for the compact index form.
if [ -n "$SHOTS" ] && [ -f "$SHOTS" ]; then
  assigned="$(cut -f2 "$pairs" | sort)"
  total="$(grep -c . "$SHOTS")"
  na="$(grep -c . "$pairs")"
  unassigned="$(comm -23 <(grep . "$SHOTS" | sort -u) <(printf '%s\n' "$assigned" | sort -u))"
  dups="$(printf '%s\n' "$assigned" | uniq -d)"
  nun="$(printf '%s' "$unassigned" | grep -c . || true)"
  ndup="$(printf '%s' "$dups" | grep -c . || true)"
  echo "MANIFEST_COVERAGE=assigned $na of $total; unassigned $nun; duplicated $ndup"
  printf '%s\n' "$unassigned" | grep . | while IFS= read -r u; do printf 'MANIFEST_UNASSIGNED\t%s\n' "$u"; done
  printf '%s\n' "$dups" | grep . | while IFS= read -r d; do printf 'MANIFEST_DUPLICATE\t%s\n' "$d"; done
fi
rm -f "$pairs" "$namemap" "$metamap"
cat "$MANIFEST"
