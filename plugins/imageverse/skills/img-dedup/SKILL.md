---
name: img-dedup
description: This skill should be used when the user asks to "/img-dedup", "find duplicate photos", "remove duplicate images", "dedupe my photos folder", "how many duplicate photos do I have", or otherwise wants exact-duplicate images in a folder found and (on confirmation) removed or archived.
version: 0.1.0
---

# img-dedup - find and remove duplicate images

Find EXACT duplicate images in a folder (identical file content) and, on
confirmation, remove or archive the extras while keeping one of each. Common in
phone-photo dumps where the same shot was copied several times.

## Steps

1. Take the folder from the arguments (required). Scan with hashes:
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.ps1" -Dir "<folder>" [-Recurse] -Hash`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.sh" --dir "<folder>" [--recurse] --hash`
   Each line is `<date>` TAB `<size>` TAB `<hash>` TAB `<path>`.
2. Group lines by the hash column. A hash shared by more than one file is a duplicate set.
3. For each set, pick ONE to KEEP (prefer: a file already in an organized path; else the shortest path; else the oldest by date). The rest are extras.
4. Show a DRY-RUN SUMMARY: number of duplicate sets, total extras, and wasted space (sum of extra sizes); list a few example sets. Ask for confirmation, and whether to DELETE the extras (recycle bin preferred) or MOVE them to an archive folder.
5. On confirmation, remove or move only the extras - never the kept copy. Prefer recycle / archive over a hard delete.
6. Report: sets resolved, files removed/archived, space reclaimed.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img-dedup` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📷` `📁` `📦` `📊` `📝` `📌` `🔖` `🔍` `🧹` `🚩`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the plan/result.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Line 1 is `📁 ` + the scanned folder. Line 2 is the heading: the dry-run preview
uses `🔍 **Plan:**`, and after the user confirms the result uses `🧹 **Cleaned:**`.
List only a few example sets - summarize the rest.

```
ᚱ imageverse › /img-dedup v0.1.0
📁 `C:\Users\you\Pictures\PhoneDump`
🔍 **Plan:**
- 📌 **What:** 37 duplicate sets, 84 extra copies to remove (keeping one each).
- 📦 **Reclaims:** 612 MB.
- 📊 **Example:** `IMG_2031.jpg` has 3 copies; keeping the oldest.

Delete extras to recycle bin, or move to an archive folder?
```

## Notes

- Exact-duplicate detection only (identical bytes, SHA1). Near-duplicates (re-encoded, resized, slightly edited) are NOT detected - a stated non-claim.
- MUTATES the folder. Dry-run + explicit confirmation required; prefer archive/recycle over hard delete; never remove the last copy of an image.
