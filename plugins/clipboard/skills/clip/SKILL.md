---
name: clip
description: This skill should be used when the user asks to "read my clipboard", "what's on my clipboard", "/clip", "ask about what I copied", "summarize what I copied", "what does this screenshot say", or otherwise wants the contents of the clipboard (text, an image, or copied files) inspected and questions answered about them.
version: 0.1.0
---

# clip - ask questions about your clipboard

Capture whatever is on the Windows clipboard - copied text, an image (screenshot
or picture), or copied file(s) - and answer the user's question about it.

## Steps

1. Capture the clipboard, using the host OS backend. On Windows (PowerShell, STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`
   On macOS/Linux:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`
2. Read `CLIP_KIND` from the output and act:
   - `text` -> the FULL content is in the script output itself, between the `-----BEGIN CLIP TEXT-----` and `-----END CLIP TEXT-----` markers (streamed as UTF-8, no file). Use it directly - do NOT look for a `CLIP_PATH`, text is never written to disk.
   - `image` -> Read the file at `CLIP_PATH` (the Read tool renders the image; only images use a file).
   - `files` -> Read each listed path, and ALWAYS state each file's FULL PATH in the reply (not just the name). The Read tool handles text, code, markdown, JSON/YAML, images, PDFs, and notebooks. For unsupported binaries (.docx, .xlsx, .zip), say so (with the path) and suggest copying the contents as text instead.
   - `empty` -> Tell the user the clipboard is empty and to copy something first.
2b. **Secret guard.** If the output carries `CLIP_SECRETS=<types>` (the capture scanned the text and found credentials - API keys, tokens, private keys, connection strings), LEAD the reply with a `🚩` warning naming the types, and do NOT echo the secret values back verbatim (mask them, e.g. `ghp_****`). Still answer the question, just without surfacing the raw secret. Offer to redact: a redacted copy is one step away via `secret-scan.ps1 -Path <file> -Redact` (`.sh`: `--path`/`--redact`) or `/clip-edit redact the secrets`.
3. Answer the user's question (the skill arguments). When the clipboard held file(s), include the full path(s); for a saved image, include `CLIP_PATH`.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📋` `📷` `📁` `📦` `💾` `📊` `📝` `📌` `🔖` `👀` `📄` `📭` `🔑` `🚩` `🧹` `🔍`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the subject/result.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place. Don't force an icon onto every bullet.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 (capture) - a path line ONLY when there is a file: an `image` (its
`CLIP_PATH`) or `files` (each path). `text` has NO file, so it gets NO path line -
go straight to the heading.

```
📋 `C:\...\clip-20260620-115840-246.png`
```

Line 2 (section heading) - a kind icon, a space, a **bold label** ending in a
colon, nothing else (the subject goes in the `📌 What` bullet, not here):

- image -> `👀 **Vision:**` (after its path line)
- text -> `📄 **Text:**` (no path line above it - text is not saved)
- files -> `📁 **Files:**` (repeat the path per file)
- empty -> `📭 **Empty.**` (no path line; just say to copy something first)

Rules for the body:

- **Lead with the answer**, not the mechanics. Don't narrate the capture step or restate `CLIP_KIND`.
- **A question was asked** -> answer it directly and only it. Pull just the detail the question needs; don't inventory the rest of the clipboard.
- **No question (bare `/clip`)** -> the two header lines, then at most 2-3 content bullets of the salient detail. Do NOT produce an exhaustive element-by-element list, and do NOT volunteer critique, analysis, or "things worth flagging" - end by asking what they want to know.
- Keep it tight. Match the length of the reply to the size of the question, not the size of the clipboard.

Shape for a bare `/clip` on an image (banner first, then the two header lines):

```
ᚱ clipboard › /clip v0.1.0
📋 `C:\...\clip-20260620-115840-246.png`
👀 **Vision:**
- 📌 **What:** web dashboard header screenshot.
- 📊 **Stats ticker:** P50 1.12 us, P99 8.42 us, MSGS/S 2.1 M, UPTIME 99.997%.
- 🔖 **Nav:** home / docs / pricing / about, account avatar.

What do you want to know about it?
```

## Notes

- Windows (verified) uses `Get-Clipboard` under STA. macOS/Linux use the
  `clipboard-io.sh` backend (pbpaste / xclip / wl-paste) - verify on those OSes.
- Captured payloads go to the per-plugin temp dir (`%TEMP%\runes\clipboard\` or `$TMPDIR/runes/clipboard`). Clipboard contents may be sensitive - they are pulled into the conversation.
