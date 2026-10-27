#!/usr/bin/env bash
# geocode: .sh port of geocode.ps1 (Nominatim, place <-> coordinates). Sends data to a third party; needs curl.
# Modes and output: ../contract/CONTRACTS.md 1.7, 2.7. At most 1 request/s.
set -u

LAT=""; LON=""; QUERY=""; BASE="https://nominatim.openstreetmap.org"
while [ $# -gt 0 ]; do
  case "$1" in
    --lat) LAT="$2"; shift 2;;
    --lon) LON="$2"; shift 2;;
    --query) QUERY="$2"; shift 2;;
    --base-url) BASE="$2"; shift 2;;
    *) shift;;
  esac
done
command -v curl >/dev/null 2>&1 || { echo "GEOCODE_NONE=1"; echo "GEOCODE_ERROR=curl not found"; exit 1; }
UA='subms-runes-imageverse/0.1 (image organiser)'

hav() { awk -v la1="$1" -v lo1="$2" -v la2="$3" -v lo2="$4" 'BEGIN{
  d=3.141592653589793/180; dla=(la2-la1)*d; dlo=(lo2-lo1)*d;
  a=sin(dla/2)*sin(dla/2)+cos(la1*d)*cos(la2*d)*sin(dlo/2)*sin(dlo/2);
  printf "%.1f", 6371.0*2*atan2(sqrt(a),sqrt(1-a)) }'; }

if [ -n "$QUERY" ]; then
  # curl -G moves --data-urlencode into the query string, encoding the place name.
  json="$(curl -s -A "$UA" -G "$BASE/search" --data-urlencode "q=$QUERY" -d 'format=jsonv2' -d 'limit=1' 2>/dev/null)"
  [ -n "$json" ] || { echo "GEOCODE_NONE=1"; exit 0; }
  clat="$(printf '%s' "$json" | grep -oE '"lat":"[^"]*"' | head -1 | sed 's/.*:"//;s/"$//')"
  clon="$(printf '%s' "$json" | grep -oE '"lon":"[^"]*"' | head -1 | sed 's/.*:"//;s/"$//')"
  [ -n "$clat" ] && [ -n "$clon" ] || { echo "GEOCODE_NONE=1"; exit 0; }
  # boundingbox: ["south","north","west","east"]
  bb="$(printf '%s' "$json" | grep -oE '"boundingbox":\[[^]]*\]' | head -1)"
  set -- $(printf '%s' "$bb" | grep -oE '\-?[0-9]+\.[0-9]+')
  south="${1:-}"; north="${2:-}"; west="${3:-}"; east="${4:-}"
  echo "GEOCODE_LATLON=$clat,$clon"
  if [ -n "$south" ] && [ -n "$north" ] && [ -n "$west" ] && [ -n "$east" ]; then
    echo "GEOCODE_BBOX=$south,$west,$north,$east"
    echo "GEOCODE_RADIUS_KM=$(hav "$clat" "$clon" "$north" "$east")"
  fi
  exit 0
fi

[ -n "$LAT" ] && [ -n "$LON" ] || { echo "GEOCODE_NONE=1"; echo "GEOCODE_ERROR=give --query <place> (forward) or --lat/--lon (reverse)"; exit 1; }
json="$(curl -s -A "$UA" "$BASE/reverse?lat=$LAT&lon=$LON&format=jsonv2&zoom=12&addressdetails=1" 2>/dev/null)"
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
