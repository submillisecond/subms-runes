<#
  image-index - the content-search cache for the imageverse pack. A GLOBAL,
  content-addressed (sha1-keyed) store of structured per-image records, so a
  given image is vision-captioned ONCE and every later search/organise reads
  text instead of re-reading pixels. Path-independent: moves/renames/copies
  reuse the caption; a deleted file simply drops out of the live scan and can
  never be returned (presence is the scan's job, never the index's).

  Store: %LOCALAPPDATA%\runes\imageverse\index\ (owner-only ACL)
    captions.tsv   one row per content hash (schema below)
    .schema        integer; bump invalidates every row (re-vision)

  Verbs:
    status [-Tsv <scan>]              store location, schema, count; with a live
                                      image-find scan, also warm/cold coverage
    plan   -Tsv <scan>                cold delta: distinct hashes not yet
                                      captioned -> a thumbnail worklist (no vision)
    put    -Batch <rows> [-Scan s]    upsert caption rows after the skill's vision
                                      pass; pulls lat/lon/camera from -Scan, dims
                                      + phash from the file, redacts secrets
    clear                             nuke the cache

  query / prune land in step 2 (see SPEC.md).

  -Tsv / -Scan take an image-find TSV: <date> \t <size> \t <sha1> \t <path> \t
  <lat> \t <lon> \t <camera>. Output is KEY=value lines then TSV rows, like
  image-find / cluster.
#>
param(
    [Parameter(Position = 0)][string]$Verb = 'status',
    [string]$Tsv,
    [string]$Batch,
    [string]$Scan,
    [string]$Query,
    [string]$Geo,
    [string]$Name,
    [long]$MinBytes = 0,
    [string]$TagAny,
    [int]$Days = 365,
    [switch]$NearDup,
    [int]$HammingMax = 6,
    [string]$Followers,
    [switch]$Recurse,
    [int]$Top = 12
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
try { Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null } catch {}

$root = Join-Path $env:LOCALAPPDATA 'runes\imageverse\index'
$captions = Join-Path $root 'captions.tsv'
$schemaFile = Join-Path $root '.schema'

# Column order is the on-disk contract. Vision fields are filled by `put` from
# the skill; metadata (w/h/lat/lon/camera/phash) is derived locally.
$COLS = @('hash', 'iv', 'phash', 'last_seen', 'seen_path', 'w', 'h', 'lat', 'lon',
    'camera', 'place_path', 'activity', 'category', 'subcategory', 'entities',
    'objects', 'attributes', 'text', 'caption', 'source')

function Ensure-Store {
    if (-not (Test-Path $root)) {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        try { icacls $root /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" *> $null } catch {}
    }
    if (-not (Test-Path $schemaFile)) { Set-Content -Path $schemaFile -Value '1' -Encoding ASCII }
}
function Get-Schema { if (Test-Path $schemaFile) { [int]((Get-Content $schemaFile -Raw).Trim()) } else { 1 } }

# Tab/newline in any field would corrupt the TSV; flatten on write.
function San([string]$s) { if ($null -eq $s) { return '' } ($s -replace "[`t`r`n]+", ' ').Trim() }

# Read captions into hash -> ordered record. Rows below the current schema are
# dropped (treated as absent -> re-captioned), the only invalidation path.
function Read-Index([int]$schema) {
    $map = @{}
    if (-not (Test-Path $captions)) { return $map }
    foreach ($line in Get-Content $captions) {
        if (-not $line.Trim()) { continue }
        $c = $line -split "`t"
        if ($c.Count -lt $COLS.Count) { continue }
        $rec = [ordered]@{}
        for ($i = 0; $i -lt $COLS.Count; $i++) { $rec[$COLS[$i]] = $c[$i] }
        if ([int]$rec.iv -lt $schema) { continue }
        $map[$rec.hash] = $rec
    }
    $map
}

function Write-Index($map) {
    $tmp = "$captions.tmp"
    $sb = New-Object System.Text.StringBuilder
    foreach ($rec in $map.Values) {
        $vals = foreach ($col in $COLS) { San([string]$rec[$col]) }
        [void]$sb.AppendLine(($vals -join "`t"))
    }
    [IO.File]::WriteAllText($tmp, $sb.ToString(), [Text.Encoding]::UTF8)
    Move-Item -LiteralPath $tmp -Destination $captions -Force   # atomic swap
}

# image-find scan TSV: date,size,hash,path,lat,lon,camera. Returns the rows we
# care about, keyed for the joins below.
function Read-Scan([string]$path) {
    $rows = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path $path)) { return $rows }
    foreach ($line in Get-Content $path) {
        if (-not $line.Trim()) { continue }
        $c = $line -split "`t"
        if ($c.Count -lt 4) { continue }
        $rows.Add([pscustomobject]@{
                date = $c[0]; size = $c[1]; hash = $c[2]; path = $c[3]
                lat  = $(if ($c.Count -ge 5) { $c[4] } else { '' })
                lon  = $(if ($c.Count -ge 6) { $c[5] } else { '' })
                cam  = $(if ($c.Count -ge 7) { $c[6] } else { '' })
            })
    }
    $rows
}

