#!/usr/bin/env bash
# contract-lib: assertions, an isolated store and the SKILL schema guard for contract-test.sh. Sourced, never run.
# Test tooling only: plugins cannot share runtime code, so nothing here ships in a pack.

PASS=0; FAIL=0
TAB="$(printf '\t')"
ok()  { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "FAIL: $*"; }
eq()  { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }
has() { if printf '%s' "$2" | grep -qE "$3"; then ok; else bad "$1: missing /$3/"; fi; }

# Point XDG_DATA_HOME (.sh) and LOCALAPPDATA (.ps1, a Windows path) at a temp root, $T, so real data is untouched.
contract_isolate() {
  T="$(mktemp -d)"
  export XDG_DATA_HOME="$T/sh"
  mkdir -p "$XDG_DATA_HOME" "$T/ps"
  if command -v cygpath >/dev/null 2>&1; then export LOCALAPPDATA="$(cygpath -w "$T/ps")"; else export LOCALAPPDATA="$T/ps"; fi
}

# True when the .ps1 half can run; Linux and macOS test the .sh half alone.
# RUNES_REQUIRE_PS=1 (Windows CI) makes a missing powershell.exe fail instead of skip.
ps_backend() {
  command -v powershell.exe >/dev/null 2>&1 && return 0
  if [ "${RUNES_REQUIRE_PS:-0}" = 1 ]; then bad "powershell.exe is required (RUNES_REQUIRE_PS=1) and is not on PATH"
  else echo "  (powershell.exe not present: .ps1 backend skipped)"; fi
  return 1
}

# skill_schema_guard <label> <marker> <.columns> <skills dir>: a schema a SKILL.md restates must have the .columns
# field count. Fails when no SKILL.md matches the marker, so a reworded restatement cannot switch the guard off.
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
