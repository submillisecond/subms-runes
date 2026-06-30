#!/usr/bin/env bash
# phash - perceptual hashing (dHash) for imageverse (macOS/Linux backend; phash.ps1
# is the verified Windows backend). SHA1 can't see through a WhatsApp re-encode; a
# perceptual hash can - so this routes re-shares to an existing album and groups
# within-dump near-dupes. dHash: 9x8 grayscale -> compare adjacent pixels -> 64-bit
# (16 hex); similarity = Hamming distance. Needs ImageMagick (magick/convert).
# VIDEOS: hashed as a frame-signature (N frames sampled -> dHash each -> concatenated,
# --video-frames N, default 4); needs ffmpeg. Video sigs are a different length from
# image hashes so the two never cross-match; match/group scale the threshold for them.
#   hash  --list F | --tsv scan.tsv  [--out F]      -> "<dhash>\t<path>" lines
#   match --query H.tsv --ref H.tsv  [--max-dist 10]-> MATCH/NOMATCH lines
#   group --in H.tsv [--max-dist 6]                 -> GROUP\t<id>\t<n>\t<paths,>
set -uo pipefail

mode="${1:-hash}"; shift || true
list=""; tsv=""; out=""; query=""; ref=""; infile=""; maxdist=""; vframes=4
while [ $# -gt 0 ]; do
  case "$1" in
    --list) list="${2:-}"; shift 2;; --tsv) tsv="${2:-}"; shift 2;; --out) out="${2:-}"; shift 2;;
    --query) query="${2:-}"; shift 2;; --ref) ref="${2:-}"; shift 2;; --in) infile="${2:-}"; shift 2;;
    --max-dist) maxdist="${2:-}"; shift 2;; --video-frames) vframes="${2:-4}"; shift 2;; *) shift;;
  esac