# dHash + dimensions from a single image open. dHash (9x8 grayscale, adjacent-
# pixel gradient -> 64 bits) groups near-duplicates; blank if the file is gone.
function Get-ImageMeta([string]$path) {
    $r = @{ w = ''; h = ''; phash = '' }
    if (-not (Test-Path -LiteralPath $path)) { return $r }
    try {
        $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path))
        $ms = New-Object IO.MemoryStream(, $bytes)
        $img = [Drawing.Image]::FromStream($ms)
        $r.w = $img.Width; $r.h = $img.Height
        $bmp = New-Object Drawing.Bitmap(9, 8)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, 9, 8)
        $g.Dispose()
        $val = [uint64]0; $bit = 0
        for ($y = 0; $y -lt 8; $y++) {
            for ($x = 0; $x -lt 8; $x++) {
                $l = $bmp.GetPixel($x, $y); $rt = $bmp.GetPixel($x + 1, $y)
                $ll = $l.R * 0.299 + $l.G * 0.587 + $l.B * 0.114
                $rl = $rt.R * 0.299 + $rt.G * 0.587 + $rt.B * 0.114
                if ($ll -gt $rl) { $val = $val -bor ([uint64]1 -shl $bit) }
                $bit++
            }
        }
        $bmp.Dispose(); $img.Dispose(); $ms.Dispose()
        $r.phash = '{0:x16}' -f $val
    }
    catch {}
    $r
}

# Cached on-screen text can carry secrets (a screenshot of a .env). Redact
# before the text lands in a durable file.
function Redact-Secrets([string]$t) {
    if (-not $t) { return @{ text = ''; n = 0 } }
    $n = 0
    $pats = @(
        @{ re = '(?i)\b(sk|pk|rk)-[A-Za-z0-9]{16,}\b'; ty = 'api-key' },
        @{ re = '\bAKIA[0-9A-Z]{16}\b'; ty = 'aws-key' },
        @{ re = '\bgh[pousr]_[A-Za-z0-9]{20,}\b'; ty = 'gh-token' },
        @{ re = '(?i)\bbearer\s+[A-Za-z0-9._\-]{20,}\b'; ty = 'bearer' },
        @{ re = '-----BEGIN [A-Z ]*PRIVATE KEY-----'; ty = 'private-key' },
        @{ re = '(?i)\b(api[_-]?key|secret|password|passwd|access[_-]?token|token)\b\s*[:=]\s*\S{6,}'; ty = 'kv-secret' }
    )
    foreach ($p in $pats) {
        $ms = [regex]::Matches($t, $p.re)
        if ($ms.Count) { $n += $ms.Count; $t = [regex]::Replace($t, $p.re, "[redacted:$($p.ty)]") }
    }
    @{ text = $t; n = $n }
}

