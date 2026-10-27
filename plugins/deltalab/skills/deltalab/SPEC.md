# deltalab rune - reference

What the `deltalab` rune does now. Tool names, arguments, room states and the
environment are in `../../contract/CONTRACTS.md`; this file does not repeat them.

## Uses

- Every tool in the contract. The rune's steps are join, read, write or
  suggest, inbox and reply, leave.
- No scripts of its own: the MCP server is the whole runtime.

## Behaviour the rune relies on

- A direct write is refused unless the agent's permission is `edit`. The rune
  treats that refusal as the signal to suggest, never as an error to retry.
- `deltalab_inbox` with `wait_seconds` returns on the first new message, so a
  conversation is a loop of inbox and reply with no polling sleep.
- A room the relay closed stays listed with its reason, so the rune can tell
  the user why the agent is out (removed, share ended, rate limited).

## Verification

- `../../contract/contract-test.sh`: the server against the contract, offline.
- `subms-ui/apps/deltalab`: `pnpm test` (the tool layer against an in-memory
  room) and `pnpm mcp:e2e` (the built bundle in a fresh room on the beta
  relay: join, read, section write, presence, inbox, reply, suggest, leave).
