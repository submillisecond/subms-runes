---
name: shots
description: This skill should be used when the user asks to "/shots", "the last N screenshots", "screenshots from the last X minutes", "look at my recent screenshots", "add my screenshots", "compare my last few screenshots", or otherwise wants recent screenshot files (from the Windows Screenshots folder) pulled in and questions answered about them.
version: 0.1.0
---

# shots - ask about your recent screenshots

Pull recent screenshot files from the Windows Screenshots folder(s) and answer
the user's question about them - read the text in them, compare them, summarize a
sequence, and so on. This is the file-on-disk complement to `clip` (which reads a
single image off the clipboard).

## Steps

1. Translate the request into selection flags (PowerShell `-Flag` / shell `--flag`):
   - count ("last 3" -> `-Count 3` / `--count 3`),
   - minutes ("last 10 minutes" -> `-Minutes 10` / `--minutes 10`),
   - `-Today`/`--today`, `-Yesterday`/`--yesterday`,
   - since/until ("since 2pm" -> `-Since "14:00"` / `--since "14:00"`; also `-Until`),
   - name ("with 'error' in the name" -> `-Name error` / `--name error`),
   - folder ("in D:\caps" -> `-Dir "D:\caps"` / `--dir`).
   Flags combine. If nothing is specified, the finder returns the single most recent screenshot. "The screenshot of the X" - select a small recent set, then Read them and pick.
2. Run the finder for the host OS (it only lists files), omitting flags not used.
   Windows: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.ps1" -Count <n> -Minutes <m>`
   macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/recent-shots.sh" --count <n> --minutes <m>`
3. Read `SHOTS_COUNT` and the listed paths (newest first). Read each image path - the Read tool renders images. If `SHOTS_COUNT=0`, tell the user none were found, list the searched folders (the `SHOTS_DIR` lines), and suggest `-Dir`.
4. Answer the user's question across the screenshots. With several, consider them in order and be explicit about which screenshot each observation comes from.

## Notes

- Windows (verified) auto-detects `Pictures\Screenshots` + OneDrive variants.
  macOS/Linux via `recent-shots.sh` (macOS: `screencapture` location / `~/Desktop`;
  Linux: `~/Pictures[/Screenshots]` + `$XDG_PICTURES_DIR`) - verify there. `-Dir`/`--dir` overrides.
- Lists png/jpg/jpeg only; never moves or modifies the files.
- Win+Shift+S snips that were only copied (not saved) are not files - use `/clip` for those.
