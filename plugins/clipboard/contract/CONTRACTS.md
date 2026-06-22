# Clipboard plugin - canonical contract

This is the canonical contract for the clipboard plugin's scripts. The
machine-readable column order lives in the `.columns` files next to this doc
(`history.columns`, `snippet.columns`); they are the source of truth for index
schemas. This doc references them - it does not re-define them. Skill specs
under `../skills/` POINT here for the contract; they must not restate schemas.

The `.ps1` backends are the verified ones (each `.sh` mirror is a port and is
annotated as such in its header). The system-clipboard operations
(`clipboard-io` read/write, and the `get` recall path that re-copies onto the
clipboard) are NOT covered by the automated contract test (`contract-test.sh`),
because they touch the live system clipboard. Everything else - verb shapes,
KEY=value outputs, index column counts - is asserted by that test on both
backends against an isolated temp store.

ASCII only throughout (hyphen-minus only).

## 1. Stores and data schemas

### clip-history store

Location:

- Windows: `%LOCALAPPDATA%\runes\clipboard\history\`
- POSIX: `${XDG_DATA_HOME:-$HOME/.local/share}/runes/clipboard/history/`

Created on demand with owner-only access (Windows `icacls` inheritance strip +
current-user full control; POSIX `chmod 700`).

Files:

| File | Meaning |
|---|---|
| `index.tsv` | One TAB-separated row per entry, append-order = chronological. 7 columns (see `history.columns`). |
| `<id>.txt` | Text entry payload (inline body). |
| `<id>.png` | Image entry payload (copied from `-Path`). |
| `<id>.files.txt` | Files entry payload (the newline-separated path list). |
| `.enabled` | Presence flag = recording is on. |

`index.tsv` columns (machine source: `history.columns`):

| # | Column | Meaning |
|---|---|---|
| 1 | `id` | Entry id, `yyyyMMdd-HHmmss-fff` (.ps1) / `yyyyMMdd-HHMMSS-<pid>` (.sh). Also the payload filename stem. |
| 2 | `ts` | Capture time, ISO-8601 UTC (`yyyy-MM-ddTHH:mm:ssZ`). |
| 3 | `kind` | `text` \| `image` \| `files`. |
| 4 | `subtype` | Caller-supplied subtype tag (default `plain`). |
| 5 | `bytes` | Payload size in bytes (the source `-Path` length). |
| 6 | `source` | Originating rune (default `clip`). |
| 7 | `preview` | One-line preview, whitespace-flattened, capped at 100 chars (`[image]` / file list for non-text). |

### clip-snippet store

Location:

- Windows: `%LOCALAPPDATA%\runes\clipboard\snippets\`
- POSIX: `${XDG_DATA_HOME:-$HOME/.local/share}/runes/clipboard/snippets/`

Same owner-only creation as history. No `.enabled` flag - snippets are always
available.

Files:

| File | Meaning |
|---|---|
| `index.tsv` | One TAB-separated row per snippet, kept LC_ALL=C / Sort-Object sorted by name. 6 columns (see `snippet.columns`). |
| `<name>.txt` | Text snippet payload. |
| `<name>.<imgext>` | Image snippet payload (extension from source, default `.png`). |

`index.tsv` columns (machine source: `snippet.columns`):

| # | Column | Meaning |
|---|---|---|
| 1 | `name` | Sanitised key (lowercased, `[^a-z0-9._-]+` -> `-`, trimmed of leading/trailing `-`). Also the payload filename stem. |
| 2 | `ts` | Save time, ISO-8601 UTC. |
| 3 | `kind` | `text` \| `image`. |
| 4 | `subtype` | Caller-supplied subtype tag (default `plain`). |
| 5 | `bytes` | Payload size in bytes. |
| 6 | `preview` | One-line preview, capped at 100 chars (`[image]` for image snippets). |

STALE COMMENT (documented drift, do not trust the header): the `clip-snippet.ps1`
file header and the `clip-snippet.sh` file header both describe a 5-column
index that OMITS `kind` (they list `name \t iso-ts \t subtype \t bytes \t
preview`). The ACTUAL on-disk and emitted row is 6 columns WITH `kind` at
position 3, as written by both scripts (`save`) and as pinned in
`snippet.columns` and asserted by `contract-test.sh`. The 6-column form above
is authoritative; the script header comments are out of date.

### clipboard-io capture conventions

`clipboard-io` reads/writes the SYSTEM clipboard. It does not maintain an index.
Ephemeral capture files (image reads only) live under:

- Windows: `%TEMP%\runes\clipboard\`
- POSIX: `${TMPDIR:-/tmp}/runes/clipboard/`

Conventions:

- TEXT reads are STREAMED to stdout between `-----BEGIN CLIP TEXT-----` /
  `-----END CLIP TEXT-----` markers - never written to a file.
- IMAGE reads are saved as `clip-<stamp>.png` in the temp dir (the Read tool
  needs a path, not inline bytes), and the path is reported via `CLIP_PATH`.
- FILES reads report the original paths in place - nothing is copied.
- Stale temp files older than 24h are pruned on each image capture. Saved clips
  (Downloads), snippets, and history (data dir) live elsewhere and are untouched.

## 2. Verb / flag / output reference

Flag spelling differs per backend: `.ps1` uses `-PascalCase`, `.sh` uses
`--kebab`. They are listed together below as `-Pascal` / `--kebab`.

### clip-history (default verb: `status`)

| Verb | Flags | Emits (KEY=value lines) |
|---|---|---|
| `enable` | - | `HISTORY_ENABLED=1` (creates `.enabled`). |
| `disable` | - | `HISTORY_ENABLED=0` (removes `.enabled`). |
| `status` | - | `HISTORY_ENABLED=<0\|1>`, `HISTORY_DIR=<root>`, `HISTORY_COUNT=<n>`. |
| `add` | `-Kind`/`--kind`, `-Subtype`/`--subtype`, `-Source`/`--source`, `-Path`/`--path` | On success: `HISTORY_ADDED=<id>`. Guards: `HISTORY_SKIPPED=disabled` \| `HISTORY_SKIPPED=too_large` \| `HISTORY_SKIPPED=excluded` \| `HISTORY_SKIPPED=secret:<types>`; `HISTORY_ERROR=missing -Path` / `missing --path`. |
| `list` | `-Count`/`--count` (default 20) | `HISTORY_COUNT=<n>`, then up to N rows: `#<num>\t<id>\t<kind>/<subtype>\t<bytes>B\t<source>\t<preview>` (newest first, `#1`=newest). |
| `search` | `-Query`/`--query` | `HISTORY_MATCHES=<n>`, then per hit: `<id>\t<kind>/<subtype>\t<preview>`. |
| `get` | `-Id`/`--id` (`<id>` or `#<n>`) | `HISTORY_ID=<id>`, `HISTORY_KIND=<kind>`. Text: `HISTORY_RECOPIED=clipboard` + body between `-----BEGIN CLIP TEXT-----`/`-----END CLIP TEXT-----`. Non-text: `HISTORY_PATH=<file>`. Errors: `HISTORY_ERROR=no such entry` \| `HISTORY_ERROR=payload missing`. (Re-copy touches the live clipboard - not contract-tested.) |
| `rm` | `-Id`/`--id` | `HISTORY_REMOVED=<id>`. |
| `clear` | - | `HISTORY_CLEARED=1` (preserves `.enabled`). |

