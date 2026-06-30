#!/usr/bin/env bash
# image-find - the image-file finder for the images pack (macOS/Linux backend;
# Windows backend is image-find.ps1). Locates image files in a folder by predicate
# (recency / name / recurse), with a sortable date (EXIF DateTimeOriginal else
# mtime) + optional hash, and Screenshots auto-detect. One tool for: recent
# screenshots (img), whole-tree find + hashes (img-dedup), recursive enumeration
# for re-organize (img-organize).
#   --count N --minutes X --today --yesterday --since STR --until STR
#   --within SPEC  calendar bucket (0=current,1=previous): t|today|0d, yesterday|1d, <N>h|d|w|m|y
#   --name SUB --dir PATH --recurse --no-video --no-audio --hash --outfile F --tsvfile F
#   --dir accepts a literal path OR the keyword `screenshots`/`downloads` (resolved to
#   the OS folders, incl. the Windows drive under WSL). Omit --dir = screenshots.
#   videos (mp4/mov/...) AND audio (mp3/m4a/wav/...) are matched BY DEFAULT so a
#   re-organize sweeps clips + voice memos into the trip's album, not leaves them
#   behind. --no-video / --no-audio opt out (e.g. an images-only scan).
#   --tsvfile F  also persist the full TSV to F (for build-manifest --meta).
# Prints IMG_DIR (each searched), IMG_COUNT, then TSV per file (newest first):
#   <yyyy-MM-dd HH:MM:SS[.fff]> \t <size> \t <sha1-or-empty> \t <path> \t <lat> \t <lon> \t <camera>
# date carries EXIF SubSecTimeOriginal (.fff) when present (burst ordering).
# GPS/camera/subsec always read (one exiftool call/file, alongside the date - free;
# blank without exiftool or on files with no EXIF). NOTE: the .ps1 is the verified backend.
set -u

count=0; minutes=0; today=0; yesterday=0; since=""; until_=""; within=""; name=""; dir=""; recurse=0; video=1; audio=1; hash=0; outfile=""; tsvfile=""
while [ $# -gt 0 ]; do
    case "$1" in
        --count) count="${2:-0}"; shift 2 ;;
        --minutes) minutes="${2:-0}"; shift 2 ;;
        --today) today=1; shift ;;
        --yesterday) yesterday=1; shift ;;
        --since) since="${2:-}"; shift 2 ;;
        --until) until_="${2:-}"; shift 2 ;;
        --within) within="${2:-}"; shift 2 ;;
        --name) name="${2:-}"; shift 2 ;;
        --dir) dir="${2:-}"; shift 2 ;;
        --recurse) recurse=1; shift ;;
        --no-video) video=0; shift ;;
        --no-audio) audio=0; shift ;;
        --hash) hash=1; shift ;;
        --outfile) outfile="${2:-}"; shift 2 ;;
        --tsvfile) tsvfile="${2:-}"; shift 2 ;;
        --hashcache) hashcache="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done
hashcache="${hashcache:-}"

# --dir accepts the special KEYWORDS `screenshots` / `downloads` (resolved to the OS
# folders, incl. the Windows drive when run under WSL) or a literal path; omitting
# --dir defaults to `screenshots`.
os="$(uname -s)"
key="${dir:-screenshots}"; keyl="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')"
cand=()
case "$keyl" in
  screenshot|screenshots)
    if [ "$os" = "Darwin" ]; then
        loc="$(defaults read com.apple.screencapture location 2>/dev/null || true)"
        [ -n "$loc" ] && cand+=("${loc/#\~/$HOME}")
        cand+=("$HOME/Desktop")
    fi
    [ -n "${XDG_PICTURES_DIR:-}" ] && cand+=("$XDG_PICTURES_DIR/Screenshots" "$XDG_PICTURES_DIR")
    cand+=("$HOME/Pictures/Screenshots" "$HOME/Pictures")
    [ -d /mnt/c/Users ] && for u in /mnt/c/Users/*/; do [ -d "${u}Pictures/Screenshots" ] && cand+=("${u}Pictures/Screenshots"); done
    ;;
  download|downloads)
    [ -n "${XDG_DOWNLOAD_DIR:-}" ] && cand+=("$XDG_DOWNLOAD_DIR")
    cand+=("$HOME/Downloads")
    [ -d /mnt/c/Users ] && for u in /mnt/c/Users/*/; do [ -d "${u}Downloads" ] && cand+=("${u}Downloads"); done
    ;;
  *)
    cand+=("$dir")
    ;;
esac

dirs=()
for d in "${cand[@]}"; do
    case " ${dirs[*]:-} " in *" $d "*) continue ;; esac
    [ -d "$d" ] && dirs+=("$d")
