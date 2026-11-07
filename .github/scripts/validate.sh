#!/usr/bin/env bash
# Structure checks with bash + jq; .ps1 files are parse-checked when pwsh is present. Keep in step with `runes validate`
# in subms-infra. Usage: validate.sh [packs...] (none = all).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLUGINS="$REPO/plugins"
MARKET="$REPO/.claude-plugin/marketplace.json"

command -v jq >/dev/null 2>&1 || { echo "validate: jq is required"; exit 2; }

errs=()
fail() { errs+=("$1"); }

have_pwsh=0
command -v pwsh >/dev/null 2>&1 && have_pwsh=1
ps1_check() {
    [ "$have_pwsh" = 1 ] || return 0
    pwsh -NoProfile -Command "\$t=\$null;\$e=\$null;[System.Management.Automation.Language.Parser]::ParseFile('$1',[ref]\$t,[ref]\$e)|Out-Null;if(\$e -and \$e.Count){exit 1}" >/dev/null 2>&1
}

market_ok=1
if [ ! -f "$MARKET" ]; then fail "missing .claude-plugin/marketplace.json"; market_ok=0
elif ! jq empty "$MARKET" >/dev/null 2>&1; then fail "marketplace.json invalid JSON"; market_ok=0; fi

ondisk=()
if [ -d "$PLUGINS" ]; then
    for d in "$PLUGINS"/*/; do
        [ -f "${d}.claude-plugin/plugin.json" ] && ondisk+=("$(basename "$d")")
    done
fi

if [ $# -gt 0 ]; then packs=("$@"); else packs=("${ondisk[@]:-}"); fi
semver='^[0-9]+\.[0-9]+\.[0-9]+$'

for p in "${packs[@]:-}"; do
    [ -n "$p" ] || continue
    pdir="$PLUGINS/$p"
    pj="$pdir/.claude-plugin/plugin.json"
    if [ ! -f "$pj" ]; then fail "$p: missing plugin.json"; continue; fi
    if ! jq empty "$pj" >/dev/null 2>&1; then fail "$p: plugin.json invalid JSON"; continue; fi
    name="$(jq -r '.name // ""' "$pj")"
    ver="$(jq -r '.version // ""' "$pj")"
    [ "$name" = "$p" ] || fail "$p: plugin.json name '$name' != dir '$p'"
    [[ "$ver" =~ $semver ]] || fail "$p: version '$ver' is not semver"

    # The site's subms-runes product page is built from site.json, so a listed
    # pack with runes needs one. A bundle (no skills) and an UNLISTED pack do not.
    if [ -d "$pdir/skills" ] && [ ! -f "$pdir/UNLISTED" ]; then
        sj="$pdir/site.json"
        if [ ! -f "$sj" ]; then fail "$p: missing site.json (the product page card)"
        elif ! jq -e '(.pitch | type == "string" and length > 0) and (.about | type == "string" and length > 0) and (.demo | type == "string")' "$sj" >/dev/null 2>&1; then
            fail "$p: site.json needs pitch, about and demo"
        fi
    fi

    sdir="$pdir/skills"
    if [ -d "$sdir" ]; then
        for skill in "$sdir"/*/; do
            [ -d "$skill" ] || continue
            sk="$(basename "$skill")"
            sf="${skill}SKILL.md"
            if [ ! -f "$sf" ]; then fail "$p/$sk: missing SKILL.md"; continue; fi
            head -n 1 "$sf" | grep -qE '^---' || fail "$p/$sk: SKILL.md missing frontmatter block"
            grep -qE '^name:[[:space:]]*[^[:space:]]' "$sf" || fail "$p/$sk: SKILL.md frontmatter missing name"
            grep -qE '^description:[[:space:]]*[^[:space:]]' "$sf" || fail "$p/$sk: SKILL.md frontmatter missing description"
            # Skill frontmatter version must match the pack (the cast banner reads it).
            sver="$(grep -m1 -E '^version:[[:space:]]*' "$sf" | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*$//')"
            if [ -n "$sver" ] && [ -n "$ver" ] && [ "$sver" != "$ver" ]; then
                fail "$p/$sk: SKILL.md version '$sver' != pack version '$ver' (run: runes release, or sync)"
            fi
            if [ -d "${skill}scripts" ]; then
                for ps in "${skill}scripts"/*.ps1; do [ -f "$ps" ] || continue; ps1_check "$ps" || fail "$p/$sk/$(basename "$ps"): PowerShell parse error"; done
                for sh in "${skill}scripts"/*.sh; do [ -f "$sh" ] || continue; bash -n "$sh" 2>/dev/null || fail "$p/$sk/$(basename "$sh"): bash syntax error"; done
            fi
        done
    fi

    if [ -d "$pdir/scripts" ]; then
        for ps in "$pdir/scripts"/*.ps1; do [ -f "$ps" ] || continue; ps1_check "$ps" || fail "$p/scripts/$(basename "$ps"): PowerShell parse error"; done
        for sh in "$pdir/scripts"/*.sh; do [ -f "$sh" ] || continue; bash -n "$sh" 2>/dev/null || fail "$p/scripts/$(basename "$sh"): bash syntax error"; done
    fi
done

if [ "$market_ok" = 1 ]; then
    listed="$(jq -r '.plugins[].name' "$MARKET" 2>/dev/null)"
    for m in "${ondisk[@]:-}"; do
        [ -n "$m" ] || continue
        # A pack held back from the marketplace says so with an UNLISTED file
        # (its reason inside); anything else on disk must be listed.
        if [ -f "$PLUGINS/$m/UNLISTED" ]; then
            printf '%s\n' "$listed" | grep -qxF "$m" && fail "pack '$m' is marked UNLISTED but marketplace.json lists it"
            continue
        fi
        printf '%s\n' "$listed" | grep -qxF "$m" || fail "pack '$m' on disk but not in marketplace.json"
    done
    while IFS= read -r m; do
        [ -n "$m" ] || continue
        found=0
        for d in "${ondisk[@]:-}"; do [ "$d" = "$m" ] && found=1; done
        [ "$found" = 1 ] || fail "marketplace.json lists '$m' but no such pack on disk"
    done <<< "$listed"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    if [ ${#errs[@]} -eq 0 ]; then badge=":white_check_mark: passed"; else badge=":x: failed (${#errs[@]})"; fi
    {
        echo ":mag: **validate** - $badge"
        echo
        echo "| Pack | Version | Runes | Scripts |"
        echo "|---|---|---|---|"
        for p in $(printf '%s\n' "${ondisk[@]:-}" | sort); do
            [ -n "$p" ] || continue
            ver="$(jq -r '.version // "?"' "$PLUGINS/$p/.claude-plugin/plugin.json")"
            runes="$(ls -1 "$PLUGINS/$p/skills" 2>/dev/null | sort | paste -sd, - )"
            nscripts="$(find "$PLUGINS/$p" \( -name '*.ps1' -o -name '*.sh' \) 2>/dev/null | wc -l | tr -d ' ')"
            echo "| $p | $ver | $runes | $nscripts |"
        done
        if [ ${#errs[@]} -ne 0 ]; then
            echo
            echo "### Failures"
            for e in "${errs[@]}"; do echo "- $e"; done
        fi
    } >> "$GITHUB_STEP_SUMMARY"
fi

if [ ${#errs[@]} -ne 0 ]; then
    echo "VALIDATION FAILED (${#errs[@]}):"
    for e in "${errs[@]}"; do echo "  - $e"; done
    exit 1
fi
n=0; for p in "${packs[@]:-}"; do [ -n "$p" ] && n=$((n + 1)); done
echo "validate: OK ($n pack(s))"
