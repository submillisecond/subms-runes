# lib - shared rune tooling

Repo-level shared code for subms-runes DEV/TEST tooling, organised into packages
by concern. Sourced by the per-pack contract tests and the functional suites.

> Plugin RUNTIME scripts cannot live here. Plugin isolation copies each pack's own
> `scripts/` under `${CLAUDE_PLUGIN_ROOT}`, so a rune can only reference scripts
> inside its own plugin. This `lib/` is for tooling that runs FROM THE REPO (CI,
> contract tests, suites) - never shipped inside a plugin.
>
> It also stays in subms-runes, NOT subms-infra: the contract tests run in this
> repo's CI and must not depend on the private operator repo (subms-infra holds the
> `runes.ps1` operator dispatcher only).

## Packages

| Package | Contents | Used by |
|---|---|---|
| `test/` | `contract-lib.sh` (bash: assertions, isolated store, SKILL<->.columns guard, result) + `suite-lib.ps1` (PowerShell: Run/NewTemp/Check/Has/Complete-Suite) | each pack's `contract/contract-test.sh` (sh) and `tests/*.tests.ps1` (ps1) |

Both backends are provided per the org dual-backend convention: `.sh` for the bash
contract tests, `.ps1` for the PowerShell functional suites. New shared concerns get
their own sibling package under `lib/` (e.g. a future `lib/fixtures/`), not a flat
dumping ground.