done
if [ ${#dirs[@]} -eq 0 ]; then
    echo "IMG_COUNT=0"; echo "IMG_NOTE=no folder resolved for '$key'; pass --dir <path> or the keywords screenshots/downloads"; exit 0
fi

gnu_date=0; date -d @0 +%s >/dev/null 2>&1 && gnu_date=1
now=$(date +%s)
to_epoch() { case "$1" in ''|*[!0-9]*) [ "$gnu_date" = 1 ] && date -d "$1" +%s 2>/dev/null ;; *) echo "$1" ;; esac; }
day_start() { if [ "$gnu_date" = 1 ]; then date -d 'today 00:00' +%s 2>/dev/null; else date -v0H -v0M -v0S +%s 2>/dev/null; fi; }
period_start() {
    case "$1" in
        h) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-%m-%d) $(date +%H):00:00" +%s 2>/dev/null; else date -v0M -v0S +%s 2>/dev/null; fi ;;
        d) day_start ;;
        w) if [ "$gnu_date" = 1 ]; then dow=$(date +%u); date -d "today 00:00 -$((dow - 1)) days" +%s 2>/dev/null; else date -v-mon -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
        m) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-%m-01) 00:00" +%s 2>/dev/null; else date -v1d -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
        y) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-01-01) 00:00" +%s 2>/dev/null; else date -v1m -v1d -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
    esac
}
shift_back() {
    if [ "$gnu_date" = 1 ]; then
        base="$(date -d "@$2" +'%Y-%m-%dT%H:%M:%S' 2>/dev/null)"
        case "$1" in
            h) date -d "$base -$3 hours" +%s 2>/dev/null ;; d) date -d "$base -$3 days" +%s 2>/dev/null ;;
            w) date -d "$base -$(($3 * 7)) days" +%s 2>/dev/null ;; m) date -d "$base -$3 months" +%s 2>/dev/null ;;
            y) date -d "$base -$3 years" +%s 2>/dev/null ;;
        esac
    else
        case "$1" in
            h) date -v-"$3"H -r "$2" +%s 2>/dev/null ;; d) date -v-"$3"d -r "$2" +%s 2>/dev/null ;;
            w) date -v-"$(($3 * 7))"d -r "$2" +%s 2>/dev/null ;; m) date -v-"$3"m -r "$2" +%s 2>/dev/null ;;
            y) date -v-"$3"y -r "$2" +%s 2>/dev/null ;;
        esac
    fi
}
if stat -c '%Y' . >/dev/null 2>&1; then mtime() { stat -c '%Y' "$1" 2>/dev/null; }; else mtime() { stat -f '%m' "$1" 2>/dev/null; }; fi
# tier-0 cache signature: size_mtime_ctime_inode. inode is the file-IDENTITY term
# (a different file at the same path gets a new inode), so "same path/size/mtime,
# different file" still misses the cache. GNU %Z / BSD %c = ctime; %i = inode.
if stat -c '%s' . >/dev/null 2>&1; then file_sig() { stat -c '%s_%Y_%Z_%i' "$1" 2>/dev/null; }; else file_sig() { stat -f '%z_%m_%c_%i' "$1" 2>/dev/null; }; fi

lo=0; hi=99999999999
[ "$minutes" -gt 0 ] && { c=$((now - minutes * 60)); [ "$c" -gt "$lo" ] && lo=$c; }
if [ "$today" = 1 ]; then ds=$(day_start); [ -n "$ds" ] && [ "$ds" -gt "$lo" ] && lo=$ds; fi
if [ "$yesterday" = 1 ]; then ds=$(day_start); [ -n "$ds" ] && { y=$((ds - 86400)); [ "$y" -gt "$lo" ] && lo=$y; [ "$ds" -lt "$hi" ] && hi=$ds; }; fi
if [ -n "$since" ]; then e=$(to_epoch "$since"); [ -n "$e" ] && [ "$e" -gt "$lo" ] && lo=$e; fi
if [ -n "$until_" ]; then e=$(to_epoch "$until_"); [ -n "$e" ] && [ "$e" -lt "$hi" ] && hi=$e; fi
if [ -n "$within" ]; then
    w="$(printf '%s' "$within" | tr '[:upper:]' '[:lower:]')"
    if [ "$w" = "today" ] || [ "$w" = "t" ]; then ds=$(day_start); [ -n "$ds" ] && [ "$ds" -gt "$lo" ] && lo=$ds
    elif [ "$w" = "yesterday" ]; then ds=$(day_start); [ -n "$ds" ] && { y=$((ds - 86400)); [ "$y" -gt "$lo" ] && lo=$y; [ "$ds" -lt "$hi" ] && hi=$ds; }
    else
        n="$(printf '%s' "$w" | sed -n 's/^\([0-9][0-9]*\)[hdwmy]$/\1/p')"
        u="$(printf '%s' "$w" | sed -n 's/^[0-9][0-9]*\([hdwmy]\)$/\1/p')"
        if [ -n "$n" ] && [ -n "$u" ]; then
            cur=$(period_start "$u")
            if [ -n "$cur" ]; then
                lob=$(shift_back "$u" "$cur" "$n"); [ -n "$lob" ] && [ "$lob" -gt "$lo" ] && lo=$lob
                if [ "$n" -ge 1 ]; then hib=$(shift_back "$u" "$cur" "$((n - 1))"); [ -n "$hib" ] && [ "$hib" -lt "$hi" ] && hi=$hib; fi
            fi
        fi
    fi