# Great-circle km between two lat/lon (geo prefilter). Same formula as cluster.ps1.
function Haversine($la1, $lo1, $la2, $lo2) {
    $deg = [math]::PI / 180
    $dLa = ($la2 - $la1) * $deg; $dLo = ($lo2 - $lo1) * $deg
    $a = [math]::Sin($dLa / 2) * [math]::Sin($dLa / 2) + [math]::Cos($la1 * $deg) * [math]::Cos($la2 * $deg) * [math]::Sin($dLo / 2) * [math]::Sin($dLo / 2)
    6371.0 * 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))
}

# Lowercase, split on non-alphanumeric, drop empties -> token list.
function Tokenize([string]$s) { @(($s.ToLower() -split '[^a-z0-9]+') | Where-Object { $_ }) }

# Hamming distance between two 16-hex (64-bit) dHashes; missing -> 64 (= not near).
function Hamming([string]$a, [string]$b) {
    if (-not $a -or -not $b) { return 64 }
    try { $x = [Convert]::ToUInt64($a, 16) -bxor [Convert]::ToUInt64($b, 16) } catch { return 64 }
    $c = 0; for ($i = 0; $i -lt 64; $i++) { if ((($x -shr $i) -band 1) -ne 0) { $c++ } }
    $c
}

$schema = if (Test-Path $schemaFile) { Get-Schema } else { 1 }

