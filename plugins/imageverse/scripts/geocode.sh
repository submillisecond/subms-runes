#!/usr/bin/env bash
# geocode - reverse-geocode ONE coordinate to a place name via OpenStreetMap
# Nominatim (macOS/Linux backend; see geocode.ps1). NETWORK + PRIVACY: sends the
# lat/lon to a third-party API. img-organize calls this ONLY on cluster centroids
# and ONLY after the user confirms in that run.
#   --lat <deg> --lon <deg> [--base-url URL]
# Prints GEOCODE_PLACE=<place>, <country> or GEOCODE_NONE. Nominatim policy:
# <=1 req/s + a real User-Agent. Needs curl.
set -u

LAT=""; LON=""; BASE="https://nominatim.openstreetmap.org"
while [ $# -gt 0 ]; do
  case "$1" in
    --lat) LAT="$2"; shift 2;;
    --lon) LON="$2"; shift 2;;
    --base-url) BASE="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$LAT" ] && [ -n "$LON" ] || { echo "GEOCODE_NONE=1"; echo "GEOCODE_ERROR=missing --lat/--lon"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "GEOCODE_NONE=1"; echo "GEOCODE_ERROR=curl not found"; exit 1; }

json="$(curl -s -A 'subms-runes-imageverse/0.1 (image organiser)' \
  "$BASE/reverse?lat=$LAT&lon=$LON&format=jsonv2&zoom=12&addressdetails=1" 2>/dev/null)"
[ -n "$json" ] || { echo "GEOCODE_NONE=1"; exit 0; }

extract() { printf '%s' "$json" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }
place="$(extract city)"; [ -z "$place" ] && place="$(extract town)"; [ -z "$place" ] && place="$(extract village)"
[ -z "$place" ] && place="$(extract county)"; [ -z "$place" ] && place="$(extract state)"
country="$(extract country)"
if [ -n "$place" ] && [ -n "$country" ]; then echo "GEOCODE_PLACE=$place, $country"
else
  dn="$(extract display_name)"
  if [ -n "$dn" ]; then echo "GEOCODE_PLACE=$(printf '%s' "$dn" | cut -d, -f1-2)"; else echo "GEOCODE_NONE=1"; fi
fi
