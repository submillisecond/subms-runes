---
name: img-save
description: This skill should be used when the user asks to "/img-save", "save my last N screenshots to <folder>", "bundle my recent screenshots", "copy the images from <folder> to <dest>", or otherwise wants a selection of image files copied to a destination (for sharing or a bug report).
version: 0.1.0
---

# img-save - copy a selection of images to a folder

Select images (recent screenshots by default, or any `--dir`) and COPY them to a
destination, leaving the originals in place.

## Steps

1. Select with the finder (same flags as `img`):
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.ps1" <flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.sh" <flags>`
   If no selection was given it returns only the most recent one - confirm that is intended before saving just one.
2. Resolve the destination:
   - An explicit path/folder in the arguments wins (relative -> cwd; absolute as-is).
   - Otherwise the runes outbox: `$RUNES_SAVE_DIR` if set, else `%USERPROFILE%\Downloads\runes\imageverse-<stamp>` (Windows) / `~/Downloads/runes/imageverse-<stamp>` (macOS/Linux). Create if missing.
3. Copy each listed path (`Copy-Item` / `cp`), preserving filenames. Never move or delete originals.
4. Report the absolute destination + count and total size copied, in the shape below.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img-save` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📷` `📁` `📦` `💾` `📊` `📝` `📌` `🔖` `📄` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of what was copied.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 is `📁 ` + the **absolute** destination folder. Line 2 is the heading
`💾 **Saved:**`. Then the `📌 What` bullet and a `📦 **Size:**` bullet for count/size.

```
ᚱ imageverse › /img-save v0.1.0
📁 `C:\Users\you\Downloads\runes\imageverse-20260620`
💾 **Saved:**
- 📌 **What:** 4 recent screenshots copied (originals left in place).
- 📦 **Size:** 4 files, 1.2 MB.
```
