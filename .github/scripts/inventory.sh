#!/usr/bin/env bash
# Regenerates the README badge line and inventory table from plugins/ on disk.
# --check fails when either is stale or a rune is missing from the Packs table (CI runs this).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
README="README.md"
REPO="submillisecond/subms-runes"

jqv() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$1" | head -1; }

packs=(); runes_total=0
for d in plugins/*/; do [ -f "$d.claude-plugin/plugin.json" ] && packs+=("$(basename "$d")"); done

badges() {
  local wf="https://github.com/$REPO/actions/workflows" sh="https://img.shields.io"
  printf '[![checks](%s/github/actions/workflow/status/%s/release.yml?branch=main&label=checks&labelColor=0d1117)](%s/release.yml)\n' "$sh" "$REPO" "$wf"
  printf '[![live](%s/github/actions/workflow/status/%s/live.yml?branch=main&label=live%%20engine&labelColor=0d1117)](%s/live.yml)\n' "$sh" "$REPO" "$wf"
  printf '![packs](%s/badge/packs-%s-1f6feb?labelColor=0d1117)\n' "$sh" "${#packs[@]}"
  printf '![runes](%s/badge/runes-%s-1f6feb?labelColor=0d1117)\n' "$sh" "$runes_total"
  printf '![licence](%s/badge/licence-MIT-9d2235?labelColor=0d1117)\n' "$sh"
}

inventory() {
  echo "| Pack | Version | Runes | Runs on | Tests |"
  echo "|---|---|---|---|---|"
  local p runes runs tests nps nsh
  for p in "${packs[@]}"; do
    runes="$(for s in $(ls -1 "plugins/$p/skills" | LC_ALL=C sort); do [ -f "plugins/$p/skills/$s/SKILL.md" ] || continue; printf '`/%s` ' "$s"; done)"
    nps="$(find "plugins/$p" -name '*.ps1' | wc -l | tr -d ' ')"
    nsh="$(find "plugins/$p" -name '*.sh' -not -path '*/contract/*' | wc -l | tr -d ' ')"
    runs=""
    [ "$nps" -gt 0 ] && runs="Windows ($nps .ps1)"
    [ "$nsh" -gt 0 ] && runs="${runs:+$runs, }macOS + Linux ($nsh .sh)"
    grep -q '"url"' "plugins/$p/.mcp.json" 2>/dev/null && runs="${runs:+$runs, }hosted MCP"
    [ -d "plugins/$p/server" ] && runs="${runs:+$runs, }local MCP (Node 22)"
    tests=""
    [ -f "plugins/$p/contract/contract-test.sh" ] && tests="contract"
    [ -f "tests/$p.tests.ps1" ] && tests="${tests:+$tests, }functional"
    [ -f "plugins/$p/contract/live-test.sh" ] && tests="${tests:+$tests, }live nightly"
    echo "| \`$p\` | $(jqv "plugins/$p/.claude-plugin/plugin.json") | ${runes% } | $runs | ${tests:--} |"
  done
}

for p in "${packs[@]}"; do for s in plugins/$p/skills/*/SKILL.md; do runes_total=$((runes_total + 1)); done; done

# Replace the lines between <!-- name:start --> and <!-- name:end --> with $2.
splice() {
  BODY="$2" awk -v s="<!-- $1:start -->" -v e="<!-- $1:end -->" '
    $0 == s { print; print ENVIRON["BODY"]; skip = 1; next }
    $0 == e { skip = 0 }
    !skip'
}

out="$(tr -d '\r' < "$README" | splice badges "$(badges)")"
out="$(printf '%s\n' "$out" | splice inventory "$(inventory)")"

if [ "${1:-}" = "--check" ]; then
  fail=0
  if [ "$out" != "$(tr -d '\r' < "$README")" ]; then echo "README inventory is stale: run .github/scripts/inventory.sh"; fail=1; fi
  table="$(tr -d '\r' < "$README" | sed -n '/^## Packs/,/^## /p')"
  for p in "${packs[@]}"; do for s in plugins/$p/skills/*/SKILL.md; do
    r="$(basename "$(dirname "$s")")"
    printf '%s' "$table" | grep -qF "\`$r\`" || { echo "README Packs table is missing the rune $r"; fail=1; }
  done; done
  [ "$fail" = 0 ] && echo "inventory: OK (${#packs[@]} packs, $runes_total runes)"
  exit "$fail"
fi
printf '%s\n' "$out" > "$README"
echo "inventory: wrote $README (${#packs[@]} packs, $runes_total runes)"
