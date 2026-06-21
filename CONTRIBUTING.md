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

## The lifecycle (AISkill-DLC)

1. **Scaffold** - `runes new-rune <pack> <rune>` (or `runes new-pack <name>` for a
   new category). Generates the boilerplate.
2. **Author** - write `SKILL.md`: a third-person `description` with concrete
   trigger phrases (this is what makes Claude pick the skill), and imperative
   step-by-step instructions. Put any deterministic logic in `scripts/`.
3. **Dev-test (live)** - `runes dev <pack>` loads the pack from the working tree
   (`--plugin-dir`, no install); iterate with edits reflected immediately.
   `runes test <pack> <rune>` runs a rune's script standalone.
4. **Validate** - `runes validate` (the same checks CI runs on every PR).
5. **Integrate** - open a PR; merge to `main` when green.
6. **Release** - trigger-based via CI (`release.yml`). Two ways to cut one:
   - **CI bumps** (preferred): put `[release]` in your commit message, OR run the
     "🚀 release" workflow manually (Run workflow). CI bumps each pack's MINOR
     (`plugin.json` + every skill's frontmatter, in lockstep), commits `[skip ci]`,
     tags `<pack>--vX.Y.0`, and pushes. Then `git pull` to catch the bump commit.
   - **Local bump**: `runes release` bumps + commits + tags locally; `git push
     --follow-tags`. A normal push (no `[release]`) just tags the current version.
   Either way the version is version-locked across pack + skills (validate enforces it).
7. **Deploy** - `runes deploy` / `runes redeploy` installs the official version.
   `runes status` shows working-tree vs installed versions (and per-rune version + drift).

## Channels

- **dev** = the local working tree, via `runes dev` (live, never installed
  globally - daily sessions never run work-in-progress).
- **official** = GitHub `submillisecond/subms-runes`, installed via `runes deploy`.
  Pushing a tag is the release gate.

## Conventions

- One pack per coherent theme. Keep `SKILL.md` descriptions tight - every
  installed skill's metadata is always loaded into context.
- ASCII only; hyphen-minus, no fancy dashes.
- `marketplace.json` `plugins[]` must match the on-disk packs exactly (CI checks
  this). `new-pack` keeps them in sync.
