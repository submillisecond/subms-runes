#!/usr/bin/env bash
# deps - preflight the external image tools the imageverse .sh backend needs, and
# report any MISSING ones with the suggested install command for THIS platform + the
# feature that degrades. Skills run this before image work and surface misses to the
# user. (deps.ps1 is the Windows backend; on Windows thumbnails/tiling use
# System.Drawing, so only ffmpeg is external there.)
set -uo pipefail
have(){ command -v "$1" >/dev/null 2>&1; }

im=""; have magick && im=magick; { [ -z "$im" ] && have convert; } && im=convert
mont=0; { have magick || have montage; } && mont=1
ff=0; have ffmpeg && ff=1
fp=0; have ffprobe && fp=1

echo "DEP	ImageMagick	$([ -n "$im" ] && echo ok || echo missing)	image resize + crop (thumbnails/montage)"
echo "DEP	montage	$([ "$mont" = 1 ] && echo ok || echo missing)	contact-sheet / montage tiling"
echo "DEP	ffmpeg	$([ "$ff" = 1 ] && echo ok || echo missing)	video contact-sheet frames"
echo "DEP	ffprobe	$([ "$fp" = 1 ] && echo ok || echo missing)	video duration for even sampling"

# pick the install command for this platform
if   have apt-get; then fix="sudo apt-get install -y imagemagick ffmpeg"
elif have brew;    then fix="brew install imagemagick ffmpeg"
elif have dnf;     then fix="sudo dnf install -y ImageMagick ffmpeg"
elif have pacman;  then fix="sudo pacman -S --noconfirm imagemagick ffmpeg"
elif have zypper;  then fix="sudo zypper install -y ImageMagick ffmpeg"
else fix="install ImageMagick + ffmpeg via your package manager"; fi

miss=""
[ -n "$im" ] || miss="$miss imagemagick"
[ "$mont" = 1 ] || miss="$miss montage"
[ "$ff" = 1 ] || miss="$miss ffmpeg"
miss="$(echo $miss | xargs)"
if [ -n "$miss" ]; then
  echo "DEPS_MISSING=$miss"
  echo "DEPS_FIX=$fix"
  [ -n "$im" ] && [ "$mont" = 1 ] || echo "DEPS_DEGRADED=montage/contact-sheet tiling unavailable until ImageMagick is installed"
  [ "$ff" = 1 ] || echo "DEPS_DEGRADED=videos can't be content-thumbnailed (fall back to time/geo-cluster grouping)"
else
  echo "DEPS_OK=all image tools present"
fi
