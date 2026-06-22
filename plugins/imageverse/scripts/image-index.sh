#!/usr/bin/env bash
# image-index - the content-search cache for the imageverse pack (macOS/Linux
# backend; Windows backend is image-index.ps1). A GLOBAL, content-addressed
# (sha1-keyed) store of structured per-image records, so an image is vision-
# captioned ONCE and later search/organise reads text not pixels. Path-
# independent: moves/renames/copies reuse the caption; a deleted file just drops
# out of the live scan and can never be returned (presence is the scan's job).
#
# Store: ${XDG_DATA_HOME:-$HOME/.local/share}/runes/imageverse/index/
#   captions.tsv   one row per content hash (20-col schema, see COLS)
#   .schema        integer; bump invalidates every row (re-vision)
#
# Verbs (mirror image-index.ps1 exactly):
#   status [--tsv scan]            store dir, schema, count; with a live
#                                  image-find scan, also warm/cold coverage
#   plan   --tsv scan              cold delta: distinct hashes not yet captioned
#   put    --batch rows [--scan s] upsert caption rows after the vision pass
#   clear                          nuke the cache
#   query / prune                  land in step 2 (see SPEC.md)
#
# --tsv/--scan take an image-find TSV: date \t size \t sha1 \t path \t lat \t
# lon \t camera. Output is KEY=value lines then TSV rows, like the .ps1.
#
# dims + perceptual hash need ImageMagick (magick/convert); absent, they blank
# (graceful degrade, same as the .ps1 when an image fails to open). The phash
# VALUE differs from the .ps1 (different resampler) - intended: dHash is only
# compared within one machine; the sha1 that drives warm/cold is identical
# cross-platform. NOTE: the .ps1 is the verified backend.
set -uo pipefail

VERB="${1:-status}"; [ $# -gt 0 ] && shift
TSV=""; SCAN=""; BATCH=""; QUERY=""; GEO=""; NAME=""; MINBYTES=0; TAGANY=""; RECURSE=0; TOP=12
while [ $# -gt 0 ]; do
    case "$1" in
        --tsv) TSV="${2:-}"; shift 2 ;;
        --scan) SCAN="${2:-}"; shift 2 ;;
        --batch) BATCH="${2:-}"; shift 2 ;;
        --query) QUERY="${2:-}"; shift 2 ;;
        --geo) GEO="${2:-}"; shift 2 ;;
        --name) NAME="${2:-}"; shift 2 ;;
        --minbytes) MINBYTES="${2:-0}"; shift 2 ;;
        --tagany) TAGANY="${2:-}"; shift 2 ;;
        --days) DAYS="${2:-365}"; shift 2 ;;
        --neardup) NEARDUP=1; shift ;;
        --hammingmax) HMAX="${2:-6}"; shift 2 ;;
        --followers) FOLLOWERS="${2:-}"; shift 2 ;;
        --recurse) RECURSE=1; shift ;;
        --top) TOP="${2:-12}"; shift 2 ;;
        *) shift ;;
    esac
done
DAYS="${DAYS:-365}"; NEARDUP="${NEARDUP:-0}"; HMAX="${HMAX:-6}"; FOLLOWERS="${FOLLOWERS:-}"

BASE="${XDG_DATA_HOME:-$HOME/.local/share}/runes/imageverse/index"
CAPTIONS="$BASE/captions.tsv"
SCHEMA_FILE="$BASE/.schema"
TAB="$(printf '\t')"

# Column order is the on-disk contract (matches the .ps1 COLS).
#   hash iv phash last_seen seen_path w h lat lon camera place_path activity
#   category subcategory entities objects attributes text caption source

MAGICK="$(command -v magick || command -v convert || true)"

