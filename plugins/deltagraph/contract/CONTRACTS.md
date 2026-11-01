# deltagraph plugin - canonical contract

The canonical contract for the deltagraph pack: its MCP server entry and its
two scripts. Skill docs under `../skills/` POINT here; they do not restate it.
ASCII only.

The `.ps1` backends are the verified ones; the `.sh` files are ports and are
annotated as such in their headers. BOTH are covered by `contract-test.sh`,
which runs them against the same fixture, because the whole value of
`dg-url` is that the URL it prints decodes to exactly the file.

## 1. What the pack does NOT own

The diagram GRAMMAR is not defined here and must not be copied here. It is
generated from the engine in the `subms-ui` repository and served at
`https://www.submillisecond.com/deltagraph/spec.md` (version stamped in the
file). The compact form is in `https://www.submillisecond.com/llms.txt`. A
rune that needs the grammar fetches the spec; a rune doc that quotes a rule
quotes it as a reminder with the spec as the authority.

Validation, layout and debugging are not done here either: the engine is not
shipped in the pack. They run in the hosted worker, reached through the MCP
server (section 2) or `dg-debug` (section 4).

## 2. MCP server

`.mcp.json` at the pack root registers one server:

| Name | Transport | URL |
|---|---|---|
| `deltagraph` | Streamable HTTP, stateless, no auth | `https://deltagraph.submillisecond.com/mcp` |

Every request carries `X-Runes-Pack: deltagraph/<version>`, the version in
`plugin.json`. When it is older than the server's minimum, the server adds an
upgrade line to the `initialize` instructions and to every tool result, telling
the user to run `/plugin marketplace update subms-runes`. `release-bump.sh`
moves the header with the version.

The tool, prompt and resource lists are the server's, read live from
`tools/list`; the pack does not pin them. At 1.0.0 they are tools
`deltagraph_check`, `deltagraph_debug`, `deltagraph_url`, `deltagraph_svg`,
`deltagraph_png`, `deltagraph_edit`, `deltagraph_diff`, `deltagraph_merge`,
`deltagraph_from_code`, `deltagraph_spec`; prompts `draw`, `evolve`, `tidy`.

## 3. `dg-url` - source file -> viewer URL

Invocation, both backends:

| Backend | Command |
|---|---|
| PowerShell | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/dg-url.ps1 <file\|-> [-Title T] [-Theme light\|dark] [-Bg B] [-Dir LR\|TD] [-ShowDebug] [-Edit] [-Compress] [-Base URL]` |
| POSIX | `bash scripts/dg-url.sh <file\|-> [--title T] [--theme light\|dark] [--bg B] [--dir LR\|TD] [--debug] [--edit] [--compress] [--base URL]` |

`-` reads the source from stdin. No network.

### Output

Two `KEY=value` lines on stdout, in this order, exit 0:

| Key | Value |
|---|---|
| `URL` | `<Base>#dsl=<encoded source>` (or `#d1=<packed source>` with compress) followed by the option pairs that were set, in the fixed order `title`, `theme`, `bg`, `dir`, `debug`, `edit` |
| `LENGTH` | the character count of `URL` |

Errors: one `ERROR=<reason>` line on stderr, exit 2. Reasons: no source file;
unknown flag; theme not `light`/`dark`; bg not one of the values below; dir
not `LR`/`TD`; compress without `gzip` on PATH (`.sh` only).

### Encoding rule

The source is trimmed (leading blank lines, trailing whitespace) with CRLF
normalised to LF.

- Plain (default): percent-encoded over its UTF-8 bytes: the RFC 3986
  unreserved set (`A-Z a-z 0-9 - _ . ~`) is kept, every other byte becomes
  `%XX` with upper-case hex. `&` is therefore always escaped. Both backends
  print byte-identical output. Not `[uri]::EscapeDataString` / `jq @uri`:
  their treatment of `! * ' ( )` differs across runtimes.
- Compressed (`compress`): raw DEFLATE of the UTF-8 bytes, base64url, no
  padding, under the `d1` key - the form the viewer and the worker read. Two
  deflaters need not emit the same bytes, so the guarantee is that each
  backend's `d1` inflates to the trimmed source, not that the strings match.

The title is encoded the plain way in both forms. `theme` accepts `white` as
`light` and `night` as `dark`; `dir` accepts `TB` as `TD`; both are emitted in
the canonical spelling. `bg` accepts `transparent`, `black`, `white`, `auto`,
or a 3- or 6-digit hex colour with or without `#`, any case; it is emitted
lower-case, without `#`, with a 3-digit colour expanded to 6.

### Default base

`https://deltagraph.submillisecond.com/`. `-Base` / `--base` overrides it,
for a local viewer (`http://localhost:3030/deltagraph`).

## 4. `dg-debug` - source file -> debug report

| Backend | Command |
|---|---|
| PowerShell | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/dg-debug.ps1 <file\|-> [-Json] [-Review out.svg] [-NoOptimise] [-Tries N] [-HostUrl URL]` |
| POSIX | `bash scripts/dg-debug.sh <file\|-> [--json] [--review out.svg] [--no-optimise] [--tries N] [--host URL]` |

POSTs the source (CRLF normalised to LF) as `text/plain` to
`<host>/debug?format=text|json` and prints the worker's body on stdout, ending
in a newline. Needs the network; the `.sh` needs `curl`.

| Exit | Meaning |
|---|---|
| 0 | the source renders (the report may still list problems) |
| 1 | the source does not render; the report says why |
| 2 | usage error, network failure, or any other worker status; one `ERROR=<reason>` line on stderr |

`review` additionally fetches `format=svg` (the diagram with problem edges
amber and clipped nodes red, on the layout that has them) into the named file
and prints `REVIEW=<path>` on stderr. Only when the source renders.

The report's content is the worker's and is not pinned here. Its JSON shape
(`renders`, `kind`, `findings[]` of `{line?, severity, rule, message, fix?}`,
`layout`, `alternatives[]`, `suggestions[]`, `links`) is defined in
`subms-ui/apps/web/lib/deltagraph-debug.ts`.

Default host: `https://deltagraph.submillisecond.com`.

## 5. Verified by

`contract-test.sh`. For `dg-url`: runs both backends over one fixture that
carries every character class the encoder has to get right (`&`, `|`, `#`,
`(`, `)`, `+`, space, newline, a multi-byte character), asserts the plain
outputs are identical, that each `URL` line decodes back to the fixture (and,
compressed, inflates back to it), that `LENGTH` matches, that each option
lands in the documented order and spelling, and that the error paths exit 2
with `ERROR=` on stderr. For `dg-debug`: the usage error paths only, offline;
its report is the worker's, tested in `subms-ui`. Also checks that every flag
named here is handled by both scripts, that `.mcp.json` names the server in
section 2, and that SKILL.md documents every option it would otherwise
describe from memory. Does not reach the network and does not exercise the
viewer.
