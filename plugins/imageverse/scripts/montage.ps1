# montage: one contact sheet of an album or folder, near-duplicates collapsed, shuffled, no blank cells. Images only.
# montage.ps1 -Dir d | -List f [-OutDir d] [-Cols 8] [-Cell 300] [-Dist 10] [-Max N] [-Indexed] [-Plugin p]
param(
    [string]$Dir,
    [string]$List,
    [string]$OutDir,
    [int]$Cols = 8,
    [int]$Cell = 300,
    [int]$Dist = 10,
    [int]$Max = 0,
    [switch]$Indexed,
    [string]$Plugin = 'imageverse'
)
# dense by default (zero gaps, no index badges - packs the most per sheet for
# eyeballing); -Indexed gives stamped, padded cells for cell-by-cell classification.
$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$phash = Join-Path $scriptDir 'phash.ps1'
$thumbs = Join-Path $scriptDir 'thumbs.ps1'
$iext = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')
$vext = @('.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp', '.3g2', '.wmv', '.mpg', '.mpeg', '.mts', '.m2ts')

# gather sources
$srcs = @()
if ($Dir) { $srcs = @(Get-ChildItem -LiteralPath $Dir -File | Sort-Object Name | ForEach-Object { $_.FullName }) }
elseif ($List -and (Test-Path $List)) { $srcs = @(Get-Content $List | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }) }
else { Write-Output 'MONTAGE_ERROR=need -Dir or -List'; exit 1 }
$imgs = @($srcs | Where-Object { $iext -contains [IO.Path]::GetExtension($_).ToLower() })
$vids = @($srcs | Where-Object { $vext -contains [IO.Path]::GetExtension($_).ToLower() })

if (-not $OutDir) {
    $nm = if ($Dir) { (Split-Path $Dir -Leaf) } else { 'montage' }
    $nm = ($nm -replace '[\\/:. ]+', '_')
    $OutDir = Join-Path $env:TEMP "runes\$Plugin\montages\$nm"
}
$work = Join-Path $env:TEMP ("runes\$Plugin\_montwork_" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $OutDir, $work | Out-Null

# Collapse near-duplicates by perceptual hash, then shuffle. Files that fail to decode get no hash and drop out.
$reps = New-Object System.Collections.Generic.List[object]   # {path, count}
if ($imgs.Count -gt 0) {
    $il = Join-Path $work 'img.txt'; $imgs | Set-Content $il -Encoding UTF8
    $ph = Join-Path $work 'img.ph.tsv'
    & powershell.exe -ExecutionPolicy Bypass -File $phash hash -List $il -OutFile $ph | Out-Null
    $grpOut = & powershell.exe -ExecutionPolicy Bypass -File $phash group -In $ph -MaxDist $Dist
    $tmp = New-Object System.Collections.Generic.List[object]
    foreach ($line in $grpOut) {
        if ($line -notlike 'GROUP*') { continue }
        $c = $line -split "`t"; $m = $c[3] -split ','
        $tmp.Add([pscustomobject]@{ path = $m[0]; count = [int]$c[2] })
    }
    foreach ($r in ($tmp | Sort-Object { Get-Random })) { $reps.Add($r) }
}
$imgRepCount = $reps.Count

# 2) images only: videos are intentionally excluded - a montage is for browsing
# photos, and a single extracted still is unreliable (dark for night clips).

# 3) optional cap: sample evenly across the distinct-shot reps so coverage stays broad
$all = $reps.ToArray()
if ($Max -gt 0 -and $all.Count -gt $Max) {
    $step = $all.Count / [double]$Max
    $sampled = New-Object System.Collections.Generic.List[object]
    for ($s = 0; $s -lt $Max; $s++) { $sampled.Add($all[[int]([math]::Floor($s * $step))]) }
    $all = $sampled.ToArray()
}

# Fixed column count, trimmed to full rows so no cell is blank.
$N = $all.Count
$cols = [int][math]::Min([math]::Max(1, $Cols), [math]::Max(1, $N))
$rows = [int][math]::Max(1, [math]::Floor($N / [double]$cols))
$keep = $cols * $rows
if ($keep -lt $N) { $all = $all[0..($keep - 1)] }
$cell = [int][math]::Max(140, [math]::Min($Cell, [math]::Floor(2400 / $cols)))
$tileList = Join-Path $work 'tiles.txt'
$all | ForEach-Object { $_.path } | Set-Content $tileList -Encoding UTF8
$thumbArgs = @('-ExecutionPolicy', 'Bypass', '-File', $thumbs, '-List', $tileList, '-Sheet', $keep, '-Cols', $cols, '-SheetCell', $cell, '-OutDir', $OutDir)
if (-not $Indexed) { $thumbArgs += '-Dense' }
& powershell.exe @thumbArgs | Out-Null

# 5) co-located list.txt: cell index -> source [xN]
$map = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $all.Count; $i++) {
    $r = $all[$i]; $tag = if ($r.count -gt 1) { " x$($r.count)" } else { '' }
    $map.Add(('{0:D3}' -f ($i + 1)) + "`t" + $r.path + $tag)
}
$map | Set-Content (Join-Path $OutDir 'list.txt') -Encoding UTF8

Remove-Item -Recurse -Force -LiteralPath $work -ErrorAction SilentlyContinue
$sheets = @(Get-ChildItem -LiteralPath $OutDir -Filter 'sheet*.png' -ErrorAction SilentlyContinue)
Write-Output ("MONTAGE_DIR=" + $OutDir)
Write-Output ("MONTAGE_SHEETS=" + $sheets.Count)
Write-Output ("MONTAGE_CELLS=" + $all.Count + " shown of " + $imgs.Count + " images (" + $imgRepCount + " distinct after dedup; random order; " + $cols + " cols; " + $vids.Count + " videos excluded)")
foreach ($s in $sheets) { Write-Output $s.FullName }
