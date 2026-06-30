<#
  phash - PERCEPTUAL hashing (dHash) for the imageverse plugin. SHA1 sees a
  WhatsApp re-encode as a different file; a perceptual hash does not - so this is how
  we (a) ROUTE a re-shared image to the album its original already lives in, and
  (b) GROUP near-duplicate shares within a dump so they classify once.

  dHash: image -> 9x8 grayscale -> compare adjacent pixels -> 64-bit hash (16 hex).
  Similarity = Hamming distance (bits differing). Re-encodes typically stay <= ~6;
  default match threshold is 10.

  MODES (Windows: powershell ... -File phash.ps1 <mode> ...):
    hash  -List <paths-file> | -Tsv <scan.tsv>   -OutFile <out.tsv>
          compute dHash per file -> `<dhash>\t<path>` lines (+ to -OutFile).
    match -Query <hash.tsv> -Ref <hash.tsv> [-MaxDist 10]
          for each query, nearest ref within MaxDist ->
          `MATCH\t<queryPath>\t<refPath>\t<dist>`  or  `NOMATCH\t<queryPath>`.
          (Route a dump: Query=dump hashes, Ref=already-organized library hashes;
          the ref path's PARENT folder is the album to route into.)
    group -In <hash.tsv> [-MaxDist 6]
          collapse near-duplicates within one set ->
          `GROUP\t<id>\t<count>\t<comma-separated paths>` (singletons included).

  Emits PHASH_* status lines. Read-only; never moves/modifies images.
#>
param(
    [Parameter(Position = 0)][string]$Mode = 'hash',
    [string]$List,
    [string]$Tsv,
    [string]$OutFile,
    [string]$Query,
    [string]$Ref,
    [string]$In,
    [int]$MaxDist = 10,
    [int]$VideoFrames = 4
)
$ErrorActionPreference = 'Stop'
try { Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null } catch {}
$script:FFMPEG = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
$script:FFPROBE = (Get-Command ffprobe -ErrorAction SilentlyContinue).Source
$vext = @('.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp', '.3g2', '.wmv', '.mpg', '.mpeg', '.mts', '.m2ts')

$nib = @(0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4)  # popcount of a nibble 0..15
function Hex-Hamming($a, $b) {
    # Different lengths = different KINDS of hash (16-hex image dHash vs an N*16-hex
    # video frame-signature) - return -1 (incomparable) so videos never match images.
    if ($a.Length -ne $b.Length) { return -1 }
    $d = 0
    for ($i = 0; $i -lt $a.Length; $i++) { $d += $nib[([Convert]::ToInt32([string]$a[$i], 16) -bxor [Convert]::ToInt32([string]$b[$i], 16))] }
    $d
}
function Get-DHash($path) {
    try {
        $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path))
        $ms = New-Object IO.MemoryStream(, $bytes)
        $img = [Drawing.Image]::FromStream($ms)
        $bmp = New-Object Drawing.Bitmap(9, 8)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, 9, 8); $g.Dispose()
        $hex = ''; $val = 0; $cnt = 0
        for ($y = 0; $y -lt 8; $y++) {
            for ($x = 0; $x -lt 8; $x++) {
                $p1 = $bmp.GetPixel($x, $y); $p2 = $bmp.GetPixel($x + 1, $y)
                $l1 = 0.299 * $p1.R + 0.587 * $p1.G + 0.114 * $p1.B
                $l2 = 0.299 * $p2.R + 0.587 * $p2.G + 0.114 * $p2.B
                $bit = if ($l1 -lt $l2) { 1 } else { 0 }
                $val = (($val -shl 1) -bor $bit); $cnt++
                if ($cnt -eq 4) { $hex += ('{0:x}' -f $val); $val = 0; $cnt = 0 }
            }
        }
        $bmp.Dispose(); $img.Dispose(); $ms.Dispose()
        return $hex
    }
    catch { return $null }
}
function Get-VideoSig($path, $frames) {
    # A video's perceptual hash = dHash of N frames sampled evenly across the clip,
    # concatenated (frames * 16 hex). Robust to re-encode/resize (WhatsApp re-shares),
    # and a DIFFERENT length from an image hash so the two never cross-match. Needs
    # ffmpeg; ffprobe gives duration for even sampling (else fixed frame steps).
    if (-not $script:FFMPEG) { return $null }
    $tmp = Join-Path $env:TEMP ("phv_" + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $dur = $null
    if ($script:FFPROBE) { $dur = (& $script:FFPROBE -v error -show_entries format=duration -of csv=p=0 "$path" 2>$null) }
    $sig = ''
    for ($k = 0; $k -lt $frames; $k++) {
        $fo = Join-Path $tmp "f$k.png"
        if ($dur -and ("$dur" -match '^[0-9.]+$')) {
            $t = [double]$dur * ($k + 0.5) / $frames
            & $script:FFMPEG -nostdin -loglevel error -y -ss $t -i "$path" -frames:v 1 -q:v 3 $fo 2>$null | Out-Null
        }
        else {
            & $script:FFMPEG -nostdin -loglevel error -y -i "$path" -vf ("select=eq(n\," + ($k * 15) + ")") -frames:v 1 $fo 2>$null | Out-Null
        }
        $fh = if (Test-Path -LiteralPath $fo) { Get-DHash $fo } else { $null }
        $sig += if ($fh) { $fh } else { '0000000000000000' }
    }
    Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue
    if ($sig -match '^0+$') { return $null }   # nothing decoded
    return $sig
}
function Load-Hashes($file) {
    $a = New-Object System.Collections.Generic.List[object]
    foreach ($l in (Get-Content $file)) {
        if (-not $l.Trim()) { continue }
        $c = $l -split "`t"; if ($c.Count -lt 2) { continue }
        $a.Add([pscustomobject]@{ hash = $c[0].Trim(); path = $c[1].Trim() })
    }
    $a
}

switch ($Mode.ToLower()) {
    'hash' {
        $paths = @()
        if ($List -and (Test-Path $List)) { $paths = @(Get-Content $List | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }) }
        elseif ($Tsv -and (Test-Path $Tsv)) { $paths = @(Get-Content $Tsv | Where-Object { $_.Trim() } | ForEach-Object { ($_ -split "`t")[3] } | Where-Object { $_ }) }
        else { Write-Output 'PHASH_ERROR=hash needs -List or -Tsv'; exit 1 }
        $lines = New-Object System.Collections.Generic.List[string]
        $ok = 0; $vid = 0; $vskip = 0
        foreach ($p in $paths) {
            if (-not (Test-Path -LiteralPath $p)) { continue }
            $ext = [IO.Path]::GetExtension($p).ToLower()
            if ($vext -contains $ext) {
                if (-not $script:FFMPEG) { $vskip++; continue }
                $h = Get-VideoSig $p $VideoFrames
                if ($h) { $vid++ }
            }
            else { $h = Get-DHash $p }
            if ($h) { $lines.Add($h + "`t" + $p); $ok++ }
        }
        if ($OutFile) { $lines | Set-Content -Path $OutFile -Encoding UTF8 }
        Write-Output ("PHASH_COUNT=$ok")
        if ($vid -gt 0) { Write-Output ("PHASH_VIDEOS=$vid (frame-signature, $VideoFrames frames)") }
        if ($vskip -gt 0) { Write-Output ("PHASH_NOTE=$vskip video(s) skipped - ffmpeg not found (run deps)") }
        if ($OutFile) { Write-Output ("PHASH_OUTFILE=$OutFile") }
        foreach ($l in $lines) { Write-Output $l }
    }
    'match' {
        if (-not ($Query -and $Ref)) { Write-Output 'PHASH_ERROR=match needs -Query and -Ref'; exit 1 }
        $q = Load-Hashes $Query; $r = Load-Hashes $Ref
        $matched = 0; $out = New-Object System.Collections.Generic.List[string]
        foreach ($qi in $q) {
            $best = $null; $bestD = 999
            foreach ($ri in $r) {
                $d = Hex-Hamming $qi.hash $ri.hash
                if ($d -lt 0) { continue }   # incomparable (image vs video)
                if ($d -lt $bestD) { $bestD = $d; $best = $ri; if ($d -eq 0) { break } }
            }
            # video sigs are N*16 hex - scale the threshold so the per-frame tolerance matches images'
            $eff = $MaxDist * [math]::Max(1, [int]($qi.hash.Length / 16))
            if ($best -and $bestD -le $eff) { $out.Add("MATCH`t$($qi.path)`t$($best.path)`t$bestD"); $matched++ }
            else { $out.Add("NOMATCH`t$($qi.path)") }
        }
        Write-Output ("PHASH_MATCHED=$matched of $($q.Count); MaxDist=$MaxDist")
        foreach ($l in $out) { Write-Output $l }
    }
    'group' {
        if ($MaxDist -eq 10) { $MaxDist = 6 }   # tighter default for within-set dedup
        $items = Load-Hashes $In
        $groups = New-Object System.Collections.Generic.List[object]   # each: {rep, members[]}
        foreach ($it in $items) {
            $placed = $false
            $eff = $MaxDist * [math]::Max(1, [int]($it.hash.Length / 16))   # scale for video sigs
            foreach ($grp in $groups) {
                $hd = Hex-Hamming $it.hash $grp.rep
                if ($hd -ge 0 -and $hd -le $eff) { $grp.members.Add($it.path); $placed = $true; break }
            }
            if (-not $placed) { $m = New-Object System.Collections.Generic.List[string]; $m.Add($it.path); $groups.Add([pscustomobject]@{ rep = $it.hash; members = $m }) }
        }
        $dupGroups = @($groups | Where-Object { $_.members.Count -gt 1 })
        Write-Output ("PHASH_GROUPS=$($groups.Count); dup-groups=$($dupGroups.Count); items=$($items.Count)")
        $id = 0
        foreach ($grp in $groups) { $id++; Write-Output ("GROUP`t$id`t$($grp.members.Count)`t" + ($grp.members -join ',')) }
    }
    default { Write-Output "PHASH_ERROR=unknown mode '$Mode' (hash|match|group)" }
}
