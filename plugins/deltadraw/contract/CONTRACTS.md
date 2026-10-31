# deltadraw plugin - canonical contract

The canonical contract for the deltadraw pack: its MCP server entry and its three
scripts. Skill docs under `../skills/` POINT here; they do not restate it.
ASCII only.

The `.ps1` backends are the verified ones on Windows; the `.sh` files are ports
and are annotated as such in their headers. BOTH are covered by
`contract-test.sh`, which runs them against the same fixture, because the whole
value of `dd-url` is that the URL it prints decodes to exactly the file.

## 1. What the pack does NOT own

The scene GRAMMAR is not defined here and must not be copied here. It is
generated from the compiler in the `subms-ui` repository and served at
`https://www.submillisecond.com/deltadraw/spec.md`. A rune that needs the
grammar fetches the spec or calls `deltadraw_spec`.

Compiling, rendering and packing paintings are not done here either: the engine
is not shipped in the pack. They run in the hosted worker, reached through the
MCP server (section 2) or `dd-png` (section 4). Turning a deltalab painting into
an exact `#p1` link needs the engine's packer and is MCP-only
(`deltadraw_pack`).

## 2. MCP server

`.mcp.json` at the pack root registers one server:

| Name | Transport | URL |
|---|---|---|
| `deltadraw` | Streamable HTTP, stateless, no auth | `https://deltadraw.submillisecond.com/mcp` |

Every request carries `X-Runes-Pack: deltadraw/<version>`, the version in
`plugin.json`. At 1.0.0 the server sets no minimum and ignores it; it is sent so
a minimum can be introduced without a pack change.

The tool, prompt and resource lists are the server's, read live from
`tools/list`; the pack does not pin them. At 1.1.0 they are tools
`deltadraw_check`, `deltadraw_url`, `deltadraw_png`, `deltadraw_svg`,
`deltadraw_gif`, `deltadraw_pack`, `deltadraw_to_scene`, `deltadraw_symbols`,
`deltadraw_spec`; prompts `draw`, `refine`. `deltadraw_png` and
`deltadraw_svg` take a 1-based `page` for a multi-page drawing (an animation);
`deltadraw_gif` returns the animation as `image/gif` content.

## 3. `dd-url` - scene file -> viewer URL

| Backend | Command |
|---|---|
| PowerShell | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/dd-url.ps1 <file\|-> [-Title T] [-Theme light\|dark] [-Replay] [-Edit] [-Compress] [-Base URL]` |
| POSIX | `bash scripts/dd-url.sh <file\|-> [--title T] [--theme light\|dark] [--replay] [--edit] [--compress] [--base URL]` |

`-` reads the scene from stdin. No network.

### Output

Two `KEY=value` lines on stdout, in this order, exit 0:

| Key | Value |
|---|---|
| `URL` | `<Base>#dsl=<encoded scene>` (or `#d1=<packed scene>` with compress) followed by the option pairs that were set, in the fixed order `title`, `theme`, `replay`, `edit` |
| `LENGTH` | the character count of `URL` |

`replay` and `edit` are bare flags in the URL (`&replay`, `&edit`).

Errors: one `ERROR=<reason>` line on stderr, exit 2. Reasons: no scene file;
unknown flag; theme not `light`/`dark`; compress without `gzip` on PATH (`.sh`
only).

### Encoding rule

The scene is trimmed (leading blank lines, trailing whitespace) with CRLF
normalised to LF.

- Plain (default): percent-encoded over its UTF-8 bytes: the RFC 3986
  unreserved set (`A-Z a-z 0-9 - _ . ~`) is kept, every other byte becomes
  `%XX` with upper-case hex. Colours (`#`), `&` and `+` are therefore always
  escaped. Both backends print byte-identical output.
- Compressed (`compress`): raw DEFLATE of the UTF-8 bytes, base64url, no
  padding, under the `d1` key. Two deflaters need not emit the same bytes, so
  the guarantee is that each backend's `d1` inflates to the trimmed scene.

`theme` accepts `white` as `light` and `night` as `dark`, emitted canonical.

### Default base

`https://www.submillisecond.com/deltadraw`. `-Base` / `--base` overrides it.

## 4. `dd-png` - scene file -> PNG file

| Backend | Command |
|---|---|
| PowerShell | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/dd-png.ps1 <file\|-> -Out out.png [-Width N] [-Page N] [-HostUrl URL]` |
| POSIX | `bash scripts/dd-png.sh <file\|-> --out out.png [--width N] [--page N] [--host URL]` |

POSTs the scene (CRLF normalised to LF) as `text/plain` to
`<host>/png?width=<N>` (default 1200), with `&page=<N>` when a page is given
(1-based; a multi-page drawing renders its first page otherwise), and writes the
PNG. Needs the network; the `.sh` needs `curl`. A page that is not a whole
number from 1 is a usage error.

| Exit | Meaning | Output |
|---|---|---|
| 0 | written | `PNG=<path>` and `BYTES=<n>` on stdout |
| 1 | nothing drew (worker 422) | the worker's JSON report on stderr |
| 2 | usage error, network failure, or any other status | one `ERROR=<reason>` line on stderr |

Default host: `https://deltadraw.submillisecond.com`.

## 5. `dd-gif` - scene file -> animated GIF file

| Backend | Command |
|---|---|
| PowerShell | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/dd-gif.ps1 <file\|-> -Out out.gif [-Mode pages\|replay] [-Width N] [-HostUrl URL]` |
| POSIX | `bash scripts/dd-gif.sh <file\|-> --out out.gif [--mode pages\|replay] [--width N] [--host URL]` |

POSTs the scene to `<host>/gif?width=<N>` (default 720, the worker caps it at
1200), with `&mode=<mode>` when given. `pages` plays the drawing's pages as
frames at their frame times (scenes written with `page` / `tween`); `replay`
shows the first page being drawn. Without a mode the worker picks pages when there
are pages, else replay. Same exits as `dd-png`, with `GIF=<path>` in place of
`PNG=`. A mode other than `pages` or `replay` is a usage error.

## 6. Verified by

`contract-test.sh`, offline: both `dd-url` backends over one fixture carrying
every character class the encoder must get right (`#`, `&`, `+`, `(`, `)`,
`"`, space, newline, a multi-byte character); plain outputs identical; each
`URL` decodes (or inflates) back to the fixture; `LENGTH` matches; options in
the documented order and spelling; error paths exit 2 with `ERROR=`; `dd-png`
and `dd-gif` usage errors; every flag named here is handled by both scripts; `.mcp.json`
names the server in section 2; SKILL.md points here and at the spec.
`live-test.sh` checks the hosted worker serves every tool the pack names and
renders a `dd-url` link, a `dd-png` request, a page of a multi-page scene and a
`dd-gif` animation.
