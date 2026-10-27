# build-manifest: turn an <album><TAB><source> classification into a file-ops manifest with dated, collision-safe names.
# Flags, the dest-name rule and output: ../contract/CONTRACTS.md 1.5, 2.4.
param(
    [string]$Class,
    [string]$Shots,
    [string]$Meta,
    [string]$Base,
    [ValidateSet('move', 'copy')][string]$Op = 'move',
    [string]$Plugin = 'misc',
    [string]$Manifest
)
$ErrorActionPreference = 'Stop'
if (-not $Class -or -not (Test-Path $Class)) { Write-Output 'MANIFEST_ERROR=missing or unreadable -Class'; exit 1 }
if (-not $Manifest) { $Manifest = Join-Path $env:TEMP "runes\$Plugin\manifest.tsv" }

# The shots list (image-find -OutFile order): full path per line, 1-based index.
$shotsArr = @()
$byName = @{}
if ($Shots -and (Test-Path $Shots)) {
    $shotsArr = @(Get-Content $Shots | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
    foreach ($t in $shotsArr) { $byName[[IO.Path]::GetFileName($t)] = $t }
}

# EXIF capture time from -Meta beats filename and mtime, so bursts order by real time.
$byMeta = @{}
if ($Meta -and (Test-Path $Meta)) {
    foreach ($line in Get-Content $Meta) {
        $c = $line -split "`t"; if ($c.Count -lt 4) { continue }
        $dcol = $c[0].Trim(); $path = $c[3].Trim()
        if ($dcol -match '^(\d{4}-\d{2}-\d{2})[ T](\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?') {
            $ssv = ''; if ($Matches[5]) { $ssv = $Matches[5] }
            $byMeta[$path] = @{ date = $Matches[1]; time = ($Matches[2] + $Matches[3] + $Matches[4]); subsec = $ssv }
        }
    }
}

# Expand "1-16,19,22-26" into 1,2,...,16,19,22,...,26.
function Expand-Spec($spec) {
    $out = New-Object System.Collections.Generic.List[int]
    foreach ($tok in ($spec -split ',')) {
        $tk = $tok.Trim(); if (-not $tk) { continue }
        if ($tk -match '^(\d+)\s*-\s*(\d+)$') { [int]$a = $Matches[1]; [int]$b = $Matches[2]; foreach ($n in $a..$b) { $out.Add($n) } }
        elseif ($tk -match '^\d+$') { $out.Add([int]$tk) }
    }
    $out
}

# -Class may be a directory of batch .tsv files, read in name order.
$batchInfo = ''
if (Test-Path -LiteralPath $Class -PathType Container) {
    $bf = @(Get-ChildItem -LiteralPath $Class -Filter *.tsv | Sort-Object Name)
    $rows = $bf | ForEach-Object { Get-Content $_.FullName }
    if ($bf.Count -gt 0) {
        # Timed from thumbnails-done to now, which covers the whole vision phase.
        $start = $bf[0].LastWriteTime
        $thumbs = Join-Path (Split-Path -Parent $Class) 'thumbs'
        if (Test-Path $thumbs) {
            $tf = @(Get-ChildItem -LiteralPath $thumbs -File)
            if ($tf.Count) { $start = ($tf | Sort-Object LastWriteTime)[-1].LastWriteTime }
        }
        $span = [int](((Get-Date) - $start).TotalSeconds); if ($span -lt 0) { $span = 0 }
        $batchInfo = "MANIFEST_BATCHES=$($bf.Count) MANIFEST_CLASSIFY_SECONDS=$span"
    }
}
else { $rows = Get-Content $Class }
$rows = $rows | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') }
$pairs = New-Object System.Collections.Generic.List[object]   # {album, src}
foreach ($r in $rows) {
    $p = $r -split "`t"
    if ($p.Count -lt 2) { continue }
    $album = $p[0].Trim(); $val = $p[1].Trim()
    # grouped form: one line per album, second field is an index SPEC (ranges into
    # the shots list) - the compact classification. Else per-image filename/path.
    if ($shotsArr.Count -gt 0 -and $val -match '^[\d,\s\-]+$') {
        foreach ($idx in (Expand-Spec $val)) {
            if ($idx -ge 1 -and $idx -le $shotsArr.Count) { $pairs.Add([pscustomobject]@{ album = $album; src = $shotsArr[$idx - 1] }) }
        }
    }
    else {
        if ($val -notmatch '[\\/]' -and $byName.ContainsKey($val)) { $val = $byName[$val] }
        $pairs.Add([pscustomobject]@{ album = $album; src = $val })
    }
}

$entries = foreach ($pair in $pairs) {
    $album = $pair.album; $src = $pair.src; $subsec = ''
    # Timestamp source priority: EXIF (-Meta, incl. sub-second) > date in filename > mtime.
    if ($byMeta.ContainsKey($src)) { $date = $byMeta[$src].date; $time = $byMeta[$src].time; $subsec = $byMeta[$src].subsec }
    elseif ($src -match '(\d{4}-\d{2}-\d{2})[ _T-](\d{6})') { $date = $Matches[1]; $time = $Matches[2] }
    elseif (Test-Path -LiteralPath $src) {
        $t = (Get-Item -LiteralPath $src).LastWriteTime
        if ($src -match '(\d{4}-\d{2}-\d{2})') { $date = $Matches[1] } else { $date = $t.ToString('yyyy-MM-dd') }
        $time = $t.ToString('HHmmss')
    }
    else { $date = 'undated'; $time = '000000' }
    [pscustomobject]@{ album = $album; src = $src; date = $date; time = $time; subsec = $subsec }
}
if (-not $entries) { Write-Output 'MANIFEST_ERROR=no usable lines in -Class'; exit 1 }
if (-not $Base) { $Base = Split-Path -Parent (($entries | Select-Object -First 1).src) }

$seen = @{}
$lines = New-Object System.Collections.Generic.List[string]
foreach ($e in ($entries | Sort-Object album, date, time, subsec, src)) {
    $ext = [IO.Path]::GetExtension($e.src); if (-not $ext) { $ext = '.png' }
    # The album may be a nested path (e.g. "2026/05/stochbook" for a yyyy/mm/album
    # schema) - normalise separators, use the leaf segment for the file name.
    $albumPath = $e.album -replace '[\\/]+', [IO.Path]::DirectorySeparatorChar
    $leaf = ($e.album -split '[\\/]+')[-1]
    # The folder keeps its "MM. " month prefix so albums sort; the file name drops it.
    $fileLeaf = $leaf -replace '^(0[1-9]|1[0-2])\.\s+', ''
    if (-not $fileLeaf) { $fileLeaf = $leaf }
    # Sub-second (from EXIF) gives bursts unique, true-ordered names; else the -N
    # counter still keeps same-second files collision-safe.
    $stem = if ($e.subsec) { "$fileLeaf-$($e.date)-$($e.time)-$($e.subsec)" } else { "$fileLeaf-$($e.date)-$($e.time)" }
    $n = ([int]$seen["$albumPath|$stem"]) + 1; $seen["$albumPath|$stem"] = $n
    $name = if ($n -eq 1) { "$stem$ext" } else { "$stem-$n$ext" }
    $dest = Join-Path (Join-Path $Base $albumPath) $name
    $lines.Add("$Op`t$($e.src)`t$dest")
}
$lines | Set-Content -Path $Manifest -Encoding UTF8
Write-Output ('MANIFEST_FILE=' + $Manifest)
Write-Output ('MANIFEST_COUNT=' + $lines.Count)
if ($batchInfo) { Write-Output $batchInfo }

# Report images the classification dropped or assigned twice; never proceed silently.
if ($shotsArr.Count -gt 0) {
    $counts = @{}
    foreach ($pr in $pairs) { $counts[$pr.src] = ([int]$counts[$pr.src]) + 1 }
    $unassigned = @($shotsArr | Where-Object { -not $counts.ContainsKey($_) })
    $dups = @($counts.GetEnumerator() | Where-Object { $_.Value -gt 1 })
    Write-Output ("MANIFEST_COVERAGE=assigned $($pairs.Count) of $($shotsArr.Count); unassigned $($unassigned.Count); duplicated $($dups.Count)")
    foreach ($u in $unassigned) { Write-Output ("MANIFEST_UNASSIGNED`t" + $u) }
    foreach ($d in $dups) { Write-Output ("MANIFEST_DUPLICATE`t$($d.Value)`t" + $d.Key) }
}
foreach ($l in $lines) { Write-Output $l }
