#!/usr/bin/env bash
# contract-test - the executable spec. Asserts that the imageverse scripts STILL
# emit the documented shapes, so "is the spec accurate?" is a test run, not a
# manual audit. Runs BOTH backends (.ps1 via powershell.exe, .sh in place) against
# an ISOLATED temp store (XDG_DATA_HOME / LOCALAPPDATA are redirected, so your real
# caches are untouched). Exits non-zero on any drift.
#
# Checks: (1) canonical column counts; (2) image-index.ps1 $COLS matches
# captions.columns (script<->schema drift guard); (3) per-verb KEY=value output
# contract + column ORDER on both backends; (4) every verb/flag is documented in
# CONTRACTS.md (doc<->script drift guard); (5) the inline schema restatements in the
# operational SKILL.md docs match the .columns field counts (skill<->schema guard).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$(cd "$HERE/../scripts" && pwd)"
SKILLS="$(cd "$HERE/../skills" && pwd)"
. "$HERE/../../../lib/test/contract-lib.sh"   # assertions, isolated store, skill guard, result
contract_isolate
PS_CAP="$T/ps/runes/imageverse/index/captions.tsv"   # unix view of the .ps1 store

PS="powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SCRIPTS/image-index.ps1"
SH="bash $SCRIPTS/image-index.sh"

echo "== 1. canonical schema integrity =="
eq "captions.columns count" "$(grep -c . "$HERE/captions.columns")" "20"
eq "put.columns count" "$(grep -c . "$HERE/put.columns")" "11"
eq "imagefind.columns count" "$(grep -c . "$HERE/imagefind.columns")" "7"

echo "== 2. script<->schema drift guard (image-index.ps1 \$COLS == captions.columns) =="
pscols="$(awk '/\$COLS = @\(/{f=1} f{print} f&&/\)/{exit}' "$SCRIPTS/image-index.ps1" | grep -oE "'[a-z_]+'" | tr -d "'")"
# tr -d '\r' both sides: a Windows checkout (autocrlf) gives captions.columns CRLF
# while the awk/grep-extracted $COLS is LF - that is a line-ending mismatch, not drift.
if diff <(printf '%s\n' "$pscols" | tr -d '\r') <(tr -d '\r' < "$HERE/captions.columns") >/dev/null 2>&1; then ok; else bad "image-index.ps1 \$COLS drifted from captions.columns"; fi

# fixtures
SCAN="$T/scan.tsv"
printf '2026-06-10 10:00:00%s100%sHAAA%sC:/p/a.png%s48.8%s2.3%sPixel\n' "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" >  "$SCAN"
printf '2026-06-10 10:01:00%s100%sHBBB%sC:/p/b.png%s%s%s\n'              "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" >> "$SCAN"
BATCH="$T/put.tsv"
printf 'HAAA%sC:/p/a.png%sCATMARK%sphoto-scene%ssightseeing%sFrance/Paris%sEiffel%stower%sevening%sa caption%svisible text here\n' \
  "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" > "$BATCH"

