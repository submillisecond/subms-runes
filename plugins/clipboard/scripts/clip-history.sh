#!/usr/bin/env bash
# clip-history: .sh port of clip-history.ps1 (opt-in history, secrets never stored).
# Verbs, store layout and output: ../contract/CONTRACTS.md.
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="${XDG_DATA_HOME:-$HOME/.local/share}/runes/clipboard/history"
index="$root/index.tsv"; flag="$root/.enabled"

ensure() { if [ ! -d "$root" ]; then mkdir -p "$root"; chmod 700 "$root" 2>/dev/null; fi; }
enabled() { [ "${RUNES_CLIP_HISTORY:-}" = "1" ] || [ -f "$flag" ]; }
preview() { printf '%s' "$1" | tr '\t\r\n' '   ' | cut -c1-100; }

verb="${1:-status}"; shift || true
KIND=text; SUBTYPE=plain; SOURCE=clip; PATH_IN=""; ID=""; QUERY=""; COUNT=20
while [ $# -gt 0 ]; do case "$1" in
  --kind) KIND="$2"; shift 2;; --subtype) SUBTYPE="$2"; shift 2;;
  --source) SOURCE="$2"; shift 2;; --path) PATH_IN="$2"; shift 2;;
  --id) ID="$2"; shift 2;; --query) QUERY="$2"; shift 2;; --count) COUNT="$2"; shift 2;;
  *) shift;; esac; done

case "$verb" in
  enable)  ensure; : > "$flag"; echo "HISTORY_ENABLED=1";;
  disable) rm -f "$flag"; echo "HISTORY_ENABLED=0";;
  status)
    echo "HISTORY_ENABLED=$(enabled && echo 1 || echo 0)"
    echo "HISTORY_DIR=$root"
    echo "HISTORY_COUNT=$([ -f "$index" ] && grep -c . "$index" || echo 0)";;
  add)
    enabled || { echo "HISTORY_SKIPPED=disabled"; exit 0; }
    [ -n "$PATH_IN" ] && [ -f "$PATH_IN" ] || { echo "HISTORY_ERROR=missing --path"; exit 0; }
    ensure
    maxb="${RUNES_HISTORY_MAX_BYTES:-1048576}"
    len="$(wc -c < "$PATH_IN" | tr -d ' ')"
    [ "$len" -gt "$maxb" ] && { echo "HISTORY_SKIPPED=too_large"; exit 0; }
    body=""; [ "$KIND" = text ] && body="$(cat "$PATH_IN")"
    if [ -n "${RUNES_HISTORY_EXCLUDE:-}" ] && printf '%s' "$body" | grep -qE "$RUNES_HISTORY_EXCLUDE"; then echo "HISTORY_SKIPPED=excluded"; exit 0; fi
    if [ "$KIND" = text ]; then
      . "$DIR/secret-scan.sh"; find_secrets "$PATH_IN"
      [ "${FS_COUNT:-0}" -gt 0 ] && { echo "HISTORY_SKIPPED=secret:$FS_TYPES"; exit 0; }
    fi
    eid="$(date +%Y%m%d-%H%M%S)-$$"; ext=".txt"; [ "$KIND" = image ] && ext=".png"; [ "$KIND" = files ] && ext=".files.txt"
    cp "$PATH_IN" "$root/$eid$ext"
    prev="$(preview "$body")"; [ "$KIND" != text ] && prev="[$KIND]"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$eid" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$KIND" "$SUBTYPE" "$len" "$SOURCE" "$prev" >> "$index"
    maxn="${RUNES_HISTORY_MAX_ENTRIES:-200}"
    n="$(grep -c . "$index")"
    if [ "$n" -gt "$maxn" ]; then
      head -n "$((n - maxn))" "$index" | cut -f1 | while read -r d; do rm -f "$root/$d".*; done
      tail -n "$maxn" "$index" > "$index.tmp" && mv "$index.tmp" "$index"
    fi
    echo "HISTORY_ADDED=$eid";;
  list)
    n="$([ -f "$index" ] && grep -c . "$index" || echo 0)"; echo "HISTORY_COUNT=$n"
    [ "$n" -gt 0 ] || exit 0
    tail -n "$COUNT" "$index" | tac | awk -F'\t' '{printf "#%d\t%s\t%s/%s\t%sB\t%s\t%s\n", NR, $1, $3, $4, $5, $6, $7}';;
  search)
    [ -f "$index" ] || { echo "HISTORY_MATCHES=0"; exit 0; }
    hits="$(grep -F "$QUERY" "$index")"; echo "HISTORY_MATCHES=$(printf '%s' "$hits" | grep -c . || true)"
    printf '%s\n' "$hits" | awk -F'\t' 'NF{printf "%s\t%s/%s\t%s\n", $1, $3, $4, $7}';;
  get)
    [ -f "$index" ] || { echo "HISTORY_ERROR=no such entry"; exit 0; }
    if printf '%s' "$ID" | grep -q '^#'; then
      k="${ID#\#}"; row="$(tac "$index" | sed -n "${k}p")"
    else
      row="$(grep -m1 "^${ID}	" "$index")"
    fi
    [ -n "$row" ] || { echo "HISTORY_ERROR=no such entry"; exit 0; }
    eid="$(printf '%s' "$row" | cut -f1)"; kind="$(printf '%s' "$row" | cut -f3)"
    cf="$(ls "$root/$eid".* 2>/dev/null | head -1)"
    [ -n "$cf" ] || { echo "HISTORY_ERROR=payload missing"; exit 0; }
    echo "HISTORY_ID=$eid"; echo "HISTORY_KIND=$kind"
    if [ "$kind" = text ]; then
      bash "$DIR/clipboard-io.sh" write "$cf" >/dev/null 2>&1
      echo "HISTORY_RECOPIED=clipboard"
      echo "-----BEGIN CLIP TEXT-----"; cat "$cf"; echo "-----END CLIP TEXT-----"
    else echo "HISTORY_PATH=$cf"; fi;;
  rm)
    eid="${ID#\#}"; rm -f "$root/$eid".*
    [ -f "$index" ] && { grep -v "^${eid}	" "$index" > "$index.tmp"; mv "$index.tmp" "$index"; }
    echo "HISTORY_REMOVED=$eid";;
  clear)
    [ -d "$root" ] && find "$root" -mindepth 1 ! -name '.enabled' -delete 2>/dev/null
    echo "HISTORY_CLEARED=1";;
  *) echo "HISTORY_ERROR=unknown verb '$verb'";;
esac