`add` pipeline: refuse if disabled; require an existing `-Path`; refuse if over
`RUNES_HISTORY_MAX_BYTES`; for text, refuse if matching `RUNES_HISTORY_EXCLUDE`
or if `secret-scan` finds any secret; copy payload, append index row, then prune
oldest rows down to `RUNES_HISTORY_MAX_ENTRIES`.

### clip-snippet (default verb: `list`)

| Verb | Flags | Emits (KEY=value lines) |
|---|---|---|
| `save` | `-Name`/`--name`, `-Kind`/`--kind`, `-Subtype`/`--subtype`, `-Path`/`--path` | On success: `SNIPPET_SAVED=<name>`. Refusals/errors: `SNIPPET_ERROR=missing/invalid -Name` / `--name`; `SNIPPET_ERROR=missing -Path` / `--path`; `SNIPPET_REFUSED=secret:<types>` (text only). Re-saving a name replaces the prior payload and row. |
| `get` | `-Name`/`--name` | `SNIPPET_NAME=<name>`, `SNIPPET_RECOPIED=clipboard`. Text: body between `-----BEGIN CLIP TEXT-----`/`-----END CLIP TEXT-----`. Image: `SNIPPET_KIND=image`, `SNIPPET_PATH=<file>`. Error: `SNIPPET_ERROR=no snippet named '<name>'`. (Re-copy touches the live clipboard - not contract-tested.) |
| `list` | - | `SNIPPET_COUNT=<n>`, then per snippet: `<name>\t<kind>/<subtype>\t<bytes>B\t<preview>`. |
| `search` | `-Query`/`--query` | `SNIPPET_MATCHES=<n>`, then per hit: `<name>\t<kind>/<subtype>\t<preview>`. (.ps1 also matches against payload text content.) |
| `rm` | `-Name`/`--name` | `SNIPPET_REMOVED=<name>`. |
| `clear` | - | `SNIPPET_CLEARED=1`. |

