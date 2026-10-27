#!/usr/bin/env bash
# settings: .sh port of settings.ps1; home and defaults live in settings.conf (no jq), read only through get/show.
# settings.sh [show] | get | home --lat --lon [--town] [--radius-km] | person add|list|remove|rename | object add|list|remove | default --key --value
set -uo pipefail

cmd="${1:-show}"; sub=""
case "$cmd" in person|object) sub="${2:-list}"; shift 2 || shift $# ;; *) shift || true ;; esac

name=""; label=""; to=""; images=""; lat=""; lon=""; town=""; radius=""; key=""; value=""; plugin="imageverse"
while [ $# -gt 0 ]; do
  case "$1" in
    --name) name="${2:-}"; shift 2;; --label) label="${2:-}"; shift 2;; --to) to="${2:-}"; shift 2;;
    --images) images="${2:-}"; shift 2;; --lat) lat="${2:-}"; shift 2;; --lon) lon="${2:-}"; shift 2;;
    --town) town="${2:-}"; shift 2;; --radius-km) radius="${2:-}"; shift 2;;
    --key) key="${2:-}"; shift 2;; --value) value="${2:-}"; shift 2;; --plugin) plugin="${2:-}"; shift 2;;
    *) shift;;
  esac
done

base="${LOCALAPPDATA:-${XDG_DATA_HOME:-$HOME/.local/share}}"
root="$base/runes/$plugin/settings"
people="$root/people"; objects="$root/objects"; conf="$root/settings.conf"
mkdir -p "$people" "$objects"
img_re='\.(jpg|jpeg|png|heic|heif|gif|bmp|tif|tiff|webp)$'

conf_get() { [ -f "$conf" ] && sed -n "s/^$1=//p" "$conf" | tail -n1; }
conf_set() { # key value
  mkdir -p "$root"; touch "$conf"
  local tmp; tmp="$(mktemp)"; grep -v "^$1=" "$conf" > "$tmp" 2>/dev/null || true
  printf '%s=%s\n' "$1" "$2" >> "$tmp"; mv -f "$tmp" "$conf"
}
sha() { ( command -v shasum >/dev/null 2>&1 && shasum -a1 "$1" || sha1sum "$1" ) 2>/dev/null | awk '{print $1}'; }
count_refs() { find "$1" -maxdepth 1 -type f 2>/dev/null | grep -ciE "$img_re"; }

