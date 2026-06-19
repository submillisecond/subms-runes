#!/usr/bin/env bash
# Publish (or refresh) one GitHub Release per pack at its plugin.json version.
# Called by .github/workflows/release.yml on push to main. Needs gh + GH_TOKEN.
# Writes a step summary to GITHUB_STEP_SUMMARY. Run from the repo root.
set -euo pipefail

rows=()
for d in plugins/*/; do
    pj="${d}.claude-plugin/plugin.json"
    [ -f "$pj" ] || continue
    name="$(basename "$d")"
    ver="$(jq -r .version "$pj")"
    tag="$name--v$ver"
    zip="$name-$ver.zip"
    rm -f "$zip"
    ( cd "$d" && zip -qr "../../$zip" . )

    if gh release view "$tag" >/dev/null 2>&1; then
        echo "Refreshing release $tag"
        gh release upload "$tag" "$zip" --clobber
        action="refreshed"
    else
        echo "Creating release $tag"
        gh release create "$tag" "$zip" --title "$tag" --generate-notes
        action="created"
    fi

    kb=$(( ($(stat -c%s "$zip") + 512) / 1024 ))
    url="$(gh release view "$tag" --json url -q .url)"
    rows+=("| [$tag]($url) | $ver | $action | ${kb} KB |")
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo ":rocket: **release**"
        echo
        echo "| Release | Version | Action | Zip |"
        echo "|---|---|---|---|"
        printf '%s\n' "${rows[@]}"
    } >> "$GITHUB_STEP_SUMMARY"
fi