fi

name_lc="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr -d '*')"
maxdepth=""; [ "$recurse" = 0 ] && maxdepth="-maxdepth 1"

emit=""; skipped=0; TAB="$(printf '\t')"
for d in "${dirs[@]}"; do
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        # _duplicates = the perceptual-duplicate archive (special handling): never
        # scanned, so it is not re-organized / re-flagged / used as a routing ref.
        case "$f" in */_duplicates/*) continue ;; esac
        # A tab in a path would corrupt the TSV; skip + warn. (Newlines in
        # filenames are a known limit of this line-based find - would need -print0.)
        case "$f" in *"$TAB"*) skipped=$((skipped + 1)); continue ;; esac
        if [ -n "$name_lc" ]; then
            b="$(printf '%s' "${f##*/}" | tr '[:upper:]' '[:lower:]')"
            case "$b" in *"$name_lc"*) : ;; *) continue ;; esac
        fi
        m="$(mtime "$f")"; [ -n "$m" ] || continue
        [ "$m" -ge "$lo" ] && [ "$m" -le "$hi" ] && emit="$emit$m	$f
"
    done <<EOF
$(find "$d" $maxdepth -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' -o -iname '*.heif' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.webp' \) 2>/dev/null
[ "$video" = 1 ] && find "$d" $maxdepth -type f \( -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.avi' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.3gp' -o -iname '*.3g2' -o -iname '*.wmv' -o -iname '*.mpg' -o -iname '*.mpeg' -o -iname '*.mts' -o -iname '*.m2ts' \) 2>/dev/null
[ "$audio" = 1 ] && find "$d" $maxdepth -type f \( -iname '*.mp3' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.aac' -o -iname '*.ogg' -o -iname '*.oga' -o -iname '*.opus' -o -iname '*.flac' -o -iname '*.wma' -o -iname '*.amr' -o -iname '*.aiff' -o -iname '*.aif' \) 2>/dev/null)
EOF
done

sorted="$(printf '%s' "$emit" | grep . | sort -rn | cut -f2-)"

anyfilter=0
{ [ "$count" -gt 0 ] || [ "$minutes" -gt 0 ] || [ "$today" = 1 ] || [ "$yesterday" = 1 ] || [ -n "$since" ] || [ -n "$until_" ] || [ -n "$within" ] || [ -n "$name" ] || [ -n "$dir" ]; } && anyfilter=1
[ "$anyfilter" = 0 ] && count=1
[ "$count" -gt 0 ] && sorted="$(printf '%s\n' "$sorted" | grep . | head -n "$count")"

for d in "${dirs[@]}"; do echo "IMG_DIR=$d"; done
echo "IMG_COUNT=$(printf '%s\n' "$sorted" | grep -c .)"
[ "$video" = 1 ] && echo "IMG_VIDEOS=$(printf '%s\n' "$sorted" | grep -ciE '\.(mp4|mov|m4v|avi|mkv|webm|3gp|3g2|wmv|mpg|mpeg|mts|m2ts)$')"
[ "$audio" = 1 ] && echo "IMG_AUDIO=$(printf '%s\n' "$sorted" | grep -ciE '\.(mp3|m4a|wav|aac|ogg|oga|opus|flac|wma|amr|aiff|aif)$')"
[ "$skipped" -gt 0 ] && echo "IMG_SKIPPED=$skipped (path contains tab)"
# Asking for the paths file always emits the sibling scan.tsv too (EXIF/GPS is
# computed regardless) so the cluster step never finds it missing.
[ -n "$outfile" ] && [ -z "$tsvfile" ] && tsvfile="$(dirname "$outfile")/scan.tsv"
[ -n "$outfile" ] && { printf '%s\n' "$sorted" | grep . > "$outfile"; echo "IMG_OUTFILE=$outfile"; }

# TSV per file. ONE exiftool call/file fetches date + sub-second + GPS + camera
# together (free alongside the date); mtime fallback for the date. SubSecTimeOriginal
# appended as `.fff` for burst ordering. --tsvfile persists this for build-manifest -Meta.
have_exif=0; command -v exiftool >/dev/null 2>&1 && have_exif=1
# Date from FILENAME for EXIF-stripped files (WhatsApp re-encodes away EXIF+GPS;
# screenshots/Signal keep the date only in the name). Used AFTER exiftool, BEFORE
# mtime (mtime of a shared file is the save date, not capture). Echoes
# "YYYY-MM-DD HH:MM:SS" or nothing. Date-only patterns get 00:00:00 so a day groups.
name_date() {
  b="$(basename "$1")"
  d="$(printf '%s' "$b" | sed -n -E 's/.*(20[0-9]{2})[-_]?([0-9]{2})[-_]?([0-9]{2})[-_ T]+([0-9]{2})[-_:.]?([0-9]{2})[-_:.]?([0-9]{2}).*/\1-\2-\3 \4:\5:\6/p' | head -n1)"
  [ -n "$d" ] && { printf '%s' "$d"; return; }
  d="$(printf '%s' "$b" | sed -n -E 's/.*(20[0-9]{2})-([0-9]{2})-([0-9]{2}).*/\1-\2-\3 00:00:00/p' | head -n1)"
  [ -n "$d" ] && { printf '%s' "$d"; return; }
  printf '%s' "$b" | sed -n -E 's/.*(20[0-9]{2})([0-9]{2})([0-9]{2}).*/\1-\2-\3 00:00:00/p' | head -n1
}
# tier-0 cache (REBUILT this run, self-pruning): new entries go to $hcnew, then the
# old file is replaced after emit_tsv. Lookup reads the OLD $hashcache by path+sig.
hcnew=""; if [ -n "$hashcache" ] && [ "$hash" = 1 ]; then hcnew="$(mktemp)"; : > "$hcnew"; fi
emit_tsv() {
  printf '%s\n' "$sorted" | grep . | while IFS= read -r f; do
    dt=""; ss=""; lat=""; lon=""; cam=""
    if [ "$have_exif" = 1 ]; then
        ex="$(exiftool -s3 -n -d '%Y-%m-%d %H:%M:%S' -DateTimeOriginal -SubSecTimeOriginal -GPSLatitude -GPSLongitude -Model "$f" 2>/dev/null)"
        dt="$(printf '%s\n' "$ex" | sed -n '1p')"; ss="$(printf '%s\n' "$ex" | sed -n '2p')"
        lat="$(printf '%s\n' "$ex" | sed -n '3p')"; lon="$(printf '%s\n' "$ex" | sed -n '4p')"; cam="$(printf '%s\n' "$ex" | sed -n '5p')"
    fi
    [ -z "$dt" ] && dt="$(name_date "$f")"
    if [ -z "$dt" ]; then
        m="$(mtime "$f")"
        if [ "$gnu_date" = 1 ]; then dt="$(date -d "@$m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"; else dt="$(date -r "$m" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"; fi
    fi
    ss="$(printf '%s' "$ss" | tr -cd '0-9')"; [ -n "$ss" ] && dt="$dt.$(printf '%s000' "$ss" | cut -c1-3)"
    sz="$(wc -c < "$f" 2>/dev/null | tr -d ' ')"
    h=""
    if [ "$hash" = 1 ]; then
      if [ -n "$hashcache" ]; then
        sig="$(file_sig "$f")"
        h="$(awk -F'\t' -v p="$f" -v sg="$sig" '$1==p && $2==sg{print $3; exit}' "$hashcache" 2>/dev/null)"
        [ -n "$h" ] || h="$( (command -v shasum >/dev/null 2>&1 && shasum -a1 "$f" || sha1sum "$f") 2>/dev/null | awk '{print $1}')"
        printf '%s\t%s\t%s\n' "$f" "$sig" "$h" >> "$hcnew"
      else
        h="$( (command -v shasum >/dev/null 2>&1 && shasum -a1 "$f" || sha1sum "$f") 2>/dev/null | awk '{print $1}')"
      fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$dt" "$sz" "$h" "$f" "$lat" "$lon" "$cam"
  done
}
if [ -n "$tsvfile" ]; then emit_tsv | tee "$tsvfile"; echo "IMG_TSVFILE=$tsvfile"; else emit_tsv; fi
if [ -n "$hcnew" ]; then mv -f "$hcnew" "$hashcache"; echo "IMG_HASHCACHE=$hashcache"; fi