add_refs() { # destdir imagescsv
  local dest="$1" csv="$2" added=0
  mkdir -p "$dest"
  declare -A seen
  while IFS= read -r f; do [ -n "$f" ] && seen["$(sha "$f")"]=1; done < <(find "$dest" -maxdepth 1 -type f 2>/dev/null)
  local IFS=','
  for raw in $csv; do
    raw="$(printf '%s' "$raw" | sed 's/^ *//;s/ *$//')"; [ -n "$raw" ] || continue
    for m in $raw; do
      [ -f "$m" ] || continue
      printf '%s' "$m" | grep -qiE "$img_re" || { echo "SETTINGS_SKIP=not an image: $m"; continue; }
      local h; h="$(sha "$m")"; [ -n "${seen[$h]:-}" ] && continue
      seen[$h]=1
      local ext; ext=".$(printf '%s' "${m##*.}" | tr '[:upper:]' '[:lower:]')"
      cp "$m" "$dest/${h:0:12}$ext"; added=$((added+1))
    done
  done
  echo "$added"
}

case "$cmd" in
  home)
    [ -n "$lat" ] && conf_set home.lat "$lat"
    [ -n "$lon" ] && conf_set home.lon "$lon"
    [ -n "$town" ] && conf_set home.town "$town"
    [ -n "$radius" ] && conf_set home.radiusKm "$radius"
    [ -n "$(conf_get home.radiusKm)" ] || conf_set home.radiusKm 25
    echo "SETTINGS_HOME=lat=$(conf_get home.lat) lon=$(conf_get home.lon) town=$(conf_get home.town) radiusKm=$(conf_get home.radiusKm)"
    ;;
  default)
    [ -n "$key" ] || { echo "SETTINGS_ERROR=default needs --key"; exit 1; }
    conf_set "default.$key" "$value"; echo "SETTINGS_DEFAULT=$key=$value" ;;
  person)
    case "$sub" in
      add) { [ -n "$name" ] && [ -n "$images" ]; } || { echo "SETTINGS_ERROR=person add needs --name and --images"; exit 1; }
           n="$(add_refs "$people/$name" "$images")"; [ -f "$people/$name/meta.json" ] || echo '{"aliases":[]}' > "$people/$name/meta.json"
           echo "SETTINGS_PERSON_ADD=$name added=$n total=$(count_refs "$people/$name")" ;;
      refs) # emit each ref image path for the recognition context: SETTINGS_REF<TAB>person<TAB>path
           if [ -n "$name" ]; then dirs="$people/$name/"; else dirs="$people"/*/; fi
           for d in $dirs; do [ -d "$d" ] || continue; nm="$(basename "$d")"
             find "$d" -maxdepth 1 -type f 2>/dev/null | grep -iE '\.(jpg|jpeg|png|heic|heif|gif|bmp|tif|tiff|webp)$' \
               | while IFS= read -r f; do printf 'SETTINGS_REF\t%s\t%s\n' "$nm" "$f"; done
           done ;;
      remove) [ -n "$name" ] && { rm -rf "$people/$name"; echo "SETTINGS_PERSON_REMOVE=$name"; } ;;
      rename) { [ -n "$name" ] && [ -n "$to" ]; } && { mv "$people/$name" "$people/$to"; echo "SETTINGS_PERSON_RENAME=$name->$to"; } ;;
      *) for d in "$people"/*/; do [ -d "$d" ] || continue; nm="$(basename "$d")"; printf 'SETTINGS_PERSON\t%s\t%s\t%s\n' "$nm" "$d" "$(count_refs "$d")"; done ;;
    esac ;;
  object)
    case "$sub" in
      add) { [ -n "$label" ] && [ -n "$images" ]; } || { echo "SETTINGS_ERROR=object add needs --label and --images"; exit 1; }
           n="$(add_refs "$objects/$label" "$images")"; echo "SETTINGS_OBJECT_ADD=$label added=$n total=$(count_refs "$objects/$label")" ;;
      remove) [ -n "$label" ] && { rm -rf "$objects/$label"; echo "SETTINGS_OBJECT_REMOVE=$label"; } ;;
      *) for d in "$objects"/*/; do [ -d "$d" ] || continue; nm="$(basename "$d")"; printf 'SETTINGS_OBJECT\t%s\t%s\t%s\n' "$nm" "$d" "$(count_refs "$d")"; done ;;
    esac ;;
  get)
    echo "SETTINGS_ROOT=$root"
    [ -n "$(conf_get home.lat)" ] && { echo "SETTINGS_HOME_LAT=$(conf_get home.lat)"; echo "SETTINGS_HOME_LON=$(conf_get home.lon)"; echo "SETTINGS_HOME_TOWN=$(conf_get home.town)"; echo "SETTINGS_HOME_RADIUS_KM=$(conf_get home.radiusKm)"; }
    for d in "$people"/*/; do [ -d "$d" ] || continue; printf 'SETTINGS_PERSON\t%s\t%s\t%s\n' "$(basename "$d")" "$d" "$(count_refs "$d")"; done
    for d in "$objects"/*/; do [ -d "$d" ] || continue; printf 'SETTINGS_OBJECT\t%s\t%s\t%s\n' "$(basename "$d")" "$d" "$(count_refs "$d")"; done
    [ -f "$conf" ] && sed -n 's/^default\.\([^=]*\)=\(.*\)$/SETTINGS_DEFAULT\t\1\t\2/p' "$conf" ;;
  *)
    echo "SETTINGS_ROOT=$root"
    if [ -n "$(conf_get home.lat)" ]; then echo "SETTINGS_HOME=$(conf_get home.town) ($(conf_get home.lat),$(conf_get home.lon)) radius $(conf_get home.radiusKm)km"; else echo "SETTINGS_HOME=(not set - run: settings home --lat <d> --lon <d> --town <name>)"; fi
    pc=0; for d in "$people"/*/; do [ -d "$d" ] && pc=$((pc+1)); done; echo "SETTINGS_PEOPLE=$pc"
    for d in "$people"/*/; do [ -d "$d" ] || continue; printf '  person\t%s\t%s ref(s)\n' "$(basename "$d")" "$(count_refs "$d")"; done
    oc=0; for d in "$objects"/*/; do [ -d "$d" ] && oc=$((oc+1)); done; echo "SETTINGS_OBJECTS=$oc"
    for d in "$objects"/*/; do [ -d "$d" ] || continue; printf '  object\t%s\t%s ref(s)\n' "$(basename "$d")" "$(count_refs "$d")"; done
    [ -f "$conf" ] && sed -n 's/^default\.\([^=]*\)=\(.*\)$/  default\t\1=\2/p' "$conf" ;;
esac
