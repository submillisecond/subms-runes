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
scripts/runes.ps1                   the management dispatcher (+ .bat wrappers)
scripts/validate.ps1                structural checks (run by `runes validate` and CI)
```

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
6. **Release** - bump the pack's `plugin.json` `version` (semver), commit, then
   `runes tag <pack>` to cut the `<pack>--vX.Y.Z` git tag. Push `main` + the tag;
   `release.yml` publishes a GitHub Release.
7. **Deploy** - `runes deploy` / `runes redeploy` installs the official version.
   `runes status` shows working-tree vs installed versions.

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
