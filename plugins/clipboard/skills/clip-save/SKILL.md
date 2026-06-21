---
name: clip-save
description: This skill should be used when the user asks to "/clip-save", "save my clipboard to <path>", "stash this screenshot", "write what I copied to a file", "save the copied files to <folder>", or otherwise wants the clipboard contents written to a file or folder on disk.
version: 0.1.0
---

# clip-save - save the clipboard to disk

Read the clipboard and write it to a destination on disk: text to a text file, an
image/screenshot to a PNG, or copied file(s) into a folder.

## Steps

1. Capture the clipboard, using the host OS backend. Windows (PowerShell, STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`
1b. **Secret guard.** If the capture reports `CLIP_SECRETS=<types>`, STOP and tell the user the content holds credentials (name the types) before writing it to disk. Offer to save a REDACTED copy instead (`secret-scan.ps1 -Path <file> -Redact` -> save the `-----BEGIN/END REDACTED-----` body), and only save the raw secret if they confirm. Saving a token to `Downloads` is a real footgun.
2. Resolve the destination:
   - If the arguments give a path or folder, use it (relative paths resolve to the current working directory; absolute paths as-is).
   - Otherwise use the clipboard outbox - its OWN subfolder so clips don't mix with other runes' output in `runes/`: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes\clips` (Windows) or `~/Downloads/runes/clips` (macOS/Linux). Create it if missing.
   - **Filename when not given:** `clip-<YYYYMMDD-HHMMSS>[-<short-slug>].<ext>`. ALWAYS include the full date AND time (to the second) so saves never collide and sort chronologically; add a short kebab-case content slug (a few words) only for readability, e.g. `clip-20260621-203811-history-notes.md`. Collision-safe: append ` (2)`, ` (3)` if it somehow exists; never overwrite.
3. Act on `CLIP_KIND`:
   - `text` -> the content is in the capture output between `-----BEGIN CLIP TEXT-----` and `-----END CLIP TEXT-----` (streamed, no `CLIP_PATH`). Write THAT text to the destination via the Write tool, and CHOOSE THE EXTENSION FROM WHAT THE CONTENT IS - do NOT default everything to `.md`:
     - plain prose / a paragraph / a list with no markdown syntax -> `.txt` (this is the DEFAULT for ordinary text).
     - genuine Markdown (`#` headings, `-`/`*` bullets, fenced code, `[]()` links) -> `.md`.
     - source code -> the language extension (`.py`, `.js`, `.ts`, `.rs`, `.go`, `.java`, `.sh`, `.sql`, `.html`, `.css`, ...).
     - structured data -> `.json` / `.yaml` / `.toml` / `.xml` / `.csv` / `.tsv` as appropriate.
     - a log / stack trace -> `.log`.
     When unsure between plain and markdown, pick `.txt` - reserve `.md` for text that actually uses markdown. An explicit extension in the arguments always wins.
   - `image` -> copy the PNG at `CLIP_PATH` to the destination (default extension `.png`).
   - `files` -> copy each listed path into the destination folder (or, for a single file and a file destination, to that path). Use a real file copy (`Copy-Item` / `cp`) so binaries are preserved.
   - `empty` -> tell the user there is nothing on the clipboard to save.
4. **Record to history** (best-effort, no-op when disabled). Run this as ITS OWN command and ignore the result - do NOT chain anything onto it, do NOT mix shells: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/clip-history.ps1" add -Kind <text|image|files> -Subtype <type> -Source clip-save -Path "<the saved file>"` (`.sh`: `--kind`/`--subtype`/`--source`/`--path`). Never append `2>$null`, `; (Get-Item ...)`, or other shell-specific syntax - a PowerShell `.ps1` invoked through the Bash tool will choke on PowerShell redirects/expressions. If it fails, shrug and continue; the save already succeeded. Secrets are skipped by the store regardless.
5. Confirm the **absolute** destination path(s) written, plus kind and size. Use the size you ALREADY have - `CLIP_BYTES` from the capture (text) or the bytes the Write/copy reported - do NOT run a separate `Get-Item ... .Length` query.
   Keep the SAVED FILE and the CHAT REPLY separate: the file on disk is the RAW content (extension by type, never reformatted). If the user ALSO asked a question about the content ("/clip-save and summarize", "save this and explain the errors"), answer it in the REPLY using structured markdown (headings/tables/bullets) - that rich answer goes in chat, never into the saved artifact.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-save` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📋` `📁` `📦` `💾` `📊` `📝` `📌` `🔖` `📄` `🔑` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of what was saved.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 is `📁 ` + the **absolute** destination path (one line per file for a
multi-file save). Line 2 is the heading `💾 **Saved:**`. Then the `📌 What` bullet
and a `📦 **Size:**` bullet for kind/size.

```
ᚱ clipboard › /clip-save v0.1.0
📁 `C:\Users\you\Downloads\runes\clips\clip-20260621-203811.png`
💾 **Saved:**
- 📌 **What:** clipboard screenshot written as PNG.
- 📦 **Size:** 1280x96, 38 KB.
```

## Notes

- Windows (verified) under STA; macOS/Linux via `clipboard-io.sh` (verify there).
- Do not overwrite an existing file without confirming, unless the user's path clearly means to replace it.
