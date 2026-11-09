#!/usr/bin/env bash
# Bump each pack's minor version (plugin.json + SKILL.md), commit with [skip ci], tag <pack>--vX.Y.0 and push.
# Arg 1: packs, space-separated (blank = all). Mirrors the local `runes release`.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
PACKS="${1:-}"
# A pack's manifest is plugins/<pack>/.claude-plugin/plugin.json, three levels down.
[ -z "$PACKS" ] && PACKS="$(find plugins -maxdepth 3 -path '*/.claude-plugin/plugin.json' -printf '%h\n' | sed 's#plugins/##; s#/.claude-plugin##' | sort)"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

tags=(); summary=()
for p in $PACKS; do
  pj="plugins/$p/.claude-plugin/plugin.json"
  if [ ! -f "$pj" ]; then echo "skip $p (no plugin.json)"; continue; fi
  cur="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[0-9]+\.[0-9]+\.[0-9]+"' "$pj" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  [ -n "$cur" ] || { echo "RELEASE_ERROR: no semver in $pj"; exit 1; }
  maj="${cur%%.*}"; rest="${cur#*.}"; min="${rest%%.*}"
  new="$maj.$((min + 1)).0"
  tag="$p--v$new"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then echo "RELEASE_ERROR: tag $tag already exists"; exit 1; fi
  sed -i -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[0-9]+\.[0-9]+\.[0-9]+(\")/\1$new\2/" "$pj"
  git add "$pj"
  mj="plugins/$p/.mcp.json"
  if grep -q '"X-Runes-Pack"' "$mj" 2>/dev/null; then
    sed -i -E "s#(\"X-Runes-Pack\"[[:space:]]*:[[:space:]]*\"$p/)[0-9]+\.[0-9]+\.[0-9]+#\1$new#" "$mj"
    git add "$mj"
  fi
  for sf in plugins/"$p"/skills/*/SKILL.md; do
    [ -f "$sf" ] || continue
    sed -i -E "s/^(version:[[:space:]]*)[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$/\1$new/" "$sf"
    git add "$sf"
  done
  tags+=("$tag"); summary+=("$p v$new")
  echo "bumped $p -> $new"
done

if [ ${#summary[@]} -eq 0 ]; then echo "nothing to release"; exit 0; fi

git commit -m "chore(release): $(IFS=,; echo "${summary[*]}") [skip ci]"
for t in "${tags[@]}"; do git tag "$t"; done
git push origin HEAD:main --follow-tags
echo "RELEASE_DONE: ${summary[*]}"