switch ($Verb.ToLower()) {

    'status' {
        Write-Output ("INDEX_DIR=" + $root)
        Write-Output ("INDEX_SCHEMA=" + $schema)
        $idx = Read-Index $schema
        Write-Output ("INDEX_CAPTIONS=" + $idx.Count)
        if ($Tsv) {
            $scanRows = Read-Scan $Tsv
            $seen = @{}; $warm = 0; $cold = 0
            foreach ($s in $scanRows) {
                if ($seen.ContainsKey($s.hash)) { continue }   # count distinct content
                $seen[$s.hash] = $true
                if ($idx.ContainsKey($s.hash)) { $warm++ } else { $cold++ }
            }
            Write-Output ("INDEX_WARM=" + $warm)
            Write-Output ("INDEX_COLD=" + $cold)
        }
    }

    'plan' {
        if (-not $Tsv) { Write-Output 'INDEX_ERROR=plan needs -Tsv (an image-find scan)'; exit 1 }
        $idx = Read-Index $schema
        $scanRows = Read-Scan $Tsv
        # Distinct cold hashes only: caption once per content, even with N copies.
        # Keep the shortest path as the representative to thumbnail.
        $cold = @{}; $warm = 0
        foreach ($s in $scanRows) {
            if ($idx.ContainsKey($s.hash)) { $warm++; continue }
            if (-not $cold.ContainsKey($s.hash) -or $s.path.Length -lt $cold[$s.hash].Length) {
                $cold[$s.hash] = $s.path
            }
        }
        if (-not $NearDup) {
            Write-Output ("INDEX_COLD=" + $cold.Count)
            foreach ($h in $cold.Keys) { Write-Output ("INDEX_COLD`t" + $h + "`t" + $cold[$h]) }
            Write-Output ("INDEX_WARM=" + $warm)
        }
        else {
            # Near-dup collapse: a cold image whose dHash is within HammingMax of an
            # already-captioned (warm) image OR an earlier cold rep is a FOLLOWER -
            # it inherits the rep's coarse caption (see put -Followers) and is NEVER
            # vision-read. Only true reps land in INDEX_COLD. Local-only (opens each
            # cold file for its phash; zero tokens). Reps are anchors: (rep-hash, phash).
            $anchors = New-Object System.Collections.Generic.List[object]
            foreach ($w in $idx.Values) { if ($w.phash) { $anchors.Add([pscustomobject]@{ hash = $w.hash; phash = $w.phash }) } }
            $reps = @{}; $followList = New-Object System.Collections.Generic.List[object]
            # Stable order so grouping is deterministic across runs.
            foreach ($h in ($cold.Keys | Sort-Object)) {
                $p = $cold[$h]
                $ph = (Get-ImageMeta $p).phash
                $repHash = $null
                if ($ph) {
                    foreach ($a in $anchors) { if ((Hamming $ph $a.phash) -le $HammingMax) { $repHash = $a.hash; break } }
                }
                if ($repHash) { $followList.Add([pscustomobject]@{ hash = $h; path = $p; rep = $repHash }) }
                else { $reps[$h] = $p; $anchors.Add([pscustomobject]@{ hash = $h; phash = $ph }) }
            }
            Write-Output ("INDEX_COLD=" + $reps.Count)
            foreach ($h in $reps.Keys) { Write-Output ("INDEX_COLD`t" + $h + "`t" + $reps[$h]) }
            Write-Output ("INDEX_NEARDUP=" + $followList.Count)
            foreach ($f in $followList) { Write-Output ("INDEX_NEARDUP`t" + $f.hash + "`t" + $f.path + "`t" + $f.rep) }
            Write-Output ("INDEX_WARM=" + $warm)
        }
    }

    'put' {
        if (-not $Batch -or -not (Test-Path $Batch)) { Write-Output 'INDEX_ERROR=put needs -Batch <rows tsv>'; exit 1 }
        Ensure-Store
        $schema = Get-Schema
        $idx = Read-Index $schema
        # Optional metadata join: hash -> lat/lon/camera from the live scan.
        $meta = @{}
        if ($Scan) { foreach ($s in (Read-Scan $Scan)) { if (-not $meta.ContainsKey($s.hash)) { $meta[$s.hash] = $s } } }
        $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        # Batch row: hash, path, category, subcategory, activity, place_path,
        # entities, objects, attributes, caption, text (inline, single line).
        # A stray tab inside the text just merges into it (cols 11.. are re-joined).
        $put = 0; $redacted = 0
        foreach ($line in Get-Content $Batch) {
            if (-not $line.Trim()) { continue }
            $c = $line -split "`t"
            if ($c.Count -lt 2) { continue }
            $hash = $c[0].Trim(); $path = $c[1]
            $raw = $(if ($c.Count -ge 11) { ($c[10..($c.Count - 1)] -join ' ') } else { '' })
            $red = Redact-Secrets $raw; if ($red.n -gt 0) { $redacted += $red.n }
            $im = Get-ImageMeta $path
            $m = $meta[$hash]
            $rec = [ordered]@{}
            foreach ($col in $COLS) { $rec[$col] = '' }
            $rec.hash = $hash
            $rec.iv = $schema
            $rec.phash = $im.phash
            $rec.last_seen = $now
            $rec.seen_path = $path
            $rec.w = $im.w; $rec.h = $im.h
            if ($m) { $rec.lat = $m.lat; $rec.lon = $m.lon; $rec.camera = $m.cam }
            $rec.place_path = $(if ($c.Count -ge 6) { $c[5] } else { '' })
            $rec.activity = $(if ($c.Count -ge 5) { $c[4] } else { '' })
            $rec.category = $(if ($c.Count -ge 3) { $c[2] } else { '' })
            $rec.subcategory = $(if ($c.Count -ge 4) { $c[3] } else { '' })
            $rec.entities = $(if ($c.Count -ge 7) { $c[6] } else { '' })
            $rec.objects = $(if ($c.Count -ge 8) { $c[7] } else { '' })
            $rec.attributes = $(if ($c.Count -ge 9) { $c[8] } else { '' })
            $rec.caption = $(if ($c.Count -ge 10) { $c[9] } else { '' })
            $txt = San $red.text; if ($txt.Length -gt 2000) { $txt = $txt.Substring(0, 2000) }
            $rec.text = $txt
            $rec.source = 'model'
            $idx[$hash] = $rec   # last-write-wins per hash
            $put++
        }
        # Near-dup followers (from plan -NearDup): each inherits its rep's COARSE
        # fields (category/subcategory/objects/activity/place_path) + caption, but
        # NOT text (look-alikes differ exactly in their text) and is marked
        # source=propagated:<rep>. Row: follower-hash, follower-path, rep-hash.
        $propagated = 0
        if ($Followers -and (Test-Path $Followers)) {
            foreach ($line in Get-Content $Followers) {
                if (-not $line.Trim()) { continue }
                $c = $line -split "`t"
                if ($c.Count -lt 3) { continue }
                $fh = $c[0].Trim(); $fp = $c[1]; $rh = $c[2].Trim()
                $rep = $idx[$rh]
                if (-not $rep) { continue }   # rep must be captioned (this batch or cache)
                $im = Get-ImageMeta $fp
                $m = $meta[$fh]
                $rec = [ordered]@{}; foreach ($col in $COLS) { $rec[$col] = '' }
                $rec.hash = $fh; $rec.iv = $schema; $rec.phash = $im.phash
                $rec.last_seen = $now; $rec.seen_path = $fp; $rec.w = $im.w; $rec.h = $im.h
                if ($m) { $rec.lat = $m.lat; $rec.lon = $m.lon; $rec.camera = $m.cam }
                $rec.place_path = $rep.place_path; $rec.activity = $rep.activity
                $rec.category = $rep.category; $rec.subcategory = $rep.subcategory
                $rec.objects = $rep.objects; $rec.caption = $rep.caption
                # entities/attributes/text intentionally left empty (not coarse-safe).
                $rec.source = 'propagated:' + $rh
                $idx[$fh] = $rec
                $propagated++
            }
        }
        # Cap the global cache: evict least-recently-seen over the limit. Not
        # presence-based (global cache); a pure size bound, like clip-history.
        $maxN = if ($env:RUNES_IMAGEVERSE_INDEX_MAX) { [int]$env:RUNES_IMAGEVERSE_INDEX_MAX } else { 50000 }
        $evicted = 0
        if ($idx.Count -gt $maxN) {
            $keep = @($idx.Values | Sort-Object { $_.last_seen } -Descending | Select-Object -First $maxN)
            $evicted = $idx.Count - $keep.Count
            $idx = @{}; foreach ($kr in $keep) { $idx[$kr.hash] = $kr }
        }
        Write-Index $idx
        Write-Output ("INDEX_PUT=" + $put)
        if ($propagated -gt 0) { Write-Output ("INDEX_PROPAGATED=" + $propagated) }
        if ($redacted -gt 0) { Write-Output ("INDEX_REDACTED=" + $redacted) }
        if ($evicted -gt 0) { Write-Output ("INDEX_EVICTED=" + $evicted) }
    }

    'clear' {
        if (Test-Path $captions) { Remove-Item $captions -Force }
        Write-Output 'INDEX_CLEARED=1'
    }

    'query' {
        if (-not $Tsv -or -not (Test-Path $Tsv)) { Write-Output 'INDEX_ERROR=query needs -Tsv (an image-find scan)'; exit 1 }
        $idx = Read-Index $schema
        $rows = Read-Scan $Tsv

        $geoLat = $null; $geoLon = $null; $geoKm = $null
        if ($Geo) { $g = $Geo -split ','; if ($g.Count -ge 3) { $geoLat = [double]$g[0]; $geoLon = [double]$g[1]; $geoKm = [double]$g[2] } }
        $nameLc = if ($Name) { $Name.ToLower() } else { '' }
        $tags = @(); if ($TagAny) { $tags = @(($TagAny.ToLower() -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
        $terms = if ($Query) { Tokenize $Query } else { @() }

        # Metadata prefilter on the live scan (date/name handled upstream by image-find).
        $paths = @{}; $bestDate = @{}; $coldRep = @{}
        foreach ($s in $rows) {
            if (-not $s.hash) { continue }
            if ($nameLc -and ($s.path.ToLower() -notlike "*$nameLc*")) { continue }
            if ($MinBytes -gt 0 -and ([long]$s.size -lt $MinBytes)) { continue }
            if ($null -ne $geoKm) {
                if (-not ($s.lat -and $s.lon)) { continue }
                if ((Haversine $geoLat $geoLon ([double]$s.lat) ([double]$s.lon)) -gt $geoKm) { continue }
            }
            if (-not $paths.ContainsKey($s.hash)) { $paths[$s.hash] = New-Object System.Collections.Generic.List[string] }
            $paths[$s.hash].Add($s.path)
            if (-not $bestDate.ContainsKey($s.hash) -or $s.date -gt $bestDate[$s.hash]) { $bestDate[$s.hash] = $s.date }
            if (-not $idx.ContainsKey($s.hash)) {
                if (-not $coldRep.ContainsKey($s.hash) -or $s.path.Length -lt $coldRep[$s.hash].Length) { $coldRep[$s.hash] = $s.path }
            }
        }

        # Tag string per warm survivor (for TagAny filter + scoring bonus).
        $tagStr = @{}
        foreach ($h in $paths.Keys) {
            if ($idx.ContainsKey($h)) {
                $r = $idx[$h]
                $tt = Tokenize (@($r.category, $r.subcategory, $r.activity, $r.place_path) -join ' ')
                $tagStr[$h] = ' ' + ($tt -join ' ') + ' '
            }
        }
        function Test-Tag($h, $tag) { $tagStr.ContainsKey($h) -and $tagStr[$h].Contains(" $tag ") }

        $hits = New-Object System.Collections.Generic.List[object]
        if ($terms.Count -gt 0) {
            # Warm survivors passing TagAny become the BM25 corpus.
            $warm = @($paths.Keys | Where-Object { $idx.ContainsKey($_) })
            if ($tags.Count) { $warm = @($warm | Where-Object { $hh = $_; ($tags | Where-Object { Test-Tag $hh $_ }).Count -gt 0 }) }
            $docTok = @{}; $docLen = @{}
            foreach ($h in $warm) {
                $r = $idx[$h]
                $docTok[$h] = Tokenize (@($r.category, $r.subcategory, $r.activity, $r.place_path, $r.entities, $r.objects, $r.attributes, $r.caption, $r.text) -join ' ')
                $docLen[$h] = $docTok[$h].Count
            }
            $nw = $warm.Count
            $avgdl = if ($nw -gt 0) { (($warm | ForEach-Object { $docLen[$_] }) | Measure-Object -Sum).Sum / $nw } else { 0 }
            if ($avgdl -lt 1) { $avgdl = 1 }
            $df = @{}
            foreach ($t in ($terms | Select-Object -Unique)) { $c = 0; foreach ($h in $warm) { if ($docTok[$h] -contains $t) { $c++ } }; $df[$t] = $c }
            $k1 = 1.5; $b = 0.75
            foreach ($h in $warm) {
                $tf = @{}; foreach ($w in $docTok[$h]) { if ($tf.ContainsKey($w)) { $tf[$w]++ } else { $tf[$w] = 1 } }
                $score = 0.0
                foreach ($t in $terms) {
                    $f = [int]$tf[$t]; if ($f -le 0) { continue }
                    $idf = [math]::Log(1 + ($nw - $df[$t] + 0.5) / ($df[$t] + 0.5))
                    $denom = $f + $k1 * (1 - $b + $b * ($docLen[$h] / $avgdl))
                    $score += $idf * ($f * ($k1 + 1)) / $denom
                    if (Test-Tag $h $t) { $score += $idf }
                }
                if ($score -gt 0) { $hits.Add([pscustomobject]@{ hash = $h; score = $score; date = $bestDate[$h] }) }
            }
            $ranked = @($hits | Sort-Object @{Expression = { $_.score }; Descending = $true }, @{Expression = { $_.date }; Descending = $true })
        }
        else {
            # Metadata-only: every distinct survivor, newest first. TagAny keeps warm-only.
            $cand = if ($tags.Count) { @($paths.Keys | Where-Object { $hh = $_; $idx.ContainsKey($hh) -and ($tags | Where-Object { Test-Tag $hh $_ }).Count -gt 0 }) } else { @($paths.Keys) }
            $ranked = @($cand | ForEach-Object { [pscustomobject]@{ hash = $_; score = 0.0; date = $bestDate[$_] } } | Sort-Object @{Expression = { $_.date }; Descending = $true })
        }

        $topHits = @($ranked | Select-Object -First $Top)
        Write-Output ("INDEX_HITS=" + $topHits.Count)
        $rank = 0
        foreach ($hit in $topHits) {
            $rank++; $h = $hit.hash
            $snip = ''
            if ($idx.ContainsKey($h)) { $r = $idx[$h]; $snip = if ($r.caption) { $r.caption } else { $r.text } }
            $snip = San $snip; if ($snip.Length -gt 100) { $snip = $snip.Substring(0, 100) }
            Write-Output ("INDEX_HIT`t$rank`t" + ('{0:0.000}' -f $hit.score) + "`t$h`t" + $paths[$h].Count + "`t" + $snip)
            foreach ($p in $paths[$h]) { Write-Output ("INDEX_HIT_PATH`t$h`t$p") }
        }
        if ($terms.Count -gt 0) {
            Write-Output ("INDEX_COLD=" + $coldRep.Count)
            foreach ($h in $coldRep.Keys) { Write-Output ("INDEX_COLD`t$h`t" + $coldRep[$h]) }
        }
        else { Write-Output 'INDEX_COLD=0' }
        # LRU touch: a search IS a use, so bump last_seen for warm hashes present
        # in this scan - keeps frequently-searched-but-rarely-recaptioned images
        # from aging out. Bounded to once/day (only when the stored date < today)
        # so a search does not rewrite the cache more than once a day.
        $today = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
        $now2 = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        $touched = 0
        foreach ($s in $rows) {
            if ($idx.ContainsKey($s.hash)) {
                $r = $idx[$s.hash]
                if ($r.last_seen.Length -ge 10 -and $r.last_seen.Substring(0, 10) -lt $today) { $r.last_seen = $now2; $touched++ }
            }
        }
        if ($touched -gt 0) { Write-Index $idx; Write-Output ("INDEX_TOUCHED=" + $touched) }
    }
    'facets' {
        # Dump cached facets for the warm hashes in a scan, for img-organize to
        # reuse instead of re-visioning. One line per distinct warm hash.
        if (-not $Tsv -or -not (Test-Path $Tsv)) { Write-Output 'INDEX_ERROR=facets needs -Tsv (an image-find scan)'; exit 1 }
        $idx = Read-Index $schema
        $rows = Read-Scan $Tsv
        $seen = @{}; $n = 0; $lines = New-Object System.Collections.Generic.List[string]
        foreach ($s in $rows) {
            if (-not $s.hash -or $seen.ContainsKey($s.hash)) { continue }
            $seen[$s.hash] = $true
            if (-not $idx.ContainsKey($s.hash)) { continue }
            $r = $idx[$s.hash]
            $lines.Add("INDEX_FACET`t$($s.hash)`t$($s.path)`t$($r.category)`t$($r.subcategory)`t$($r.activity)`t$($r.place_path)`t$($r.caption)")
            $n++
        }
        Write-Output ("INDEX_FACETS=" + $n)
        foreach ($l in $lines) { Write-Output $l }
    }
    'prune' {
        # User action only: drop rows last seen before the cutoff. NOT presence-
        # based (absence from one scan != gone, the cache is global).
        if (-not (Test-Path $captions)) { Write-Output 'INDEX_PRUNED=0'; break }
        $idx = Read-Index $schema
        $cut = (Get-Date).ToUniversalTime().AddDays(-$Days)
        $before = $idx.Count
        $kept = @{}
        foreach ($rec in $idx.Values) {
            $ls = [datetime]::MinValue
            $ok = [datetime]::TryParse($rec.last_seen, [ref]$ls)
            if ($ok -and $ls.ToUniversalTime() -lt $cut) { continue }   # too old, drop
            $kept[$rec.hash] = $rec
        }
        Write-Index $kept
        Write-Output ("INDEX_PRUNED=" + ($before - $kept.Count))
        Write-Output ("INDEX_CAPTIONS=" + $kept.Count)
    }

    default { Write-Output "INDEX_ERROR=unknown verb '$Verb'" }
}
