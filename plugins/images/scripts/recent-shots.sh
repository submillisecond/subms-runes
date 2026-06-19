#!/usr/bin/env bash
# recent-shots.sh - macOS/Linux recent-screenshot finder; mirror of recent-shots.ps1.
# Selection (combine; with none given, returns the single most recent):
#   --count N     last N (after the other filters)
#   --minutes X   modified within the last X minutes
#   --today       modified today
#   --yesterday   modified yesterday
#   --since STR   modified at/after STR (GNU date string, or epoch seconds)
#   --until STR   modified at/before STR (GNU date string, or epoch seconds)
#   --within SPEC calendar bucket (0=current,1=previous): t|today|0d, yesterday|1d, <N>h|d|w|m|y
#   --name SUB    filename contains SUB (case-insensitive)
#   --dir PATH    search here instead of the auto-detected Screenshots folders
# Prints SHOTS_DIR (each searched), SHOTS_COUNT, then one absolute path per line
# (newest first). Lists only; never moves or modifies files.
# NOTE: the Windows backend (.ps1) is the verified one; verify this on macOS/Linux.
set -u

count=0; minutes=0; today=0; yesterday=0; since=""; until_=""; within=""; name=""; dir=""
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
        *) shift ;;
    esac
done

os="$(uname -s)"
cand=()
if [ -n "$dir" ]; then
    cand+=("$dir")
elif [ "$os" = "Darwin" ]; then
    loc="$(defaults read com.apple.screencapture location 2>/dev/null || true)"
    [ -n "$loc" ] && cand+=("${loc/#\~/$HOME}")
    cand+=("$HOME/Desktop")
else
    [ -n "${XDG_PICTURES_DIR:-}" ] && cand+=("$XDG_PICTURES_DIR/Screenshots" "$XDG_PICTURES_DIR")
    cand+=("$HOME/Pictures/Screenshots" "$HOME/Pictures")
fi

dirs=()
for d in "${cand[@]}"; do
    case " ${dirs[*]:-} " in *" $d "*) continue ;; esac
    [ -d "$d" ] && dirs+=("$d")
done
if [ ${#dirs[@]} -eq 0 ]; then
    echo "SHOTS_COUNT=0"; echo "SHOTS_NOTE=no Screenshots folder found; pass --dir <path>"; exit 0
fi

# epoch helpers (GNU date -d, else BSD date -v / numeric passthrough)
gnu_date=0; date -d @0 +%s >/dev/null 2>&1 && gnu_date=1
now=$(date +%s)
to_epoch() {
    case "$1" in ''|*[!0-9]*) : ;; *) echo "$1"; return ;; esac
    [ "$gnu_date" = 1 ] && date -d "$1" +%s 2>/dev/null
}
day_start() {
    if [ "$gnu_date" = 1 ]; then date -d 'today 00:00' +%s 2>/dev/null
    else date -v0H -v0M -v0S +%s 2>/dev/null; fi
}
period_start() { # $1 unit -> epoch of the CURRENT period's start
    case "$1" in
        h) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-%m-%d) $(date +%H):00:00" +%s 2>/dev/null; else date -v0M -v0S +%s 2>/dev/null; fi ;;
        d) day_start ;;
        w) if [ "$gnu_date" = 1 ]; then dow=$(date +%u); date -d "today 00:00 -$((dow - 1)) days" +%s 2>/dev/null; else date -v-mon -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
        m) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-%m-01) 00:00" +%s 2>/dev/null; else date -v1d -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
        y) if [ "$gnu_date" = 1 ]; then date -d "$(date +%Y-01-01) 00:00" +%s 2>/dev/null; else date -v1m -v1d -v0H -v0M -v0S +%s 2>/dev/null; fi ;;
    esac
}
shift_back() { # $1 unit  $2 start-epoch  $3 k(>=0) -> epoch shifted back k periods
    if [ "$gnu_date" = 1 ]; then
        base="$(date -d "@$2" +'%Y-%m-%dT%H:%M:%S' 2>/dev/null)"
        case "$1" in
            h) date -d "$base -$3 hours" +%s 2>/dev/null ;;
            d) date -d "$base -$3 days" +%s 2>/dev/null ;;
            w) date -d "$base -$(($3 * 7)) days" +%s 2>/dev/null ;;
            m) date -d "$base -$3 months" +%s 2>/dev/null ;;
            y) date -d "$base -$3 years" +%s 2>/dev/null ;;
        esac
    else
        case "$1" in
            h) date -v-"$3"H -r "$2" +%s 2>/dev/null ;;
            d) date -v-"$3"d -r "$2" +%s 2>/dev/null ;;
            w) date -v-"$(($3 * 7))"d -r "$2" +%s 2>/dev/null ;;
            m) date -v-"$3"m -r "$2" +%s 2>/dev/null ;;
            y) date -v-"$3"y -r "$2" +%s 2>/dev/null ;;
        esac
    fi
}
if stat -c '%Y' . >/dev/null 2>&1; then mtime() { stat -c '%Y' "$1" 2>/dev/null; }
else mtime() { stat -f '%m' "$1" 2>/dev/null; }; fi

