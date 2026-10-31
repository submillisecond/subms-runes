# Contributing to subms-runes

## Structure

Three tiers: the marketplace (`subms-runes`, this repo) lists category **packs**
(`plugins/<pack>`), each holding **runes** (skills, `plugins/<pack>/skills/<rune>`).

```
.claude-plugin/marketplace.json     lists every pack
plugins/<pack>/
  .claude-plugin/plugin.json        the pack manifest (name == dir, semver version)
  skills/<rune>/
    SKILL.md                        frontmatter (name + description) + instructions
    scripts/                        optional deterministic helpers
.github/scripts/validate.sh         CI structural checks (bash + jq)
```

The operator dispatcher (`runes` - deploy / status / dev / validate / etc.) lives
in the private `subms-infra` repo at `automation/runes/` (it drives this
marketplace as a sibling under the umbrella). `runes validate` folds the same
structural checks in PowerShell; CI runs the bash port above. Keep the two in step.

## The lifecycle

1. Scaffold with `runes new-rune <pack> <rune>`, or `runes new-pack <name>` for a
   new category.
2. Write `SKILL.md`: a third-person `description` with concrete trigger phrases,
   which is what makes Claude pick the skill, then imperative steps. Deterministic
   logic goes in `scripts/`.
3. Load the pack live with `runes dev <pack>` (`--plugin-dir`, no install) and
   iterate; `runes test <pack> <rune>` runs a rune's script on its own.
4. Run `runes validate`, the same checks CI runs on every PR.
5. Open a PR and merge to `main` when green.
6. Release through CI (`release.yml`), one of two ways:
   - Put `[release]` in the commit message, or run the release workflow by hand.
     CI bumps each pack's minor version in `plugin.json` and every skill's
     frontmatter together, commits with `[skip ci]`, tags `<pack>--vX.Y.0` and
     pushes. `git pull` afterwards to pick up the bump commit.
   - Or bump locally with `runes release`, which bumps, commits and tags, then
     `git push --follow-tags`. A push without `[release]` tags the current version.
   Pack and skill versions move together either way; validate enforces it.
7. `runes deploy` / `runes redeploy` installs the official version, and
   `runes status` shows working-tree against installed versions and any drift.

## Channels

- dev is the local working tree, loaded with `runes dev` and never installed
  globally, so daily sessions never run work in progress.
- official is GitHub `submillisecond/subms-runes`, installed with `runes deploy`.
  Pushing a tag is the release gate.

## Conventions

- One pack per coherent theme. Keep `SKILL.md` descriptions tight - every
  installed skill's metadata is always loaded into context.
- ASCII only; hyphen-minus, no fancy dashes.
- `marketplace.json` `plugins[]` must match the on-disk packs exactly (CI checks
  this). `new-pack` keeps them in sync.
