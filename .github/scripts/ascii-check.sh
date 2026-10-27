#!/usr/bin/env bash
# Fail on non-ASCII bytes in scripts, the server bundle, contracts and manifests: PowerShell 5.1 reads a BOM-less .ps1
# as ANSI, so one stray dash changes what it parses. Skill prose is exempt; the runes render emoji.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

mapfile -t files < <(git ls-files \
  'plugins/*/scripts/*' 'plugins/*/skills/*/scripts/*' 'plugins/*/server/*' \
  'plugins/*/contract/*' 'plugins/*/.claude-plugin/*.json' 'plugins/*/.mcp.json' \
  '.claude-plugin/*.json' 'lib/*' '.github/scripts/*' 'tests/*')

bad=0
for f in "${files[@]}"; do
  case "$f" in *.png|*.jpg|*.ico) continue ;; esac
  if LC_ALL=C grep -n '[^[:print:][:space:]]' "$f" > /tmp/ascii.$$ 2>/dev/null; then
    bad=$((bad + 1))
    echo "::error file=$f::non-ASCII bytes"
    head -3 /tmp/ascii.$$ | sed "s|^|  $f:|"
  fi
done
rm -f /tmp/ascii.$$

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  if [ "$bad" = 0 ]; then echo ":white_check_mark: **ascii** - ${#files[@]} files" ; else echo ":x: **ascii** - $bad of ${#files[@]} files have non-ASCII bytes"; fi >> "$GITHUB_STEP_SUMMARY"
fi
[ "$bad" = 0 ] && echo "ascii: OK (${#files[@]} files)" || { echo "ascii: $bad file(s) with non-ASCII bytes"; exit 1; }
