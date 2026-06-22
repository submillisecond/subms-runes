#!/usr/bin/env bash
# contract-lib - shared scaffolding for the per-pack contract-test.sh executable
# specs (`plugins/<pack>/contract/contract-test.sh`). SOURCED, never run.
#
# This is REPO-LEVEL TEST tooling only. Plugin RUNTIME scripts cannot share code -
# plugin isolation copies each pack's own scripts under ${CLAUDE_PLUGIN_ROOT} - so
# this never ships inside a plugin; it stays in subms-runes (NOT subms-infra: the
# contract tests run in this repo's CI and must not depend on the private operator
# repo). It provides: assertion helpers + counters, an isolated temp store (so real
# caches are untouched), the generic SKILL<->.columns drift guard, and the finish.
#
# Usage from a pack's contract-test.sh:
#   HERE="$(cd "$(dirname "$0")" && pwd)"
#   . "$HERE/../../../lib/contract-lib.sh"
#   contract_isolate          # sets $T, exports XDG_DATA_HOME + LOCALAPPDATA
#   ... eq/has/skill_schema_guard ...
#   contract_result           # prints RESULT, cleans $T, exits non-zero on any FAIL

PASS=0; FAIL=0
TAB="$(printf '\t')"
ok()  { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "FAIL: $*"; }
eq()  { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }
has() { if printf '%s' "$2" | grep -qE "$3"; then ok; else bad "$1: missing /$3/"; fi; }

# Mint an isolated store and redirect the data-dir env vars so the live caches are
# untouched: XDG_DATA_HOME for the .sh backend, LOCALAPPDATA (a WINDOWS path via
# cygpath when present) for the .ps1 backend. Sets $T to the temp root.
contract_isolate() {
  T="$(mktemp -d)"
  export XDG_DATA_HOME="$T/sh"
  mkdir -p "$XDG_DATA_HOME" "$T/ps"
  if command -v cygpath >/dev/null 2>&1; then export LOCALAPPDATA="$(cygpath -w "$T/ps")"; else export LOCALAPPDATA="$T/ps"; fi
}

# skill_schema_guard <label> <grep -F marker> <.columns file> <skills dir>
# A SKILL.md that quotes an inline `<a>\t<b>\t...` schema must have the field count
# its .columns file declares. Field count = (number of '>\t<' separators) + 1.
# Fails loudly if the marker matches NO SKILL.md (a reworded restatement that would
# otherwise silently disable the guard).
skill_schema_guard() {
  local label="$1" marker="$2" cols="$3" skills="$4" expect f line n found=0
  expect="$(grep -c . "$cols")"
  for f in "$skills"/*/SKILL.md; do
    grep -qF -- "$marker" "$f" 2>/dev/null || continue
    found=1
    line="$(grep -m1 -F -- "$marker" "$f")"
    n="$(printf '%s' "$line" | grep -oF '>\t<' | wc -l | tr -d ' ')"; n=$((n + 1))
    eq "$label in $(basename "$(dirname "$f")")/SKILL.md" "$n" "$expect"
  done
  [ "$found" = 1 ] || bad "$label: no SKILL.md matched marker '$marker' (reworded? update the marker)"
}

# Print the tally, clean the isolated store, exit non-zero on any failure. Call last.
contract_result() {
  echo
  echo "RESULT: $PASS passed, $FAIL failed"
  rm -rf "$T" 2>/dev/null
  [ "$FAIL" -eq 0 ]
}
