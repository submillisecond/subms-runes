#!/usr/bin/env bash
# Tag each pack at its plugin.json version on push to main - lightweight version
# markers only: NO GitHub Release, NO zip, NO source-code archives. A new version
# creates + pushes the tag <pack>--vX.Y.Z; an existing tag is left untouched.
# Needs contents:write (the default GITHUB_TOKEN). Run from the repo root.
set -euo pipefail

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

rows=()
for d in plugins/*/; do
    pj="${d}.claude-plugin/plugin.json"
    [ -f "$pj" ] || continue
    name="$(basename "$d")"
    ver="$(jq -r .version "$pj")"
    tag="$name--v$ver"
    if git ls-remote --tags origin "refs/tags/$tag" | grep -q .; then
        echo "exists: $tag"
        status="exists"
    else
        echo "tagging: $tag"
        git tag "$tag"
        git push origin "refs/tags/$tag"
        status="created"
    fi
    rows+=("| $tag | $ver | $status |")
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo ":rocket: **release** (tags)"
        echo
        echo "| Tag | Version | Status |"
        echo "|---|---|---|"
        printf '%s\n' "${rows[@]}"
    } >> "$GITHUB_STEP_SUMMARY"
fi
