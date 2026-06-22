---
name: img
description: This skill should be used when the user asks to "/img", "what's in my recent screenshots", "look at the last N screenshots", "what does this screenshot/image say", "ask about the photos in <folder>", "compare my last few screenshots", or otherwise wants recent screenshots (or images in a folder) pulled in and questions answered about them.
version: 0.1.0
---

# img - ask questions about your images

Pull image files - recent screenshots by default, or any folder - and answer the
user's question about them: read the text in them, compare them, summarize a set.

## Steps

1. Translate the request into selection flags. The default source is the OS
   Screenshots folder; `-Dir`/`--dir` points at any folder.
   - relative window `-Within` / `--within` as a calendar bucket (0 = current period, 1 = previous): `t` / `today` / `0d`, `yesterday` / `1d`, `1w` (last week), `1m` (last month), or `<N>h|d|w|m|y`.
   - count (`-Count N` / `--count N`), `-Minutes`, `-Since`/`-Until` (exact dates), `-Name` (filename contains), `-Dir`. Flags combine.
   Run the finder:
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.ps1" <flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/image-find.sh" <flags>`
   With no selection it returns the single most recent screenshot.
2. Read `IMG_COUNT` and the listed paths. For ONE or a FEW images, Read them directly. For MANY images (or wide/hi-res ones), thumbnail first - but get a UNIQUE per-run workspace so concurrent `/img` runs never clobber each other's temp (do NOT use a fixed flat file like `%TEMP%\runes-shots.txt`): `workspace new -Plugin imageverse -Skill img` (`.sh`: `--plugin`/`--skill`) prints `WORKSPACE=<dir>` - that dir is a FIXED string for this run; INLINE it literally in each command (`$run` below is shorthand for it, NOT a shell var - vars don't persist across tool calls, so never stash the path in a flat file like `/tmp/...`). Then `image-find <flags> -OutFile "<workspace>\shots.txt"` and `thumbs -List "<workspace>\shots.txt" -OutDir "<workspace>\thumbs"` (keep temp paths in ONE shell - don't write with Bash `/tmp` and read from PowerShell as `C:\tmp`). Then Read the thumbnails in a SINGLE message so the reads run CONCURRENTLY (one turn) - do not read batch-after-batch across messages (that serialises into N turns); only split if a request is rejected for too many images. Map each `<thumb>\t<source>` back. Full-res reads of wide screenshots are wasteful and trip the 2000px/side cap; the 1600px thumbnail stays legible. Re-Read one source at full res only when tiny text needs it. `thumbs` reports `THUMB_SECONDS` - mention it (e.g. "100 thumbnails generated locally in 2.3s", no upload). When done, `workspace clean -Dir "$run"`. If `IMG_COUNT=0`, say so, list the searched `IMG_DIR` lines, and suggest `-Dir`.
3. Answer the user's question across the images, ALWAYS citing each image's FULL PATH (the finder lists them). With several, consider them in order (newest first) and be explicit about which image each observation comes from.
4. **OPTIONAL (opt-in, OFF by default) - warm the shared search cache.** You already vision-read these thumbnails to answer the question, so those observations can be written into the global `image-index` cache for free, leaving `/img-search` warm. This is best-effort and OPT-IN - do it ONLY when the user asks (e.g. "also index these") or a stored pref says so; do NOT add a turn or latency to the core flow by default. When doing it: re-run `image-find` with `-Hash` (so the content hash is populated - the cache is keyed by hash) if you have not already, then write one 11-column row per image to a `$run\put.tsv` and call `image-index put -Batch "$run\put.tsv"` (columns: `<hash>\t<path>\t<category>\t<subcategory>\t<activity>\t<place_path>\t<entities>\t<objects>\t<attributes>\t<caption>\t<text>`, same format `/img-search` uses; leave fields empty where not applicable but keep all 11 tabs). It is purely additive: writes are idempotent (last-write-wins per hash), so re-warming is always safe.

## Reply format

This is the shared rune reply shape: a CAST BANNER, a path line, a section
heading, then bullets. The spacing + glyph rules below are ABSOLUTE and identical
across every rune.

- **Cast banner first** - its own line: `ᚱ imageverse › /img` (the rune-letter `ᚱ`, the pack, then the rune as a slash-command, then `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it). The path line follows it.

- Every icon is a **full-width emoji** followed by **exactly one space**. NEVER use a variation-selector / text-style glyph that renders narrow and eats its space: banned are `👁` `🏷` `⚠️` `✏️` `✂️` `ℹ️` `🗂️` `🗑️`. Use the vetted full-width set: `📷` `📁` `📦` `💾` `📊` `📝` `📌` `🔖` `👀` `📄` `🔑` `🚩` `🔍`.
- The path lives ALONE on its line, in backticks, so prose never wraps around it.
- NO blank line between the section heading and the first bullet.
- The **first bullet is always `📌 **What:**`** - a one-line summary of the subject.
- Later bullets lead with a short **bold label**, with a leading icon + space only where it earns its place. Don't force an icon onto every bullet.
- **Nest detail as INDENTED sub-bullets** (2-space indent) under their parent bullet - lists, per-item counts, multi-part notes. Don't flatten everything to one level; the indent separates a breakdown from the top-line summary.

Per image: Line 1 is `📷 ` + the image path; Line 2 is the heading `👀 **Vision:**`;
then the bullets. With several images, repeat the `📷`/`👀` pair per image, newest
first, so each finding is clearly tied to its path.

- **A question was asked** -> answer it directly across the images, citing each path; don't inventory everything else in them.
- **No question (bare `/img`)** -> the two header lines, then at most 2-3 content bullets per image; don't volunteer critique. End by asking what they want to know.
- Keep it tight. Match the length of the reply to the size of the question, not the image count.

Shape for a bare `/img` on one screenshot:

```
ᚱ imageverse › /img v0.1.0
📷 `C:\Users\you\Pictures\Screenshots\Screenshot 2026-06-20 115825.png`
👀 **Vision:**
- 📌 **What:** web dashboard header screenshot.
- 📊 **Stats ticker:** P50 1.12 us, P99 8.42 us, MSGS/S 2.1 M, UPTIME 99.997%.
- 🔖 **Nav:** home / docs / pricing / about, account avatar.

What do you want to know about it?
```

## Notes

- Windows (verified) auto-detects `Pictures\Screenshots` + OneDrive; macOS/Linux via `image-find.sh`. `-Dir`/`--dir` points at any folder of images.
- Lists png/jpg/jpeg; reads only. For a single image on the clipboard, use the `clip` rune instead.
