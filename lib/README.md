# lib - shared rune tooling

Shared code for the repo's development and test tooling: the per-pack contract
tests and the functional suites source it.

Nothing here ships in a plugin. Claude Code copies each pack's own folder into its
cache, so a rune can only call scripts inside its own plugin; `lib/` is for code
that runs from the repo, in CI and in local tests. It lives here, and stays out of
subms-infra, because this repo's CI must not depend on the private operator repo.

## Packages

| Package | Contents | Used by |
|---|---|---|
| `test/` | `contract-lib.sh` (bash: assertions, isolated store, SKILL<->.columns guard, result) and `suite-lib.ps1` (PowerShell: Run/NewTemp/Check/Has/Complete-Suite) | each pack's `contract/contract-test.sh` and `tests/*.tests.ps1` |

There is a bash and a PowerShell side to match the org's two backends. A new
shared concern gets its own folder under `lib/`, such as `lib/fixtures/`.
