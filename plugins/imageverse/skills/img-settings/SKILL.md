---
name: img-settings
description: This skill should be used when the user asks to "/img-settings", "recognise this person as <Name>" (with attached/clipboard/path images), "remember our dog/pet/object", "set my home location/town", "what are my image settings", "list the people I've registered", "forget <Name>", or otherwise wants to VIEW or CHANGE the persistent imageverse settings (home location, known people, known objects, defaults) that the other imageverse skills (img-organize, img-search, img) use.
version: 0.2.0
---

# img-settings - the one place to manage imageverse settings

A single skill to maintain every persistent setting the imageverse plugin uses, so
the other runes get smarter without re-asking each run. It stores:

- **HOME** location (lat/lon + town + radius km). Any GPS cluster farther than the
  radius from home is treated as a **TRIP**; nearer is everyday. This replaces the
  "densest GPS = home" guess in `/img-organize`.
- **PEOPLE** - named **reference images** ("recognise this person as Alicia"). The
  vision pass in organize/search is shown these refs so it can recognise that person
  in your photos (e.g. an `Alicia` album, or "find photos of Alicia").
- **OBJECTS / PETS** - named reference images, same idea ("this is our dog Rex").
- **DEFAULTS** - free key/value (e.g. the default organize scheme).

Recognition is **reference-images-as-CONTEXT**: the store keeps labelled example
images; the rune's existing vision read uses them to identify people/objects. There
is NO separate ML model or dependency - the same vision pass that classifies photos
does the recognising, now with your labelled examples in front of it.

Durable, per-plugin store (OUTSIDE temp), shared by all imageverse skills:
`%LOCALAPPDATA%\runes\imageverse\settings\` (`settings.json` (ps1) / `settings.conf`
(sh) for home+defaults; `people\<Name>\` and `objects\<Label>\` hold the copied
reference images). Originals are never modified - references are COPIED in and
deduped by content hash.

Script: `${CLAUDE_PLUGIN_ROOT}/scripts/settings.ps1` (Windows `powershell.exe ...
-File`) / `settings.sh` (macOS/Linux `bash`). The rune's only job is to turn the
request into the right `settings` sub-command - do NOT hand-roll the store.

## How to handle each request

- **Show / list** ("what are my settings", "who have I registered"): `settings show`
  (human dump) or `settings get` (machine lines other skills parse). Report HOME,
  the PEOPLE (with ref counts), OBJECTS, and DEFAULTS.

- **Register a person** ("recognise this person as Alicia", "this is Evelina"):
  obtain the reference image FILE PATH(S), then
  `settings person add -Name Alicia -Images "<path1>,<path2>"` (`.sh`:
  `person add --name Alicia --images "..."`). Get the image paths from, in order:
  1. an explicit path / folder / glob in the args (e.g. `... as Alicia C:\pics\a.jpg`);
  2. an image ATTACHED/pasted in this chat - save it to a file first (use the
     clipboard plugin `clip-save`, or the attachment's temp path) and pass that path;
  3. existing library photos the user points at ("use those Disneyland selfies").
  Confirm the name + how many refs were added (`SETTINGS_PERSON_ADD=...`). More refs
  per person (varied angles/lighting) = better recognition; you can add more later.
  CANDIDATE-APPROVAL flow (when the user has no ready ref but a likely album exists,
  e.g. "register Alicia from her birthday album"): `/img-montage` that album, show it,
  let the user point at the cells that are clearly that person, then `person add` those
  source paths (resolve cell->path via the montage's `list.txt`). Never auto-register a
  face without the user confirming it's them.
- **List a person's refs** for downstream recognition: `settings person refs [-Name X]`
  (`.sh`: `person refs [--name X]`) emits `SETTINGS_REF<TAB>person<TAB>path` - this is
  what `/img-organize` and `/img-search` thumbnail to build the recognition context.

- **Register an object / pet** ("remember our dog Rex"): same flow with
  `settings object add -Label Rex -Images "..."` (`.sh`: `object add --label ...`).

- **Set home** ("home is Greenhithe", "I live in <town>"): you need lat/lon. If the
  user gives a town only, resolve it to coordinates FIRST with the `geocode` script
  (NETWORK - confirm with the user before the lookup; forward-geocode the town), or
  derive coords from a sample home photo's GPS. Then
  `settings home -Lat <d> -Lon <d> -Town "<name>" -RadiusKm <n>` (default radius 25).
  `.sh`: `home --lat --lon --town --radius-km`.

- **Remove / rename**: `settings person remove -Name X` / `person rename -Name X -To Y`;
  `settings object remove -Label X`. Confirm before removing.

- **Default**: `settings default -Key scheme -Value trip`.

## How the OTHER skills consume this (for reference)

At the start of an organize/search run, the rune calls `settings get` and uses:
- **HOME_LAT/LON/RADIUS_KM** - for each GPS cluster, distance from home > radius =>
  route as a TRIP album; <= radius => everyday. (Overrides the densest-GPS guess.)
- **PERSON / OBJECT** lines (name + ref dir) - read a few reference thumbnails so the
  vision pass can recognise and name those people/objects in the photos (per-person
  albums, or person filters in search).

## Reply format

Shared rune reply shape. Cast banner first on its own line:
`ᚱ imageverse › /img-settings v0.1.0`, then the store path line in backticks, then a
section heading, then bullets. Full-width emoji + one space (vetted set: `📷 📁 📦
📊 📝 📌 🔖 🔍 🚩 🏠 👤`). First bullet is `📌 **What:**`. Use `🏠` for home, `👤`
for people, `🔖` for objects. NO blank line between heading and first bullet.

```
ᚱ imageverse › /img-settings v0.1.0
📁 `%LOCALAPPDATA%\runes\imageverse\settings`
📝 **Settings:**
- 📌 **What:** registered Alicia (2 reference images) and set home.
- 🏠 **Home:** Greenhithe (51.43, 0.10), trip radius 25 km.
- 👤 **People:** Alicia (2), Evelina (3).
- 🔖 **Objects:** Rex the dog (1).
```

## Notes

- Reference images are COPIED into the store and deduped by content hash; adding the
  same image twice is a no-op (`added=0`).
- No ML dependency - recognition is the vision pass using your labelled refs.
- Settings are global to the plugin (all folders), unlike `prefs` which remembers the
  per-FOLDER organize scheme. Both are surfaced by `/img-organize`.