done
MAGICK="$(command -v magick || command -v convert || true)"
FFMPEG="$(command -v ffmpeg || true)"; FFPROBE="$(command -v ffprobe || true)"
is_vid() { case "$(printf '%s' "${1##*.}" | tr 'A-Z' 'a-z')" in mp4|mov|m4v|avi|mkv|webm|3gp|3g2|wmv|mpg|mpeg|mts|m2ts) return 0;; *) return 1;; esac; }

dhash() { # file -> 16 hex (empty on failure)
  [ -n "$MAGICK" ] || return
  "$MAGICK" "$1" -resize '9x8!' -colorspace Gray -depth 8 gray:- 2>/dev/null | od -An -v -tu1 | tr -s ' \t' '\n' | grep -v '^$' | awk '
    { a[NR-1]=$1 }
    END{ if (NR<72) exit; hex="0123456789abcdef"; out=""; val=0; cnt=0;
      for(y=0;y<8;y++) for(x=0;x<8;x++){ bit=(a[y*9+x]<a[y*9+x+1])?1:0; val=val*2+bit; cnt++;
        if(cnt==4){ out=out substr(hex,val+1,1); val=0; cnt=0 } } print out }'
}
video_sig() { # file frames -> frames*16 hex (empty if nothing decoded). dHash of N
  # frames sampled evenly across the clip, concatenated - robust to re-encode; a
  # different length from an image hash so the two never cross-match. Needs ffmpeg.
  [ -n "$FFMPEG" ] || return
  local f="$1" n="${2:-4}" td dur="" sig="" k=0 t fo fh
  td="$(mktemp -d)"
  [ -n "$FFPROBE" ] && dur="$("$FFPROBE" -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)"
  while [ "$k" -lt "$n" ]; do
    fo="$td/f$k.png"
    if printf '%s' "$dur" | grep -qE '^[0-9.]+$'; then
      t="$(awk -v d="$dur" -v k="$k" -v n="$n" 'BEGIN{printf "%.3f", d*(k+0.5)/n}')"
      "$FFMPEG" -nostdin -loglevel error -y -ss "$t" -i "$f" -frames:v 1 -q:v 3 "$fo" 2>/dev/null
    else
      "$FFMPEG" -nostdin -loglevel error -y -i "$f" -vf "select=eq(n\,$((k*15)))" -frames:v 1 "$fo" 2>/dev/null
    fi
    fh=""; [ -f "$fo" ] && fh="$(dhash "$fo")"
    if [ -n "$fh" ]; then sig="$sig$fh"; else sig="${sig}0000000000000000"; fi
    k=$((k+1))
  done
  rm -rf "$td"
  case "$sig" in *[1-9a-f]*) printf '%s' "$sig";; esac   # empty if all-zero (no frames)
}

case "$mode" in
  hash)
    paths=""
    if [ -n "$list" ] && [ -f "$list" ]; then paths="$(grep . "$list")"
    elif [ -n "$tsv" ] && [ -f "$tsv" ]; then paths="$(awk -F'\t' '{print $4}' "$tsv" | grep .)"
    else echo "PHASH_ERROR=hash needs --list or --tsv"; exit 1; fi
    [ -n "$MAGICK" ] || { echo "PHASH_ERROR=need ImageMagick"; exit 1; }
    tmp="$(mktemp)"; ok=0; vid=0; vskip=0
    while IFS= read -r p; do
      [ -f "$p" ] || continue
      if is_vid "$p"; then
        [ -n "$FFMPEG" ] || { vskip=$((vskip+1)); continue; }
        h="$(video_sig "$p" "$vframes")"; [ -n "$h" ] && vid=$((vid+1))
      else h="$(dhash "$p")"; fi
      [ -n "$h" ] && { printf '%s\t%s\n' "$h" "$p" >> "$tmp"; ok=$((ok+1)); }
    done <<< "$paths"
    echo "PHASH_COUNT=$ok"
    [ "$vid" -gt 0 ] && echo "PHASH_VIDEOS=$vid (frame-signature, $vframes frames)"
    [ "$vskip" -gt 0 ] && echo "PHASH_NOTE=$vskip video(s) skipped - ffmpeg not found (run deps)"
    [ -n "$out" ] && { cp "$tmp" "$out"; echo "PHASH_OUTFILE=$out"; }
    cat "$tmp"; rm -f "$tmp" ;;
  match)
    { [ -n "$query" ] && [ -n "$ref" ]; } || { echo "PHASH_ERROR=match needs --query and --ref"; exit 1; }
    md="${maxdist:-10}"
    awk -F'\t' -v md="$md" '
      function ham(a,b,  i,d,x,n){ if(length(a)!=length(b)) return -1; n="0112122312232334"; d=0;
        for(i=1;i<=length(a);i++){ x=xor(strtonum("0x" substr(a,i,1)), strtonum("0x" substr(b,i,1))); d+=substr(n,x+1,1) } return d }
      FNR==NR{ rh[FNR]=$1; rp[FNR]=$2; nr=FNR; next }
      { best=999; bp=""; s=int(length($1)/16); if(s<1)s=1; eff=md*s;
        for(i=1;i<=nr;i++){ d=ham($1,rh[i]); if(d<0)continue; if(d<best){best=d; bp=rp[i]; if(d==0)break} }
        if(bp!="" && best<=eff){ printf "MATCH\t%s\t%s\t%d\n",$2,bp,best; m++ } else printf "NOMATCH\t%s\n",$2
      }
      END{ printf "PHASH_MATCHED=%d of %d; MaxDist=%d\n", m, FNR, md > "/dev/stderr" }
    ' "$ref" "$query" ;;
  group)
    md="${maxdist:-6}"
    awk -F'\t' -v md="$md" '
      function ham(a,b,  i,d,x,n){ if(length(a)!=length(b)) return -1; n="0112122312232334"; d=0;
        for(i=1;i<=length(a);i++){ x=xor(strtonum("0x" substr(a,i,1)), strtonum("0x" substr(b,i,1))); d+=substr(n,x+1,1) } return d }
      { placed=0; s=int(length($1)/16); if(s<1)s=1; eff=md*s;
        for(g=1;g<=ng;g++){ d=ham($1,grep[g]); if(d>=0 && d<=eff){ gm[g]=gm[g] "," $2; gc[g]++; placed=1; break } }
        if(!placed){ ng++; grep[ng]=$1; gm[ng]=$2; gc[ng]=1 }
      }
      END{ dup=0; for(g=1;g<=ng;g++) if(gc[g]>1) dup++;
        printf "PHASH_GROUPS=%d; dup-groups=%d; items=%d\n", ng, dup, NR;
        for(g=1;g<=ng;g++) printf "GROUP\t%d\t%d\t%s\n", g, gc[g], gm[g] }
    ' "$infile" ;;
  *) echo "PHASH_ERROR=unknown mode '$mode' (hash|match|group)" ;;
esac
