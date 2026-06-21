---
name: clip-history
description: This skill should be used when the user asks to "/clip-history", "show my clipboard history", "what did I copy earlier", "recall the last URL I copied", "re-copy that python function", "paste back the command from before", "search my clip history for X", "clear my clipboard history", or "enable/disable clipboard history". Manages the durable, typed, searchable history of clipboard operations and re-copies a recalled entry back onto the clipboard.
version: 0.1.0
---

# clip-history - recall and manage your clipboard history

A durable, typed, searchable log of clipboard operations. Privacy-first: it is OFF
by default (the user opts in), secrets are never stored, entries live owner-only
under the per-user app-data dir, and size/count caps bound it. This rune views,
searches, recalls (re-copies), and manages that store.

Backend (Windows): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/clip-history.ps1" <verb> [flags]`.
macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clip-history.sh" <verb> [flags]`.

## Steps

1. **Read the request and pick the verb:**
   - view -> `list [-Count N]` (`.sh`: `--count`). Newest first; each row is `#n  <id>  <kind>/<subtype>  <bytes>  <source>  <preview>`.
   - search -> `search -Query <text>` (`--query`) when the user names a substring.
   - recall ("the last url", "that python function", "#2", an id) -> see step 2.
   - enable / disable / status -> toggle or report recording.
   - delete one / all -> `rm -Id <id|#n>` / `clear`.

2. **Recall is the headline action - and natural language is YOUR job.** Run `list`
   (or `search` with a keyword), read the TYPED rows, and pick the entry the user
   means: "the last url" -> the newest row whose subtype is `url`; "that python
   function" -> the newest `code` row whose preview looks like Python; "#2" -> that
   index. Then `get -Id <id-or-#n>` - the backend prints the content AND **re-copies
   it onto the clipboard** (`HISTORY_RECOPIED=clipboard`). Confirm what is now on the
   clipboard. If nothing matches, say so and show the closest few rows.

3. **Enabling.** If the user wants history but it is off (`HISTORY_ENABLED=0`), run
   `enable` and tell them recording is now on (only future operations are captured;
   nothing was logged while off). Mention it stores under the owner-only app-data dir
   and skips secrets.

4. **Report** in the format below.

## Reply format

This is the shared rune reply shape: a CAST BANNER, then a section heading and
bullets. The spacing + glyph rules are ABSOLUTE and identical across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-history` plus `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it.
- Every icon is a **full-width emoji** + **exactly one space**. Vetted set: `📋` `🕘` `🔁` `🔍` `📄` `📌` `🔢` `🧹` `🚩`.
- NO blank line between the section heading and the first bullet. First bullet is always `📌 **What:**`.
- For a `list`, render the rows as a compact numbered list (`#n` + type + preview) - never dump payloads; recall is one extra step.

Headings by action: recall -> `🔁 **Recalled:**`; list -> `🕘 **History:**`; search -> `🔍 **Found:**`; enable/disable -> `📋 **History:**`; clear/rm -> `🧹 **Cleared:**`.

```
ᚱ clipboard › /clip-history v0.1.0
🔁 **Recalled:**
- 📌 **What:** the last URL you copied - now back on your clipboard.
- 🔗 https://example.com/dashboard
- 🕘 from #2 (text/url, copied 11:04 via clip).
```

```
ᚱ clipboard › /clip-history v0.1.0
🕘 **History:** (5 most recent)
- #1 `text/command` - `pnpm add -D vitest`
- #2 `text/url` - `https://example.com/dashboard`
- #3 `text/code` - `def add(a, b): return a + b`

Say "recall #2" or "re-copy the command" to put one back on the clipboard.
```

## Notes

- OFF by default. `status` reports whether recording is on; `enable`/`disable` toggle a persisted flag. `RUNES_CLIP_HISTORY=1` also forces it on.
- Secrets are NEVER stored (the store scans every text entry and skips secret-bearing ones). Tune with `RUNES_HISTORY_EXCLUDE` (regex), `RUNES_HISTORY_MAX_ENTRIES` (default 200), `RUNES_HISTORY_MAX_BYTES` (default 1 MB/entry).
- Recall re-copies onto the clipboard - a side effect. Windows backend verified; macOS/Linux needs verification.