# Run the full verb contract against one backend. $1 = label, $2 = invocation,
# $3 = flag style ("ps" uses -Tsv, "sh" uses --tsv), $4 = captions.tsv path.
backend() {
  local L="$1" RUN="$2" F="$3" CAP="$4"
  local T1 P1 Q1 ST PL FC PR CAPROW
  $RUN clear >/dev/null
  if [ "$F" = ps ]; then
    P1="$($RUN put -Batch "$BATCH" -Scan "$SCAN")"
    ST="$($RUN status -Tsv "$SCAN")"
    PL="$($RUN plan -Tsv "$SCAN")"
    Q1="$($RUN query -Tsv "$SCAN" -Query 'tower')"
    FC="$($RUN facets -Tsv "$SCAN")"
    CAPROW="$(awk -F'\t' 'NR==1' "$CAP")"   # capture BEFORE clear removes the file
    PR="$($RUN prune -Days 365)"
    T1="$($RUN clear)"
  else
    P1="$($RUN put --batch "$BATCH" --scan "$SCAN")"
    ST="$($RUN status --tsv "$SCAN")"
    PL="$($RUN plan --tsv "$SCAN")"
    Q1="$($RUN query --tsv "$SCAN" --query 'tower')"
    FC="$($RUN facets --tsv "$SCAN")"
    CAPROW="$(awk -F'\t' 'NR==1' "$CAP")"
    PR="$($RUN prune --days 365)"
    T1="$($RUN clear)"
  fi
  has "$L put"      "$P1" '^INDEX_PUT=1$'
  has "$L status"   "$ST" '^INDEX_CAPTIONS=1$'
  has "$L status"   "$ST" '^INDEX_(WARM|COLD)='
  has "$L plan"     "$PL" '^INDEX_COLD=1$'
  has "$L plan"     "$PL" '^INDEX_WARM='
  has "$L query"    "$Q1" '^INDEX_HITS=1$'
  has "$L query"    "$Q1" "^INDEX_HIT${TAB}1${TAB}"
  has "$L query"    "$Q1" "^INDEX_HIT_PATH${TAB}HAAA${TAB}"
  has "$L facets"   "$FC" '^INDEX_FACETS=1$'
  has "$L facets"   "$FC" "^INDEX_FACET${TAB}HAAA${TAB}"
  has "$L prune"    "$PR" '^INDEX_PRUNED='
  has "$L clear"    "$T1" '^INDEX_CLEARED=1$'
  # INDEX_HIT must carry 6 tab fields: marker,rank,score,hash,copies,snippet
  local hitcols; hitcols="$(printf '%s' "$Q1" | grep "^INDEX_HIT${TAB}" | head -1 | awk -F'\t' '{print NF}')"
  eq "$L INDEX_HIT field count" "$hitcols" "6"
  # INDEX_FACET must carry 8 tab fields
  local faccols; faccols="$(printf '%s' "$FC" | grep "^INDEX_FACET${TAB}" | head -1 | awk -F'\t' '{print NF}')"
  eq "$L INDEX_FACET field count" "$faccols" "8"
  # captions row: 20 cols, and col 13 (category) == the put marker -> column ORDER intact
  eq "$L captions col count" "$(printf '%s' "$CAPROW" | awk -F'\t' '{print NF}')" "20"
  eq "$L captions category position" "$(printf '%s' "$CAPROW" | awk -F'\t' '{print $13}')" "CATMARK"
}

echo "== 3a. .sh backend verb + column contract =="
# re-put after clear inside backend(); CAP path for .sh store:
backend ".sh" "$SH" sh "$XDG_DATA_HOME/runes/imageverse/index/captions.tsv"
echo "== 3b. .ps1 backend verb + column contract =="
backend ".ps1" "$PS" ps "$PS_CAP"

echo "== 4. doc<->script drift guard (every verb + flag documented in CONTRACTS.md) =="
DOC="$HERE/CONTRACTS.md"
if [ -f "$DOC" ]; then
  for v in status plan put query facets prune clear; do has "verb $v in CONTRACTS.md" "$(cat "$DOC")" "\b$v\b"; done
  # every --flag in image-index.sh must be documented
  for fl in $(grep -oE -- '--[a-z]+\)' "$SCRIPTS/image-index.sh" | tr -d ')' | sort -u); do
    if grep -qF -- "$fl" "$DOC"; then ok; else bad "flag $fl not in CONTRACTS.md"; fi
  done
else
  echo "  (CONTRACTS.md not present yet - skipping doc drift checks)"
fi

echo "== 5. SKILL.md inline schema restatements match .columns (skill<->schema drift guard) =="
skill_schema_guard "put-batch schema" '<hash>\t<path>\t<category>' "$HERE/put.columns"     "$SKILLS"
skill_schema_guard "image-find TSV"   '<date[.subsec]>\t<size>'    "$HERE/imagefind.columns" "$SKILLS"

contract_result