lo=0; hi=99999999999
[ "$minutes" -gt 0 ] && { c=$((now - minutes * 60)); [ "$c" -gt "$lo" ] && lo=$c; }
if [ "$today" = 1 ]; then ds=$(day_start); [ -n "$ds" ] && [ "$ds" -gt "$lo" ] && lo=$ds; fi
if [ "$yesterday" = 1 ]; then ds=$(day_start); [ -n "$ds" ] && { y=$((ds - 86400)); [ "$y" -gt "$lo" ] && lo=$y; [ "$ds" -lt "$hi" ] && hi=$ds; }; fi
if [ -n "$since" ]; then e=$(to_epoch "$since"); [ -n "$e" ] && [ "$e" -gt "$lo" ] && lo=$e; fi
if [ -n "$until_" ]; then e=$(to_epoch "$until_"); [ -n "$e" ] && [ "$e" -lt "$hi" ] && hi=$e; fi
if [ -n "$within" ]; then
    # Calendar bucket: 0 = current period, 1 = previous (0d=today, 1d=yesterday).
    w="$(printf '%s' "$within" | tr '[:upper:]' '[:lower:]')"
    if [ "$w" = "today" ] || [ "$w" = "t" ]; then
        ds=$(day_start); [ -n "$ds" ] && [ "$ds" -gt "$lo" ] && lo=$ds
    elif [ "$w" = "yesterday" ]; then
        ds=$(day_start); [ -n "$ds" ] && { y=$((ds - 86400)); [ "$y" -gt "$lo" ] && lo=$y; [ "$ds" -lt "$hi" ] && hi=$ds; }
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

emit=""
for d in "${dirs[@]}"; do
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        if [ -n "$name_lc" ]; then
            b="$(printf '%s' "${f##*/}" | tr '[:upper:]' '[:lower:]')"
            case "$b" in *"$name_lc"*) : ;; *) continue ;; esac
        fi
        m="$(mtime "$f")"; [ -n "$m" ] || continue
        [ "$m" -ge "$lo" ] && [ "$m" -le "$hi" ] && emit="$emit$m	$f
"
    done <<EOF
$(find "$d" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null)
EOF
done

sorted="$(printf '%s' "$emit" | grep . | sort -rn | cut -f2-)"

anyfilter=0
{ [ "$count" -gt 0 ] || [ "$minutes" -gt 0 ] || [ "$today" = 1 ] || [ "$yesterday" = 1 ] || [ -n "$since" ] || [ -n "$until_" ] || [ -n "$within" ] || [ -n "$name" ]; } && anyfilter=1
[ "$anyfilter" = 0 ] && count=1
[ "$count" -gt 0 ] && sorted="$(printf '%s\n' "$sorted" | grep . | head -n "$count")"

for d in "${dirs[@]}"; do echo "SHOTS_DIR=$d"; done
echo "SHOTS_COUNT=$(printf '%s\n' "$sorted" | grep -c .)"
printf '%s\n' "$sorted" | grep . || true
