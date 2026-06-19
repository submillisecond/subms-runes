---
name: dedup
description: This skill should be used when the user asks to "/dedup", "find duplicate photos", "remove duplicate images", "dedupe my photos folder", "how many duplicate photos do I have", or otherwise wants exact-duplicate images in a folder found and (on confirmation) removed or archived.
version: 0.1.0
---

# dedup - find and remove duplicate images

Find EXACT duplicate images in a folder (identical file content) and, on
confirmation, remove or archive the extras while keeping one of each. Common in
phone-photo dumps where the same shot was copied several times.

## Steps

1. Take the folder from the arguments (required). Scan with hashes:
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/photo-scan.ps1" -Dir "<folder>" [-Recurse] -Hash`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/photo-scan.sh" --dir "<folder>" [--recurse] --hash`
   Each line is `<date>` TAB `<size>` TAB `<hash>` TAB `<path>`.
2. Group lines by the hash column. A hash shared by more than one file is a duplicate set.
3. For each set, pick ONE to KEEP (prefer: a file already in an organized path; else the shortest path; else the oldest by date). The rest are extras.
4. Show a DRY-RUN SUMMARY: number of duplicate sets, total extras, and wasted space (sum of extra sizes); list a few example sets. Ask for confirmation, and whether to DELETE the extras (recycle bin preferred) or MOVE them to an archive folder.
5. On confirmation, remove or move only the extras - never the kept copy. Prefer recycle / archive over a hard delete.
6. Report: sets resolved, files removed/archived, space reclaimed.

## Notes

- Exact-duplicate detection only (identical bytes, SHA1). Near-duplicates (re-encoded, resized, slightly edited) are NOT detected - a stated non-claim.
- MUTATES the folder. Dry-run + explicit confirmation required; prefer archive/recycle over hard delete; never remove the last copy of an image.
