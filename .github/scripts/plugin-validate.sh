#!/usr/bin/env bash
# Runs `claude plugin validate` on the marketplace and every pack; errors fail, warnings go to the summary.
# Env: none. Needs the claude CLI on PATH; no login is required.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
export CLAUDE_CONFIG_DIR="$(mktemp -d)"

fail=0; rows=()
for p in . plugins/*/; do
  p="${p%/}"
  out="$(claude plugin validate "$p" 2>&1)"; rc=$?
  warns="$(printf '%s\n' "$out" | grep -oE '\b[A-Z]+(_[A-Z]+)+\b' | sort -u | paste -sd' ' -)"
  echo "== $p (exit $rc) ${warns}"
  [ "$rc" -ne 0 ] && { fail=1; printf '%s\n' "$out"; }
  if [ "$rc" -ne 0 ]; then st=":x: failed"; else st=":white_check_mark: passed"; fi
  rows+=("| \`$p\` | $st | ${warns:--} |")
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  { echo "### claude plugin validate"; echo; echo "| Path | Result | Warnings |"; echo "|---|---|---|"; printf '%s\n' "${rows[@]}"; } >> "$GITHUB_STEP_SUMMARY"
fi
exit "$fail"
