#!/usr/bin/env bash
# Runs every pack's contract-test.sh (or live-test.sh with --live); a new pack is picked up with no CI edit.
# Env: RUNES_REQUIRE_PS=1 on Windows makes a missing powershell.exe fail instead of skip.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
name="contract-test.sh"; [ "${1:-}" = "--live" ] && name="live-test.sh"

fail=0; rows=()
for t in plugins/*/contract/"$name"; do
  [ -f "$t" ] || continue
  pack="$(basename "$(dirname "$(dirname "$t")")")"
  echo "== $pack"
  out="$(bash "$t" 2>&1)"; rc=$?
  printf '%s\n' "$out" | grep -E '^(FAIL|RESULT)|skipped' || true
  result="$(printf '%s\n' "$out" | sed -n 's/^RESULT: //p' | tail -1)"
  if [ "$rc" -ne 0 ]; then fail=1; rows+=("| $pack | :x: ${result:-exit $rc} |"); else rows+=("| $pack | :white_check_mark: $result |"); fi
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  { echo "### ${name%.sh} ($(uname -s))"; echo; echo "| Pack | Result |"; echo "|---|---|"; printf '%s\n' "${rows[@]}"; } >> "$GITHUB_STEP_SUMMARY"
fi
exit "$fail"
