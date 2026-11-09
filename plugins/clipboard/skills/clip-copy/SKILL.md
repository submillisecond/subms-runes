---
name: clip-copy
description: This skill should be used when the user asks to "/clip-copy", "copy that", "copy that to my clipboard", "copy the code", "copy just the command", "copy the URL/email/path", "copy the last answer as plain text", "put that on my clipboard", or otherwise wants a clean deliverable from YOUR recent output placed on the system clipboard. This is the Claude-output -> clipboard direction (the inverse of /clip, which reads the clipboard).
version: 0.2.0
---

# clip-copy - put a clean deliverable from your output onto the clipboard

Take the relevant deliverable from your OWN recent response, strip the
conversational scaffolding, and load the clean result onto the system clipboard so
the user can paste it straight away. This closes the loop the other clipboard runes
don't: `/clip` reads the clipboard, `/clip-edit` transforms it, `/clip-save` files
it - `/clip-copy` writes YOUR output to it.

## Steps

1. **Pick the deliverable** from the recent conversation - by default the single most
   useful artifact from your last substantive message; or the specific target the
   arguments name. Recognised targets (match the user's words, don't require exact
   flags):
   - `the code` / `just the code` -> the most recent/relevant code block, body only.
   - `the command` -> the shell command, ONE line, no leading `$`/`#` prompt, no fence.
   - `the url` / `the link` -> the URL only. `the email` -> the address (or the drafted email body if that's clearly what's meant). `the path` -> the file path.
   - `the json` / `the yaml` / `the config` -> that block, body only.
   - `the answer` / `the whole thing` -> your last message.
   - `as plain text` -> the chosen content with all markdown stripped (no fences, no `**`, no bullets-as-syntax).
   If the request is ambiguous (several code blocks, unclear which artifact), pick the
   most recent and say which you chose - or ask one short question only if genuinely unclear.

2. **Strip the scaffolding, preserve the code EXACTLY.** The clipboard gets the
   DELIVERABLE, not the prose: remove ``` fences, language tags, leading prompts
   (`$ `, `> `, `PS> `), explanatory sentences, and trailing commentary. A command is
   one paste-ready line (no trailing newline). For CODE, reproduce the block
   BYTE-FOR-BYTE as it would live in a file:
   - keep EXACT indentation, blank lines, and tabs-vs-spaces - do NOT re-indent.
   - do NOT reformat, prettify, re-wrap, sort, or "clean up" anything (no black/prettier/gofmt). Copy is faithful, not opinionated.
   - keep a trailing newline if the file form would have one; otherwise don't add one.
   For a long or whitespace-sensitive block, after writing the temp file (step 3),
   re-read it and confirm it matches the source block before loading the clipboard -
   a silent transcription drift would paste broken code.

3. **Write the clean text to a temp file** with the Write tool: `%TEMP%\runes\clipboard\copy-<stamp>.txt` (`$TMPDIR/runes/clipboard/` on macOS/Linux). The clipboard `write` backend loads from a file, and a file avoids any command-length limit on large payloads.

4. **Load it onto the clipboard.** Windows (STA):
   `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" write -Path "<temp file>"`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" write "<temp file>"`
   Expect `CLIP_WRITE=ok` (+ `CLIP_BYTES`).

5. **Record to history** (best-effort; no-op when disabled). Run it as ITS OWN command - do NOT chain `2>$null`, `;`, or `(Get-Item ...)` onto it (a `.ps1` invoked through the Bash tool chokes on PowerShell syntax); if it errors, ignore it, the copy already succeeded. Classify the artifact: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/clip-history.ps1" add -Kind text -Subtype <code|command|url|email|path|json|plain> -Source clip-copy -Path "<temp file>"` (`.sh`: `--kind`/`--subtype`/`--source`/`--path`). Secrets are skipped automatically by the store.

6. **Report** in the format below: what was copied + a short preview.

## Reply format

This is the shared rune reply shape: a CAST BANNER, then a section heading and
bullets. The spacing + glyph rules below are ABSOLUTE and identical across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-copy` plus `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it (the rune-letter `ᚱ`, the pack, the slash-command, the version).
- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a narrow variation-selector / text-style glyph that eats its space (banned: `👁` `🏷` `⚠️` `✂️` `⌨`). Use the vetted set: `📋` `📄` `📌` `🔗` `💻` `🔑` `🚩`.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - one line naming the deliverable copied.
- Keep it tight: the user wants confirmation + a glance at what landed, not the whole payload echoed.

Line 1 is the heading `📋 **Copied:**`. Then the `📌 What` bullet, a short
`📄 **Preview:**` (first line or ~80 chars; for a command show it verbatim), and the
size. If `clip-copy` had to choose among several artifacts, say which in the What line.

```
ᚱ clipboard › /clip-copy v0.1.0
📋 **Copied:**
- 📌 **What:** the install command (one line, prompt + fence stripped).
- 💻 **Preview:** `pnpm add -D vitest @vitest/coverage-v8`
- 📦 **Size:** 41 bytes. Ready to paste.
```

## Notes

- This rune REPLACES the clipboard (side effect) - the previous clipboard contents are gone. If the user might want them, suggest `/clip` first.
- It copies from YOUR output, so secrets are the user's own; the history store still refuses to persist anything secret-bearing.
- Windows backend is verified; macOS/Linux `clipboard-io.sh write` needs verification on those OSes.
