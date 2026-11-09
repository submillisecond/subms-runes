---
name: clip-ocr
description: This skill should be used when the user asks to "/clip-ocr", "what does this screenshot say", "read the text in my clipboard image", "transcribe this image", "extract the text from this screenshot", "ocr <path-to-image>", "transcribe this attached image", "OCR the clipboard", and (only if they say so) "...and copy it" / "...and save it to a file". The image can come from an attachment in the prompt, an explicit file path in the arguments, or the clipboard (default). By default it PRINTS the transcribed text in the reply; copying to the clipboard or saving to a file are opt-in.
version: 0.2.0
---

# clip-ocr - read the text out of a clipboard image

Transcribe the text inside the image on the clipboard and, by DEFAULT, print it in
the reply so it can be read and copied by hand. Putting it back on the clipboard or
saving it to a file happen ONLY when the request asks for them. The transcription is
vision-based - no OCR engine to install.

## Steps

1. **Find the image to transcribe - check sources in this order, the clipboard is just the default:**
   - **Attached to the prompt:** if the user attached/pasted an image into THIS message, you already see it - transcribe that directly, no capture or file needed. (Pasting into the Claude Code prompt, not via a rune, is the fastest path.)
   - **An explicit file path in the arguments** (`/clip-ocr C:\shots\err.png`, "ocr ~/Pictures/x.png"): Read that path directly. A folder or several paths -> transcribe each.
   - **Otherwise, the clipboard.** Windows (STA): `powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.ps1" read`; macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clipboard-io.sh" read`.
2. For the CLIPBOARD path, check `CLIP_KIND`:
   - `image` -> proceed with `CLIP_PATH` (the captured PNG).
   - `files` -> if a single image file was copied, transcribe that path; else say what was copied.
   - `text` -> there is already text on the clipboard, nothing to OCR; point them at `/clip`.
   - `empty` -> ask them to copy/screenshot an image, attach one to the prompt, or give a file path.
3. **Read the image** (the Read tool renders `CLIP_PATH`) and TRANSCRIBE the text faithfully:
   - Verbatim - exact wording, casing, punctuation, numbers.
   - Preserve meaningful structure: keep line breaks; for code or a table keep the layout; for flowing prose join wrapped lines into paragraphs.
   - All of it by default; if the arguments scope it ("just the error", "only the code"), transcribe that part.
   - Illegible text -> mark `[illegible]`, never invent.
4. **Decide the destination from the request - default is PRINT:**
   - **Default (no copy/save asked): print only.** Put the full transcription in the reply inside a fenced block; create NO temp file, do NOT touch the clipboard.
   - **"...copy it" / "onto my clipboard" / "as text":** ALSO put it on the clipboard - write the text to `%TEMP%\runes\clipboard\ocr-<stamp>.txt` then `clipboard-io.ps1 write -Path "<that file>"` (`.sh`: `... write "<file>"`); expect `CLIP_WRITE=ok`.
   - **"...save it" / "to a file" / "to <path>":** ALSO write it to disk - to the given path, or default `%USERPROFILE%\Downloads\runes\clips\ocr-<YYYYMMDD-HHMMSS>.txt` (extension by content, like `/clip-save`).
   - The user can ask for both (copy AND save). Only create files for the destinations actually requested.
5. **Record to history** ONLY if it went to the clipboard (best-effort, no-op when disabled; run it standalone, never chain shell syntax): `clip-history.ps1 add -Kind text -Subtype <code|plain|...> -Source clip-ocr -Path "<the temp/saved file>"`.
6. **Report** in the format below.

## Reply format

Shared rune shape: a CAST BANNER, then a section heading and bullets. Spacing +
glyph rules are ABSOLUTE and identical across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-ocr` plus `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it.
- Every icon is a **full-width emoji** + **exactly one space**. Vetted set: `📋` `🔡` `📄` `📌` `🔢` `💾` `🚩`.
- NO blank line between the heading and the first bullet. First bullet is always `📌 **What:**`.

DEFAULT (print) - heading `🔡 **Transcribed:**`, the `📌 What` bullet, then the FULL
text in a fenced block (so the user can select/copy it), and a `🔢` size line. Note
that they can add "copy it" or "save it" to also place it.

```
ᚱ clipboard › /clip-ocr v0.1.0
🔡 **Transcribed:**
- 📌 **What:** the error dialog text (verbatim).
- 🔢 **Size:** 3 lines, 142 chars. Add "copy it" / "save it" to place it.

​```
Unhandled exception: System.NullReferenceException
  at App.Run() line 42
  at Program.Main()
​```
```

If COPIED/SAVED, add a `📋 **Clipboard:** on the clipboard` and/or `💾 **Saved:** <path>`
bullet; for a long transcription that you copied/saved you may show a short preview
instead of the full block.

## Notes

- Default is print-only: no clipboard side effect, no temp file. Copy/save are opt-in.
- Vision-based; tiny/low-contrast text may be imperfect - it marks `[illegible]` rather than guessing. Windows verified; macOS/Linux `clipboard-io.sh` needs verification.
