---
name: ask
description: This skill should be used when the user asks to "/ask" about images, "what's in my recent screenshots", "look at the last N screenshots", "what does this screenshot/image say", "ask about the photos in <folder>", "compare my last few screenshots", or otherwise wants recent screenshots (or images in a folder) pulled in and questions answered about them.
version: 0.1.0
---

# ask - ask questions about your images

Pull image files - recent screenshots by default, or any folder - and answer the
user's question about them: read the text in them, compare them, summarize a set.

## Steps

1. Translate the request into selection flags. The default source is the OS
   Screenshots folder; `-Dir`/`--dir` points at any folder.
   - relative window `-Within` / `--within` as a calendar bucket (0 = current period, 1 = previous): `t` / `today` / `0d`, `yesterday` / `1d`, `1w` (last week), `1m` (last month), or `<N>h|d|w|m|y`.
   - count (`-Count N` / `--count N`), `-Minutes`, `-Since`/`-Until` (exact dates), `-Name` (filename contains), `-Dir`. Flags combine.
   Run the finder:
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.ps1" <flags>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.sh" <flags>`
   With no selection it returns the single most recent screenshot.
2. Read `SHOTS_COUNT` and each listed path; Read each image (the Read tool renders images). If `SHOTS_COUNT=0`, say so, list the searched `SHOTS_DIR` lines, and suggest `-Dir`.
3. Answer the user's question across the images. With several, consider them in order (newest first) and be explicit about which image each observation comes from.

## Notes

- Windows (verified) auto-detects `Pictures\Screenshots` + OneDrive; macOS/Linux via `recent-shots.sh`. `-Dir`/`--dir` points at any folder of images.
- Lists png/jpg/jpeg; reads only. For a single image on the clipboard, use the `clip` rune instead.