ensure_store() {
    if [ ! -d "$BASE" ]; then mkdir -p "$BASE"; chmod 700 "$BASE" 2>/dev/null || true; fi
    [ -f "$SCHEMA_FILE" ] || printf '1' > "$SCHEMA_FILE"
}
get_schema() { if [ -f "$SCHEMA_FILE" ]; then tr -dc '0-9' < "$SCHEMA_FILE"; else printf '1'; fi; }

# Flatten tab/newline (would corrupt the TSV) and trim; squeeze runs to one space.
san() { printf '%s' "${1:-}" | tr -s '\t\r\n' '   ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# Cached on-screen text can carry secrets (a screenshot of a .env). Redact before
# it lands in a durable file. Explicit case classes (no /i flag) keep it portable
# across GNU + BSD sed. Pattern order matches the .ps1 (api-key before kv-secret).
REDACT_TEXT=""; REDACT_N=0
redact() {
    local t="${1:-}" n=0 spec ty re cnt
    REDACT_TEXT=""; REDACT_N=0
    [ -n "$t" ] || return 0
    for spec in \
        'api-key|([Ss][Kk]|[Pp][Kk]|[Rr][Kk])-[A-Za-z0-9]{16,}' \
        'aws-key|AKIA[0-9A-Z]{16}' \
        'gh-token|gh[pousr]_[A-Za-z0-9]{20,}' \
        'bearer|[Bb][Ee][Aa][Rr][Ee][Rr][[:space:]]+[A-Za-z0-9._-]{20,}' \
        'private-key|-----BEGIN [A-Z ]*PRIVATE KEY-----' \
        'kv-secret|([Aa][Pp][Ii][_-]?[Kk][Ee][Yy]|[Ss][Ee][Cc][Rr][Ee][Tt]|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]|[Pp][Aa][Ss][Ss][Ww][Dd]|[Aa][Cc][Cc][Ee][Ss][Ss][_-]?[Tt][Oo][Kk][Ee][Nn]|[Tt][Oo][Kk][Ee][Nn])[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}'
    do
        ty="${spec%%|*}"; re="${spec#*|}"
        cnt="$(printf '%s' "$t" | grep -oE "$re" 2>/dev/null | grep -c . || true)"
        if [ "${cnt:-0}" -gt 0 ]; then n=$((n + cnt)); t="$(printf '%s' "$t" | sed -E "s/$re/[redacted:$ty]/g")"; fi
    done
    REDACT_TEXT="$t"; REDACT_N="$n"
}

# dims + dHash from one image open. 9x8 grayscale raw bytes -> 64-bit gradient
# hash (left>right), row-major, identical bit convention to the .ps1.
META_W=""; META_H=""; META_PHASH=""
image_meta() {
    META_W=""; META_H=""; META_PHASH=""
    local f="${1:-}"
    [ -n "$f" ] && [ -f "$f" ] || return 0
    [ -n "$MAGICK" ] || return 0
    local wh; wh="$("$MAGICK" "$f" -format '%w %h' info:- 2>/dev/null | head -n1)"
    META_W="${wh%% *}"; META_H="${wh##* }"
    local nums arr val bit y x a b
    nums="$("$MAGICK" "$f" -resize '9x8!' -colorspace Gray -depth 8 gray:- 2>/dev/null | od -An -v -tu1 | tr -s ' \t' '\n' | grep . || true)"
    arr=($nums)
    [ "${#arr[@]}" -eq 72 ] || return 0
    val=0; bit=0
    for ((y = 0; y < 8; y++)); do
        for ((x = 0; x < 8; x++)); do
            a="${arr[$((y * 9 + x))]}"; b="${arr[$((y * 9 + x + 1))]}"
            if [ "$a" -gt "$b" ]; then val=$((val | (1 << bit))); fi
            bit=$((bit + 1))
        done
    done
    META_PHASH="$(printf '%016x' "$val")"
}

# captions file to read for joins: the real file, or /dev/null when absent so
# the awk NR==FNR pass still works.
cap_src() { if [ -f "$CAPTIONS" ]; then printf '%s' "$CAPTIONS"; else printf '/dev/null'; fi; }

# Hamming distance between two 16-hex (64-bit) dHashes via per-nibble popcount -
# no 64-bit ints needed, so it is portable to any awk/bash. Missing -> 64.
hamming() {
    local a="$1" b="$2" i x d=0
    [ -n "$a" ] && [ -n "$b" ] || { echo 64; return; }
    for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        x=$(( 16#${a:$i:1} ^ 16#${b:$i:1} ))
        while [ "$x" -gt 0 ]; do d=$(( d + (x & 1) )); x=$(( x >> 1 )); done
    done
    echo "$d"
}

SCHEMA="$(get_schema)"; [ -n "$SCHEMA" ] || SCHEMA=1

case "$(printf '%s' "$VERB" | tr '[:upper:]' '[:lower:]')" in

    status)
        echo "INDEX_DIR=$BASE"
        echo "INDEX_SCHEMA=$SCHEMA"
        if [ -f "$CAPTIONS" ]; then
            cnt="$(awk -F'\t' -v s="$SCHEMA" 'NF>=2 && $2+0>=s{c++} END{print c+0}' "$CAPTIONS")"
        else cnt=0; fi
        echo "INDEX_CAPTIONS=$cnt"
        if [ -n "$TSV" ] && [ -f "$TSV" ]; then
            # Distinct content for BOTH warm and cold (matches the .ps1 status).
            # Key on FILENAME, not NR==FNR: an absent captions file is passed as
            # /dev/null (empty), and NR==FNR would then misread the scan as captions.
            CAP="$(cap_src)"
            awk -F'\t' -v s="$SCHEMA" -v capf="$CAP" '
                FILENAME==capf { if(NF>=2 && $2+0>=s) idx[$1]=1; next }
                { h=$3; if(h=="" || seen[h]++) next; if(h in idx) w++; else c++ }
                END { print "INDEX_WARM=" w+0; print "INDEX_COLD=" c+0 }
            ' "$CAP" "$TSV"
        fi
        ;;

    plan)
        if [ -z "$TSV" ] || [ ! -f "$TSV" ]; then echo "INDEX_ERROR=plan needs --tsv (an image-find scan)"; exit 1; fi
        CAP="$(cap_src)"
        # Distinct cold hashes only (caption once per content); shortest path rep.
        cold="$(awk -F'\t' -v s="$SCHEMA" -v capf="$CAP" '
            FILENAME==capf { if(NF>=2 && $2+0>=s) idx[$1]=1; next }
            { h=$3; p=$4; if(h=="" || (h in idx)) next; if(!(h in best) || length(p)<length(best[h])) best[h]=p }
            END { for(h in best) print h "\t" best[h] }
        ' "$CAP" "$TSV")"
        ncold="$(printf '%s' "$cold" | grep -c . || true)"
        # Warm = per-instance scan rows whose hash is cached (matches the .ps1 plan).
        warm="$(awk -F'\t' -v s="$SCHEMA" -v capf="$CAP" '
            FILENAME==capf { if(NF>=2 && $2+0>=s) idx[$1]=1; next }
            { if($3!="" && ($3 in idx)) w++ } END { print w+0 }
        ' "$CAP" "$TSV")"
        if [ "$NEARDUP" != 1 ]; then
            echo "INDEX_COLD=$ncold"
            [ -n "$cold" ] && printf '%s\n' "$cold" | while IFS= read -r l; do [ -n "$l" ] && printf 'INDEX_COLD\t%s\n' "$l"; done
            echo "INDEX_WARM=$warm"
        else
            # Near-dup collapse (mirrors the .ps1): a cold image within HMAX of an
            # already-captioned image OR an earlier cold rep is a FOLLOWER (inherits
            # the rep's coarse caption via put --followers, never vision-read). Opens
            # each cold file for its phash (local, zero tokens).
            anchors="$(mktemp)"   # "hash<TAB>phash" lines: warm rows first
            [ -f "$CAPTIONS" ] && awk -F'\t' -v s="$SCHEMA" 'NF>=20 && $2+0>=s && $3!=""{print $1"\t"$3}' "$CAPTIONS" > "$anchors"
            reps="$(mktemp)"; fols="$(mktemp)"
            # Stable order (sort by hash) so grouping is deterministic.
            printf '%s\n' "$cold" | grep . | sort | while IFS= read -r row; do
                h="$(printf '%s' "$row" | cut -f1)"; p="$(printf '%s' "$row" | cut -f2-)"
                image_meta "$p"; ph="$META_PHASH"
                rep=""
                if [ -n "$ph" ]; then
                    while IFS="$TAB" read -r ah aph; do
                        [ -n "$ah" ] || continue
                        if [ "$(hamming "$ph" "$aph")" -le "$HMAX" ]; then rep="$ah"; break; fi
                    done < "$anchors"
                fi
                if [ -n "$rep" ]; then printf '%s\t%s\t%s\n' "$h" "$p" "$rep" >> "$fols"
                else printf '%s\t%s\n' "$h" "$p" >> "$reps"; printf '%s\t%s\n' "$h" "$ph" >> "$anchors"; fi
            done
            echo "INDEX_COLD=$(grep -c . "$reps" || true)"
            while IFS= read -r l; do [ -n "$l" ] && printf 'INDEX_COLD\t%s\n' "$l"; done < "$reps"
            echo "INDEX_NEARDUP=$(grep -c . "$fols" || true)"
            while IFS= read -r l; do [ -n "$l" ] && printf 'INDEX_NEARDUP\t%s\n' "$l"; done < "$fols"
            echo "INDEX_WARM=$warm"
            rm -f "$anchors" "$reps" "$fols"
        fi
        ;;

    put)
        if [ -z "$BATCH" ] || [ ! -f "$BATCH" ]; then echo "INDEX_ERROR=put needs --batch <rows tsv>"; exit 1; fi
        ensure_store
        SCHEMA="$(get_schema)"; [ -n "$SCHEMA" ] || SCHEMA=1
        now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        newrows="$(mktemp)"; : > "$newrows"
        put=0; redtot=0; propagated=0
        # Batch row: hash path category subcategory activity place_path entities
        # objects attributes caption text (inline). Parse with cut, NOT `IFS=tab
        # read`: tab is IFS-whitespace, so read folds the empty fields (e.g. a
        # blank activity) and shifts every column. cut keeps empty fields; -f11-
        # gives the text plus any stray tabs it contains.
        while IFS= read -r line || [ -n "$line" ]; do
            [ -n "$line" ] || continue
            bhash="$(printf '%s' "$line" | cut -f1)"
            [ -n "$bhash" ] || continue
            bpath="$(printf '%s' "$line" | cut -f2)"
            bcat="$(printf '%s' "$line" | cut -f3)"
            bsub="$(printf '%s' "$line" | cut -f4)"
            bact="$(printf '%s' "$line" | cut -f5)"
            bplace="$(printf '%s' "$line" | cut -f6)"
            bent="$(printf '%s' "$line" | cut -f7)"
            bobj="$(printf '%s' "$line" | cut -f8)"
            battr="$(printf '%s' "$line" | cut -f9)"
            bcap="$(printf '%s' "$line" | cut -f10)"
            btext="$(printf '%s' "$line" | cut -f11-)"
            raw="${btext:-}"
            redact "$raw"; redtot=$((redtot + REDACT_N))
            image_meta "${bpath:-}"
            lat=""; lon=""; cam=""
            if [ -n "$SCAN" ] && [ -f "$SCAN" ]; then
                ll="$(awk -F'\t' -v h="$bhash" '$3==h{print $5"\t"$6"\t"$7; exit}' "$SCAN")"
                lat="$(printf '%s' "$ll" | cut -f1)"; lon="$(printf '%s' "$ll" | cut -f2)"; cam="$(printf '%s' "$ll" | cut -f3)"
            fi
            txt="$(san "$REDACT_TEXT")"; txt="${txt:0:2000}"
            # 20 cols in schema order; last-write-wins dedup happens in the merge below.
            printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$bhash" "$SCHEMA" "$META_PHASH" "$now" "$(san "${bpath:-}")" "$META_W" "$META_H" "$lat" "$lon" "$cam" \
                "$(san "${bplace:-}")" "$(san "${bact:-}")" "$(san "${bcat:-}")" "$(san "${bsub:-}")" "$(san "${bent:-}")" \
                "$(san "${bobj:-}")" "$(san "${battr:-}")" "$txt" "$(san "${bcap:-}")" "model" >> "$newrows"
            put=$((put + 1))
        done < "$BATCH"
        unset line
        # Near-dup followers (plan --neardup): inherit the rep's COARSE fields
        # (place_path/activity/category/subcategory/objects + caption), NOT text,
        # source=propagated:<rep>. Row: follower-hash, follower-path, rep-hash.
        if [ -n "$FOLLOWERS" ] && [ -f "$FOLLOWERS" ]; then
            replook="$(mktemp)"; cat "$newrows" > "$replook"
            [ -f "$CAPTIONS" ] && awk -F'\t' -v s="$SCHEMA" 'NF>=20 && $2+0>=s' "$CAPTIONS" >> "$replook"
            while IFS= read -r frow; do
                [ -n "$frow" ] || continue
                fh="$(printf '%s' "$frow" | cut -f1)"; fp="$(printf '%s' "$frow" | cut -f2)"; rh="$(printf '%s' "$frow" | cut -f3)"
                [ -n "$fh" ] && [ -n "$rh" ] || continue
                rrow="$(awk -F'\t' -v h="$rh" '$1==h{r=$0} END{print r}' "$replook")"
                [ -n "$rrow" ] || continue   # rep must be captioned (this batch or cache)
                rplace="$(printf '%s' "$rrow" | cut -f11)"; ract="$(printf '%s' "$rrow" | cut -f12)"
                rcat="$(printf '%s' "$rrow" | cut -f13)"; rsub="$(printf '%s' "$rrow" | cut -f14)"
                robj="$(printf '%s' "$rrow" | cut -f16)"; rcap="$(printf '%s' "$rrow" | cut -f19)"
                image_meta "$fp"
                lat=""; lon=""; cam=""
                if [ -n "$SCAN" ] && [ -f "$SCAN" ]; then
                    ll="$(awk -F'\t' -v h="$fh" '$3==h{print $5"\t"$6"\t"$7; exit}' "$SCAN")"
                    lat="$(printf '%s' "$ll" | cut -f1)"; lon="$(printf '%s' "$ll" | cut -f2)"; cam="$(printf '%s' "$ll" | cut -f3)"
                fi
                printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
                    "$fh" "$SCHEMA" "$META_PHASH" "$now" "$(san "$fp")" "$META_W" "$META_H" "$lat" "$lon" "$cam" \
                    "$(san "$rplace")" "$(san "$ract")" "$(san "$rcat")" "$(san "$rsub")" "" \
                    "$(san "$robj")" "" "" "$(san "$rcap")" "propagated:$rh" >> "$newrows"
                propagated=$((propagated + 1))
            done < "$FOLLOWERS"
            rm -f "$replook"
        fi
        # Merge: keep existing rows at/above schema (stale dropped), then new rows;
        # awk keeps the LAST line per hash, so a re-put overwrites. Atomic swap.
        tmp="$(mktemp)"
        { [ -f "$CAPTIONS" ] && awk -F'\t' -v s="$SCHEMA" 'NF>=20 && $2+0>=s' "$CAPTIONS"; cat "$newrows"; } \
            | awk -F'\t' '{ row[$1]=$0 } END { for(h in row) print row[h] }' > "$tmp"
        # Cap the global cache: evict least-recently-seen (last_seen = col 4) over
        # the limit. Pure size bound, not presence-based.
        MAX="${RUNES_IMAGEVERSE_INDEX_MAX:-50000}"
        evicted=0
        n="$(grep -c . "$tmp" || true)"
        if [ "$n" -gt "$MAX" ]; then
            evicted=$((n - MAX))
            cap="$(mktemp)"; sort -t"$TAB" -k4,4r "$tmp" | head -n "$MAX" > "$cap"; mv -f "$cap" "$tmp"
        fi
        mv -f "$tmp" "$CAPTIONS"
        rm -f "$newrows"
        echo "INDEX_PUT=$put"
        [ "$propagated" -gt 0 ] && echo "INDEX_PROPAGATED=$propagated"
        [ "$redtot" -gt 0 ] && echo "INDEX_REDACTED=$redtot"
        [ "$evicted" -gt 0 ] && echo "INDEX_EVICTED=$evicted"
        ;;

    clear)
        rm -f "$CAPTIONS"
        echo "INDEX_CLEARED=1"
        ;;

    query)
        if [ -z "$TSV" ] || [ ! -f "$TSV" ]; then echo "INDEX_ERROR=query needs --tsv (an image-find scan)"; exit 1; fi
        CAP="$(cap_src)"
        # Whole engine in awk (it has log/sin/cos/atan2 + arrays): metadata prefilter
        # -> BM25-lite recall -> hash-grouped hits -> cold emission. Mirrors the .ps1.
        awk -F'\t' -v schema="$SCHEMA" -v capf="$CAP" -v query="$QUERY" -v geo="$GEO" -v name="$NAME" -v minb="$MINBYTES" -v tagany="$TAGANY" -v top="$TOP" '
        function hav(la1, lo1, la2, lo2,   d, dla, dlo, a) {
            d = 3.141592653589793 / 180; dla = (la2 - la1) * d; dlo = (lo2 - lo1) * d
            a = sin(dla / 2) * sin(dla / 2) + cos(la1 * d) * cos(la2 * d) * sin(dlo / 2) * sin(dlo / 2)
            return 6371.0 * 2 * atan2(sqrt(a), sqrt(1 - a))
        }
        function hastag(h,   i) { for (i = 1; i <= tn; i++) if (index(tagstr[h], " " tagarr[i] " ") > 0) return 1; return 0 }
        function after(i, j) { if (cscore[i] != cscore[j]) return cscore[i] < cscore[j]; return cdate[i] < cdate[j] }
        BEGIN {
            qn = 0
            if (query != "") { q = tolower(query); gsub(/[^a-z0-9]+/, " ", q); m = split(q, qa, " "); for (i = 1; i <= m; i++) if (qa[i] != "") { qn++; qterms[qn] = qa[i] } }
            gset = 0
            if (geo != "") { m = split(geo, ga, ","); if (m >= 3) { glat = ga[1] + 0; glon = ga[2] + 0; gkm = ga[3] + 0; gset = 1 } }
            name = tolower(name)
            tn = 0
            if (tagany != "") { tl = tolower(tagany); m = split(tl, ta, ","); for (i = 1; i <= m; i++) { gsub(/^[ \t]+|[ \t]+$/, "", ta[i]); if (ta[i] != "") { tn++; tagarr[tn] = ta[i] } } }
            k1 = 1.5; b = 0.75
        }
        FILENAME == capf {
            if (NF >= 20 && $2 + 0 >= schema) {
                h = $1; ix[h] = 1
                plc[h] = $11; act[h] = $12; cat[h] = $13; sub2[h] = $14; ent[h] = $15; obj[h] = $16; att[h] = $17; txt[h] = $18; cap[h] = $19
            }
            next
        }
        {
            h = $3; if (h == "") next
            p = $4
            if (name != "" && index(tolower(p), name) == 0) next
            if (minb > 0 && $2 + 0 < minb) next
            if (gset) { if ($5 == "" || $6 == "") next; if (hav(glat, glon, $5 + 0, $6 + 0) > gkm) next }
            surv[h] = 1; cnt[h]++
            if (paths[h] == "") paths[h] = p; else paths[h] = paths[h] SUBSEP p
            if (!(h in bd) || $1 > bd[h]) bd[h] = $1
            if (!(h in ix)) { if (!(h in coldrep) || length(p) < length(coldrep[h])) coldrep[h] = p }
        }
        END {
            for (h in surv) if (h in ix) { tg = tolower(cat[h] " " sub2[h] " " act[h] " " plc[h]); gsub(/[^a-z0-9]+/, " ", tg); tagstr[h] = " " tg " " }
            nc = 0
            if (qn > 0) {
                nw = 0; sumdl = 0
                for (h in surv) {
                    if (!(h in ix)) continue
                    if (tn > 0 && !hastag(h)) continue
                    nw++; W[nw] = h
                    doc = tolower(cat[h] " " sub2[h] " " act[h] " " plc[h] " " ent[h] " " obj[h] " " att[h] " " cap[h] " " txt[h])
                    gsub(/[^a-z0-9]+/, " ", doc)
                    dn = split(doc, dt, " "); cw = 0; split("", ind)
                    for (i = 1; i <= dn; i++) { w = dt[i]; if (w == "") continue; cw++; tf[h SUBSEP w]++; if (!(w in ind)) { ind[w] = 1; df[w]++ } }
                    dl[h] = cw; sumdl += cw
                }
                avgdl = (nw > 0 ? sumdl / nw : 0); if (avgdl < 1) avgdl = 1
                for (wi = 1; wi <= nw; wi++) {
                    h = W[wi]; s = 0
                    for (qi = 1; qi <= qn; qi++) {
                        t = qterms[qi]; f = tf[h SUBSEP t] + 0; if (f <= 0) continue
                        d = df[t] + 0
                        idf = log(1 + (nw - d + 0.5) / (d + 0.5))
                        denom = f + k1 * (1 - b + b * (dl[h] / avgdl))
                        s += idf * (f * (k1 + 1)) / denom
                        if (index(tagstr[h], " " t " ") > 0) s += idf
                    }
                    if (s > 0) { nc++; chash[nc] = h; cscore[nc] = s; cdate[nc] = bd[h] }
                }
            } else {
                for (h in surv) { if (tn > 0) { if (!(h in ix) || !hastag(h)) continue } nc++; chash[nc] = h; cscore[nc] = 0; cdate[nc] = bd[h] }
            }
            K = (nc < top ? nc : top)
            for (r = 1; r <= K; r++) {
                bi = r
                for (i = r + 1; i <= nc; i++) if (after(bi, i)) bi = i
                if (bi != r) { x = chash[r]; chash[r] = chash[bi]; chash[bi] = x; y = cscore[r]; cscore[r] = cscore[bi]; cscore[bi] = y; z = cdate[r]; cdate[r] = cdate[bi]; cdate[bi] = z }
            }
            print "INDEX_HITS=" K
            for (r = 1; r <= K; r++) {
                h = chash[r]; snip = ""
                if (h in ix) snip = (cap[h] != "" ? cap[h] : txt[h])
                snip = substr(snip, 1, 100)
                printf "INDEX_HIT\t%d\t%.3f\t%s\t%d\t%s\n", r, cscore[r], h, cnt[h], snip
                np = split(paths[h], pa, SUBSEP)
                for (pi = 1; pi <= np; pi++) printf "INDEX_HIT_PATH\t%s\t%s\n", h, pa[pi]
            }
            if (qn > 0) {
                m2 = 0; for (h in surv) if (!(h in ix)) m2++
                print "INDEX_COLD=" m2
                for (h in surv) if (!(h in ix)) print "INDEX_COLD\t" h "\t" coldrep[h]
            } else print "INDEX_COLD=0"
        }
        ' "$CAP" "$TSV"
        # LRU touch: a search is a use, so bump last_seen for warm hashes in this
        # scan, bounded to once/day (only rows whose stored date < today), so a
        # search rewrites the cache at most once a day. Mirrors the .ps1.
        if [ -f "$CAPTIONS" ]; then
            today="$(date -u +%Y-%m-%d)"; now2="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            sh="$(mktemp)"; awk -F'\t' '$3!=""{print $3}' "$TSV" | sort -u > "$sh"
            ttmp="$(mktemp)"
            # OFS=tab: assigning $4 rebuilds $0, which would otherwise re-join with spaces.
            touched="$(awk -F'\t' -v s="$SCHEMA" -v today="$today" -v now2="$now2" -v out="$ttmp" '
                BEGIN { OFS="\t" }
                FNR==NR { want[$1]=1; next }
                { if (NF>=20 && $2+0>=s && ($1 in want) && substr($4,1,10) < today) { $4=now2; n++ } print > out }
                END { print n+0 }
            ' "$sh" "$CAPTIONS")"
            if [ "${touched:-0}" -gt 0 ]; then mv -f "$ttmp" "$CAPTIONS"; echo "INDEX_TOUCHED=$touched"; else rm -f "$ttmp"; fi
            rm -f "$sh"
        fi
        ;;
    facets)
        # Dump cached facets for warm hashes in a scan (for img-organize to reuse
        # instead of re-visioning). Count first, then one line per distinct warm hash.
        if [ -z "$TSV" ] || [ ! -f "$TSV" ]; then echo "INDEX_ERROR=facets needs --tsv (an image-find scan)"; exit 1; fi
        CAP="$(cap_src)"
        awk -F'\t' -v s="$SCHEMA" -v capf="$CAP" '
            FILENAME==capf { if (NF>=20 && $2+0>=s) { cat[$1]=$13; sub2[$1]=$14; act[$1]=$12; plc[$1]=$11; cp[$1]=$19; ix[$1]=1 } next }
            { h=$3; if (h=="" || seen[h]++ || !(h in ix)) next; n++; out[n]="INDEX_FACET\t" h "\t" $4 "\t" cat[h] "\t" sub2[h] "\t" act[h] "\t" plc[h] "\t" cp[h] }
            END { print "INDEX_FACETS=" n+0; for (i=1;i<=n;i++) print out[i] }
        ' "$CAP" "$TSV"
        ;;
    prune)
        # User action only: drop rows last seen before the cutoff. NOT presence-
        # based (absence from one scan != gone). ISO 8601 sorts lexically, so a
        # plain string compare against the cutoff is a chronological compare.
        if [ ! -f "$CAPTIONS" ]; then echo "INDEX_PRUNED=0"; exit 0; fi
        if date -u -d '-1 days' >/dev/null 2>&1; then cutoff="$(date -u -d "-$DAYS days" +%Y-%m-%dT%H:%M:%SZ)"; else cutoff="$(date -u -v-"${DAYS}"d +%Y-%m-%dT%H:%M:%SZ)"; fi
        before="$(awk -F'\t' -v s="$SCHEMA" 'NF>=20 && $2+0>=s' "$CAPTIONS" | grep -c . || true)"
        tmp="$(mktemp)"
        awk -F'\t' -v s="$SCHEMA" -v cut="$cutoff" 'NF>=20 && $2+0>=s { if ($4 != "" && $4 < cut) next; print }' "$CAPTIONS" > "$tmp"
        kept="$(grep -c . "$tmp" || true)"
        mv -f "$tmp" "$CAPTIONS"
        echo "INDEX_PRUNED=$((before - kept))"
        echo "INDEX_CAPTIONS=$kept"
        ;;

    *) echo "INDEX_ERROR=unknown verb '$VERB'" ;;
esac
