#!/usr/bin/env bash
# contract-test: run both backends against an isolated store and fail when output, schemas or CONTRACTS.md drift.
# The live clipboard (clipboard-io, get) is out of scope.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/../scripts" && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"   # assertions, isolated store, result
contract_isolate
export RUNES_CLIP_HISTORY=1   # history is opt-in; enable it for the isolated test store

PAY="$T/pay.txt"; printf 'hello world snippet body\n' > "$PAY"   # no secrets -> not refused

echo "== 1. canonical schema integrity =="
eq "history.columns count" "$(grep -c . "$HERE/history.columns")" "7"
eq "snippet.columns count" "$(grep -c . "$HERE/snippet.columns")" "6"

# $1 label, $2 ps|sh, $3 history index path, $4 snippet index path
backend() {
  local L="$1" F="$2" HIDX="$3" SIDX="$4"
  local HADD HLIST HSRCH HSTAT HRM HCLR SSAVE SLIST SSRCH SRM SCLR HROW SROW
  local H S
  if [ "$F" = ps ]; then
    H="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SCRIPTS/clip-history.ps1"
    S="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SCRIPTS/clip-snippet.ps1"
    $H clear >/dev/null
    HADD="$($H add -Kind text -Subtype plain -Source test -Path "$PAY")"
    HLIST="$($H list)"; HSRCH="$($H search -Query hello)"; HSTAT="$($H status)"
    HROW="$(awk 'NR==1' "$HIDX" 2>/dev/null)"
    HRM=""; HCLR="$($H clear)"
    $S clear >/dev/null
    SSAVE="$($S save -Name testsnip -Subtype plain -Path "$PAY")"
    SLIST="$($S list)"; SSRCH="$($S search -Query hello)"
    SROW="$(awk 'NR==1' "$SIDX" 2>/dev/null)"
    SCLR="$($S clear)"
  else
    H="bash $SCRIPTS/clip-history.sh"
    S="bash $SCRIPTS/clip-snippet.sh"
    $H clear >/dev/null
    HADD="$($H add --kind text --subtype plain --source test --path "$PAY")"
    HLIST="$($H list)"; HSRCH="$($H search --query hello)"; HSTAT="$($H status)"
    HROW="$(awk 'NR==1' "$HIDX" 2>/dev/null)"
    HCLR="$($H clear)"
    $S clear >/dev/null
    SSAVE="$($S save --name testsnip --subtype plain --path "$PAY")"
    SLIST="$($S list)"; SSRCH="$($S search --query hello)"
    SROW="$(awk 'NR==1' "$SIDX" 2>/dev/null)"
    SCLR="$($S clear)"
  fi
  has "$L history add"    "$HADD"  '^HISTORY_ADDED='
  has "$L history list"   "$HLIST" '^HISTORY_COUNT=1$'
  has "$L history search" "$HSRCH" '^HISTORY_MATCHES=1$'
  has "$L history status" "$HSTAT" '^HISTORY_ENABLED=1$'
  has "$L history status" "$HSTAT" '^HISTORY_DIR='
  has "$L history clear"  "$HCLR"  '^HISTORY_CLEARED=1$'
  has "$L snippet save"   "$SSAVE" '^SNIPPET_SAVED=testsnip$'
  has "$L snippet list"   "$SLIST" '^SNIPPET_COUNT=1$'
  has "$L snippet search" "$SSRCH" '^SNIPPET_MATCHES=1$'
  has "$L snippet clear"  "$SCLR"  '^SNIPPET_CLEARED=1$'
  # index row column counts == canonical schema (script<->schema drift guard)
  eq "$L history index cols" "$(printf '%s' "$HROW" | awk -F'\t' '{print NF}')" "7"
  eq "$L snippet index cols" "$(printf '%s' "$SROW" | awk -F'\t' '{print NF}')" "6"
}

echo "== 2/3a. .sh backend verb + column contract =="
backend ".sh" sh "$XDG_DATA_HOME/runes/clipboard/history/index.tsv" "$XDG_DATA_HOME/runes/clipboard/snippets/index.tsv"
echo "== 2/3b. .ps1 backend verb + column contract =="
ps_backend && backend ".ps1" ps "$T/ps/runes/clipboard/history/index.tsv" "$T/ps/runes/clipboard/snippets/index.tsv"

echo "== 3c. redaction removes every secret, both backends =="
# Two kinds of secret in one text; the .ps1 once leaked the tail of the second. The AWS key is AWS's published example.
SEC='key AKIAIOSFODNN7EXAMPLE and PASSWORD = "abcdefghijklmnop1234" end'
redact_check() {
  local L="$1" OUT="$2" BODY
  BODY="$(printf '%s\n' "$OUT" | sed -n '/^-----BEGIN REDACTED-----$/,/^-----END REDACTED-----$/p')"
  has "$L redact count" "$OUT" '^CLIP_SECRET_COUNT=2$'
  has "$L redact aws tag" "$BODY" '\[REDACTED:aws-access-key\]'
  has "$L redact assignment tag" "$BODY" '\[REDACTED:generic-secret-assignment\]'
  has "$L redact keeps the text around it" "$BODY" '^key \[REDACTED:aws-access-key\] and \[REDACTED'
  if printf '%s' "$BODY" | grep -qE 'AKIAIOSFODNN7EXAMPLE|abcdefghijklmnop|1234'; then bad "$L redact leaked part of a secret: $BODY"; else ok; fi
  eq "$L redact body is 3 lines" "$(printf '%s\n' "$BODY" | wc -l | tr -d ' ')" "3"
}
redact_check ".sh" "$(bash "$SCRIPTS/secret-scan.sh" --text "$SEC" --redact)"
if ps_backend; then
  redact_check ".ps1" "$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPTS/secret-scan.ps1" -Text "$SEC" -Redact | tr -d '\r')"
fi

echo "== 4. doc<->script drift guard (every verb documented in CONTRACTS.md) =="
DOC="$HERE/CONTRACTS.md"
if [ -f "$DOC" ]; then
  for v in enable disable status add list search get rm clear; do has "history verb $v" "$(cat "$DOC")" "\b$v\b"; done
  for v in save get list search rm clear; do has "snippet verb $v" "$(cat "$DOC")" "\b$v\b"; done
  for k in CLIP_KIND CLIP_PATH CLIP_WRITE HISTORY_ADDED SNIPPET_SAVED; do has "key $k" "$(cat "$DOC")" "$k"; done
else
  echo "  (CONTRACTS.md not present yet - skipping doc drift checks)"
fi

contract_result
