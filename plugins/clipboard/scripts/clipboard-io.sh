#!/usr/bin/env bash
# clipboard-io.sh - macOS/Linux clipboard I/O; mirror of clipboard-io.ps1.
#   read           (default) capture the clipboard and print a CLIP_KIND summary;
#                  payloads are written under ${TMPDIR:-/tmp}/runes-clip.
#   write <path>   set the clipboard to the UTF-8 text in <path>.
#
# Tools used (install if missing):
#   macOS : pbpaste / pbcopy (built in); pngpaste (brew) for clipboard images.
#   Linux : Wayland -> wl-clipboard (wl-paste/wl-copy); X11 -> xclip (or xsel, text only).
# NOTE: the Windows backend (.ps1) is the verified one; this script needs
# verification on macOS/Linux. Clipboard FILE lists are supported on Linux only
# (via text/uri-list); not on macOS (stated non-claim).
set -u

mode="${1:-read}"
dir="${TMPDIR:-/tmp}/runes-clip"
mkdir -p "$dir"
stamp="$(date +%Y%m%d-%H%M%S)-$$"
os="$(uname -s)"
have() { command -v "$1" >/dev/null 2>&1; }

# Resolve per-OS / per-session backends.
text_get=""; text_set=""; img_get=""; files_get=""; img_is_pngpaste=0
if [ "$os" = "Darwin" ]; then
    have pbpaste && text_get="pbpaste"
    have pbcopy && text_set="pbcopy"
    if have pngpaste; then img_get="pngpaste"; img_is_pngpaste=1; fi
elif [ -n "${WAYLAND_DISPLAY:-}" ] && have wl-paste; then
    text_get="wl-paste -n"
    text_set="wl-copy"
    img_get="wl-paste -t image/png"
    files_get="wl-paste -t text/uri-list -n"
elif have xclip; then
    text_get="xclip -selection clipboard -o"
    text_set="xclip -selection clipboard -i"
    img_get="xclip -selection clipboard -t image/png -o"
    files_get="xclip -selection clipboard -t text/uri-list -o"
elif have xsel; then
    text_get="xsel -b -o"
    text_set="xsel -b -i"
fi

if [ "$mode" = "write" ]; then
    path="${2:-}"
    if [ -z "$path" ] || [ ! -f "$path" ]; then echo "CLIP_WRITE=error: missing or unreadable path"; exit 1; fi
    if [ -z "$text_set" ]; then echo "CLIP_WRITE=error: no clipboard tool (install pbcopy / xclip / wl-clipboard)"; exit 1; fi
    $text_set < "$path"
    echo "CLIP_WRITE=ok"
    echo "CLIP_BYTES=$(wc -c < "$path" | tr -d ' ')"
    exit 0
fi

# read - priority: files (Linux) -> image -> text -> empty
if [ -n "$files_get" ]; then
    uris="$($files_get 2>/dev/null | tr -d '\r')"
    if [ -n "$uris" ]; then
        # file:// URIs -> decoded local paths
        paths="$(printf '%s\n' "$uris" | sed -n 's#^file://##p' | sed 's/%20/ /g')"
        if [ -n "$(printf '%s' "$paths" | tr -d '[:space:]')" ]; then
            echo "CLIP_KIND=files"
            echo "CLIP_COUNT=$(printf '%s\n' "$paths" | grep -c .)"
            printf '%s\n' "$paths" | grep .
            exit 0
        fi
    fi
fi

if [ -n "$img_get" ]; then
    out="$dir/clip-$stamp.png"
    if [ "$img_is_pngpaste" = "1" ]; then
        pngpaste "$out" >/dev/null 2>&1
    else
        $img_get > "$out" 2>/dev/null
    fi
    if [ -s "$out" ]; then echo "CLIP_KIND=image"; echo "CLIP_PATH=$out"; exit 0; fi
    rm -f "$out"
fi

if [ -n "$text_get" ]; then
    txt="$($text_get 2>/dev/null)"
    if [ -n "$(printf '%s' "$txt" | tr -d '[:space:]')" ]; then
        out="$dir/clip-$stamp.txt"
        printf '%s' "$txt" > "$out"
        echo "CLIP_KIND=text"
        echo "CLIP_PATH=$out"
        echo "CLIP_BYTES=$(wc -c < "$out" | tr -d ' ')"
        echo "CLIP_LINES=$(printf '%s\n' "$txt" | wc -l | tr -d ' ')"
        echo "----- preview -----"
        printf '%s\n' "$txt" | head -n 30
        exit 0
    fi
fi

if [ -z "$text_get" ]; then
    echo "CLIP_KIND=empty"
    echo "CLIP_NOTE=no clipboard tool found (install pbpaste / xclip / xsel / wl-clipboard)"
    exit 0
fi
echo "CLIP_KIND=empty"