Image detection on `save`: `-Kind image` OR a source path extension in
`.png/.jpg/.jpeg/.bmp/.gif/.tiff`. Image snippets skip the secret scan.

### clipboard-io (system clipboard - NOT contract-tested)

Invocation (Windows REQUIRES STA):

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File clipboard-io.ps1 <read|write> [-Path f]
bash clipboard-io.sh <read|write> [path]
```

| Mode | Emits |
|---|---|
| `read` (default), files present | `CLIP_KIND=files`, `CLIP_COUNT=<n>`, then one path per line. |
| `read`, image present | `CLIP_KIND=image`, `CLIP_PATH=<temp png>`. |
| `read`, text present | `CLIP_KIND=text`, `CLIP_BYTES=<n>`, `CLIP_LINES=<n>`, optional `CLIP_SECRETS=<types>` + `CLIP_SECRET_COUNT=<n>`, then body between `-----BEGIN CLIP TEXT-----`/`-----END CLIP TEXT-----`. |
| `read`, nothing | `CLIP_KIND=empty` (POSIX may add `CLIP_NOTE=...` when no clipboard tool is installed). |
| `write -Path` (text file) | `CLIP_WRITE=ok`, `CLIP_BYTES=<n>`. |
| `write -Path` (image file) | `CLIP_WRITE=ok`, `CLIP_KIND=image`. |
| `write` error | `CLIP_WRITE=error: <reason>` (exit 1). |

STA requirement: the Windows clipboard APIs (`Get-Clipboard -Format Image`,
`Clipboard::SetImage`) require single-threaded apartment mode; callers must pass
`-STA`. POSIX resolves backends per session: macOS `pbpaste`/`pbcopy` (+
`pngpaste` for images); Wayland `wl-clipboard`; X11 `xclip`/`xsel`. Clipboard
FILE lists are Linux-only (via `text/uri-list`); macOS does not support them.

### secret-scan (shared, dot-sourced)

Dot-sourced by `clip-history`, `clip-snippet`, and `clipboard-io` to refuse or
flag credentials. Two entry shapes:

- Function (dot-source): `.ps1` `Find-Secrets $text` returns
  `@{ types=@(...); count=N; redacted='<text with [REDACTED:type]>' }`. `.sh`
  `find_secrets <textfile>` sets `FS_TYPES` (comma list), `FS_COUNT`,
  `FS_REDACTED` (a redacted temp file path).
- CLI: `secret-scan.ps1 -Path f [-Redact]` / `-Text '...'`;
  `secret-scan.sh --path f [--redact]` / `--text '...'`. Prints
  `CLIP_SECRETS=<comma types>`, `CLIP_SECRET_COUNT=<n>`, and with redact the
  text between `-----BEGIN REDACTED-----`/`-----END REDACTED-----`.

Detection favours precision over a blunt entropy sweep: vendor-prefixed and
structural tokens (private keys; AWS access/secret keys; GitHub/GitLab PATs;
Slack token + webhook; Google/Stripe/OpenAI/Anthropic/npm/pypi/SendGrid/Twilio
keys; JWT; bearer tokens; basic-auth URLs; DB connection URLs). A final
`generic-secret-assignment` rule catches `api_key = "..."` style assignments
ONLY when the captured value clears a Shannon-entropy floor (`>= 3.0` bits) so
`password = "changeme"` does not trip it. (The `.sh` mirror omits the
`aws-secret-key`, `stripe`-suffix nuance, `pypi-token`, and `twilio-key`
patterns present in the `.ps1`; treat `.ps1` as the verified superset.)

## 3. KEY=value vocabulary

Alphabetical. Every key any clipboard script can emit.

| Key | Meaning |
|---|---|
| `CLIP_BYTES` | UTF-8 byte count of clipboard text (read) or text written (write). |
| `CLIP_COUNT` | Number of files in a `CLIP_KIND=files` read. |
| `CLIP_KIND` | Clipboard content kind: `text` \| `image` \| `files` \| `empty`. |
| `CLIP_LINES` | Line count of clipboard text on read. |
| `CLIP_NOTE` | POSIX-only note (e.g. no clipboard tool installed). |
| `CLIP_PATH` | Temp PNG path for a captured clipboard image. |
| `CLIP_SCAN_ERROR` | secret-scan CLI error (missing path). |
| `CLIP_SECRETS` | Comma-separated secret types detected in clipboard text. |
| `CLIP_SECRET_COUNT` | Number of secret matches detected. |
| `CLIP_WRITE` | `ok` on a successful clipboard write, else `error: <reason>`. |
| `HISTORY_ADDED` | Id of the just-recorded history entry. |
| `HISTORY_CLEARED` | `1` after `clear`. |
| `HISTORY_COUNT` | Number of history entries (status / list header). |
| `HISTORY_DIR` | History store root path. |
| `HISTORY_ENABLED` | `0` / `1` recording state. |
| `HISTORY_ERROR` | History error (missing path, no such entry, payload missing, unknown verb). |
| `HISTORY_ID` | Id of the entry returned by `get`. |
| `HISTORY_KIND` | Kind of the entry returned by `get`. |
| `HISTORY_MATCHES` | Number of search hits. |
| `HISTORY_PATH` | Payload path for a non-text `get`. |
| `HISTORY_RECOPIED` | `clipboard` when a text `get` re-copies onto the clipboard. |
| `HISTORY_REMOVED` | Id removed by `rm`. |
| `HISTORY_SKIPPED` | Reason `add` was a no-op: `disabled` \| `too_large` \| `excluded` \| `secret:<types>`. |
| `SNIPPET_CLEARED` | `1` after `clear`. |
| `SNIPPET_COUNT` | Number of snippets (list header). |
| `SNIPPET_ERROR` | Snippet error (missing/invalid name, missing path, no snippet named, unknown verb). |
| `SNIPPET_KIND` | `image` for an image snippet returned by `get`. |
| `SNIPPET_MATCHES` | Number of search hits. |
| `SNIPPET_NAME` | Name of the snippet returned by `get`. |
| `SNIPPET_PATH` | Payload path for an image snippet `get`. |
| `SNIPPET_RECOPIED` | `clipboard` after a `get` re-copies onto the clipboard. |
| `SNIPPET_REFUSED` | `secret:<types>` when a text snippet save is refused. |
| `SNIPPET_REMOVED` | Name removed by `rm`. |
| `SNIPPET_SAVED` | Name of the just-saved snippet. |

Environment variables (clip-history only):

| Var | Effect |
|---|---|
| `RUNES_CLIP_HISTORY` | `1` forces recording on (overrides the `.enabled` flag). |
| `RUNES_HISTORY_EXCLUDE` | Regex; matching text payloads are dropped (`HISTORY_SKIPPED=excluded`). |
| `RUNES_HISTORY_MAX_ENTRIES` | Max retained entries (default 200); older entries pruned. |
| `RUNES_HISTORY_MAX_BYTES` | Max payload size in bytes (default 1048576); larger payloads skipped. |
