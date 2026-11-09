---
name: clip-snippet
description: This skill should be used when the user asks to "/clip-snippet", "save this as a snippet called X", "save the clipboard as 'mit-header'", "save this image as a logo snippet", "paste my mit-header snippet", "recall the X snippet", "what snippets do I have", "list my snippets", "delete the X snippet", or otherwise wants to keep a NAMED, reusable clipboard snippet (text or image) and recall it onto the clipboard later. Distinct from /clip-history (automatic chronological log) - this is a curated library you name.
version: 0.2.0
---

# clip-snippet - a named, curated snippet library

Save reusable boilerplate by NAME - license headers, config templates, command
recipes, canned replies, a logo or signature image - and recall any of them onto
the clipboard on demand. Always available (no enable flag, unlike `/clip-history`);
text snippets that contain credentials are refused.

Backend (Windows): `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/clip-snippet.ps1" <verb> [flags]`.
macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/clip-snippet.sh" <verb> [flags]`.

## Steps

1. **Pick the action** from the request: save, recall (get), list, search, delete.

2. **save** - capture what to store, then save it under the name:
   - Source: by default the CURRENT clipboard (capture via `clipboard-io.ps1 read`). For `text`, write the captured text (the `-----BEGIN/END CLIP TEXT-----` body) to a temp file; for an `image`, use the captured `CLIP_PATH`. The user may instead point at explicit content ("save this code as ...").
   - `clip-snippet save -Name "<name>" -Kind <text|image> -Subtype <code|command|url|yaml|...> -Path "<temp/CLIP_PATH>"` (`.sh`: `--name`/`--kind`/`--subtype`/`--path`). Names are sanitised to kebab-case (`MIT Header` -> `mit-header`); saving an existing name UPDATES it.
   - If it prints `SNIPPET_REFUSED=secret:<types>`, tell the user the snippet holds credentials and was not saved (a snippet library is for reusable boilerplate, not secrets).

3. **recall (get)** - `clip-snippet get -Name "<name>"` (`--name`). It re-copies the snippet onto the clipboard (`SNIPPET_RECOPIED=clipboard`). For text it returns the body between `-----BEGIN/END CLIP TEXT-----`; for an image it returns `SNIPPET_KIND=image` + `SNIPPET_PATH` (Read that path to show it). If the name is unknown, run `list` and suggest the closest matches.

4. **list / search / delete** - `list` (all snippets: `name  kind/subtype  bytes  preview`), `search -Query <text>` (name/preview/content), `rm -Name <name>`, `clear`.

5. **Report** in the format below.

## Reply format

Shared rune shape: a CAST BANNER, then a section heading and bullets. Spacing +
glyph rules are ABSOLUTE and identical across every rune.

- **Cast banner first** - its own line: `ᚱ clipboard › /clip-snippet` plus `v<version>` from this skill's frontmatter `version:` - ALWAYS include the version (e.g. `v0.1.0`), NEVER omit it.
- Every icon is a **full-width emoji** + **exactly one space**. Vetted set: `📋` `🔖` `🔁` `🗂` `🔍` `📄` `📌` `🧹` `🚩`.
- NO blank line between the heading and the first bullet. First bullet is always `📌 **What:**`.
- For a `list`, a compact named list (name + kind + preview) - never dump payloads.

Headings by action: save -> `🔖 **Saved snippet:**`; recall -> `🔁 **Recalled:**`; list -> `🗂 **Snippets:**`; search -> `🔍 **Found:**`; delete -> `🧹 **Deleted:**`.

```
ᚱ clipboard › /clip-snippet v0.1.0
🔖 **Saved snippet:**
- 📌 **What:** saved the clipboard as `mit-header` (text/code).
- 📄 Recall any time with "paste the mit-header snippet".
```

```
ᚱ clipboard › /clip-snippet v0.1.0
🗂 **Snippets:** (3)
- `mit-header` text/code - `// SPDX-License-Identifier: MIT`
- `deploy-cmd` text/command - `kubectl rollout restart deploy/api`
- `company-logo` image - `[image]`

Say "paste the deploy-cmd snippet" to put one on the clipboard.
```

## Notes

- Curated + named, vs `/clip-history` which is automatic + chronological. Snippets never expire and have no count cap; they only change when you save/delete them.
- Text snippets are secret-scanned and REFUSED if they hold credentials. Image snippets store the PNG as-is.
- Recall is a side effect (it sets the clipboard). Windows backend verified; macOS/Linux needs verification, and setting an IMAGE clipboard there needs `wl-clipboard`/`xclip` (macOS `pbcopy` cannot - a stated non-claim).
