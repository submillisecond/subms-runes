#!/usr/bin/env bash
# clip-snippet: .sh port of clip-snippet.ps1 (named snippets, secrets refused).
# Verbs, store layout and output: ../contract/CONTRACTS.md.
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${XDG_DATA_HOME:-$HOME/.local/share}/runes/clipboard/snippets"
index="$root/index.tsv"

ensure() { if [ ! -d "$root" ]; then mkdir -p "$root"; chmod 700 "$root" 2>/dev/null; fi; }
safe_name() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//'; }
preview() { printf '%s' "$1" | tr '\t\r\n' '   ' | cut -c1-100; }

verb="${1:-list}"; shift || true
NAME=""; KIND=text; SUBTYPE=plain; PATH_IN=""; QUERY=""
while [ $# -gt 0 ]; do case "$1" in
  --name) NAME="$2"; shift 2;; --kind) KIND="$2"; shift 2;; --subtype) SUBTYPE="$2"; shift 2;;
  --path) PATH_IN="$2"; shift 2;; --query) QUERY="$2"; shift 2;; *) shift;; esac; done

case "$verb" in
  save)
    key="$(safe_name "$NAME")"
    [ -n "$key" ] || { echo "SNIPPET_ERROR=missing/invalid --name"; exit 0; }
    [ -n "$PATH_IN" ] && [ -f "$PATH_IN" ] || { echo "SNIPPET_ERROR=missing --path"; exit 0; }
    isimg=0; case "$(printf '%s' "$PATH_IN" | tr '[:upper:]' '[:lower:]')" in *.png|*.jpg|*.jpeg|*.bmp|*.gif|*.tiff) isimg=1;; esac
    [ "$KIND" = image ] && isimg=1
    ensure
    rm -f "$root/$key".*   # replace any prior payload/kind
    if [ "$isimg" = 1 ]; then
      ext="${PATH_IN##*.}"; cp "$PATH_IN" "$root/$key.$ext"; prev="[image]"; rkind=image
    else
      . "$DIR/secret-scan.sh"; find_secrets "$PATH_IN"
      [ "${FS_COUNT:-0}" -gt 0 ] && { echo "SNIPPET_REFUSED=secret:$FS_TYPES"; exit 0; }
      cp "$PATH_IN" "$root/$key.txt"; prev="$(preview "$(cat "$PATH_IN")")"; rkind=text
    fi
    len="$(wc -c < "$PATH_IN" | tr -d ' ')"
    [ -f "$index" ] && grep -v "^${key}	" "$index" > "$index.tmp" 2>/dev/null && mv "$index.tmp" "$index"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$key" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$rkind" "$SUBTYPE" "$len" "$prev" >> "$index"
    LC_ALL=C sort -o "$index" "$index"
    echo "SNIPPET_SAVED=$key";;
  get)
    key="$(safe_name "$NAME")"; cf="$(ls "$root/$key".* 2>/dev/null | head -1)"
    [ -n "$cf" ] || { echo "SNIPPET_ERROR=no snippet named '$key'"; exit 0; }
    bash "$DIR/clipboard-io.sh" write "$cf" >/dev/null 2>&1
    echo "SNIPPET_NAME=$key"; echo "SNIPPET_RECOPIED=clipboard"
    case "$cf" in *.txt) echo "-----BEGIN CLIP TEXT-----"; cat "$cf"; echo "-----END CLIP TEXT-----";;
                  *) echo "SNIPPET_KIND=image"; echo "SNIPPET_PATH=$cf";; esac;;
  list)
    n="$([ -f "$index" ] && grep -c . "$index" || echo 0)"; echo "SNIPPET_COUNT=$n"
    [ "$n" -gt 0 ] && awk -F'\t' '{printf "%s\t%s/%s\t%sB\t%s\n", $1, $3, $4, $5, $6}' "$index";;
  search)
    [ -f "$index" ] || { echo "SNIPPET_MATCHES=0"; exit 0; }
    hits="$(grep -F "$QUERY" "$index")"
    echo "SNIPPET_MATCHES=$(printf '%s' "$hits" | grep -c . || true)"
    printf '%s\n' "$hits" | awk -F'\t' 'NF{printf "%s\t%s/%s\t%s\n", $1, $3, $4, $6}';;
  rm)
    key="$(safe_name "$NAME")"; rm -f "$root/$key".*
    [ -f "$index" ] && { grep -v "^${key}	" "$index" > "$index.tmp"; mv "$index.tmp" "$index"; }
    echo "SNIPPET_REMOVED=$key";;
  clear)
    [ -d "$root" ] && find "$root" -mindepth 1 -delete 2>/dev/null
    echo "SNIPPET_CLEARED=1";;
  *) echo "SNIPPET_ERROR=unknown verb '$verb'";;
esac
