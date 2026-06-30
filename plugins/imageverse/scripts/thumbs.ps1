<#
  thumbs - batch-downscale images to small thumbnails for cheap vision reads.
  The img / img-organize runes classify by CONTENT; reading full-res ultrawide
  screenshots is wasteful and trips the many-image request cap (2000px/side).
  Thumbnail first, then batch-read the thumbnails.

    -Path a,b,c     source image paths (repeatable)
    -List file      OR a file of newline-separated source paths
    -Max N          longest-side px (default 1600; aspect preserved, never upscales).
                    1600 stays legible for dense screenshot text yet under the
                    2000px/side many-image cap so thumbnails still batch.
    -Sheet N        TRIAGE mode for large still dumps: instead of one thumbnail per
                    image, tile N images per CONTACT SHEET (e.g. 25 -> a 5x5 grid),
                    each cell stamped with its GLOBAL 1-based index (= line number in
                    -List). Read ~ceil(total/N) sheets to bucket a big dump fast, then
                    refine ambiguous cells at full size. Emits SHEET_COUNT then
                    `<sheet>\t<startIdx>-<endIdx>` lines. (Off by default; 0.)
    -SheetCell N    per-cell longest-side px in -Sheet mode (default 360; 5 cols * 360
                    ~ 1800px, under the 2000px many-image cap).
    -VideoFrames N  for VIDEO inputs (mp4/mov/...): sample N frames evenly across the
                    clip and tile them into ONE contact-sheet thumbnail (default 12),
                    so a clip is classified from its content like a still. Needs
                    ffmpeg (+ffprobe) on PATH; without it, videos are skipped (a
                    THUMB_SKIP_VIDEO line is emitted) and the rune assigns them by
                    their time/geo cluster instead.
    -Plugin name    calling plugin/pack; namespaces the default temp dir (default 'misc')
    -OutDir dir     output dir (default %TEMP%\runes\<plugin>\thumbs)

  Prints THUMB_DIR, THUMB_COUNT (incl. video contact sheets), THUMB_VIDEOS, then
  one `<thumb>\t<source>` line per image (index-prefixed names keep order + avoid
  basename collisions). A video with no ffmpeg emits `THUMB_SKIP_VIDEO\t<source>`.
#>
param(
    [string[]]$Path,
    [string]$List,
    [int]$Max = 1600,
    [int]$Sheet = 0,
    [int]$SheetCell = 360,
    [int]$Cols = 0,
    [switch]$Dense,
    [int]$VideoFrames = 12,
    [string]$Plugin = 'misc',
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'
if (-not $OutDir) { $OutDir = Join-Path $env:TEMP "runes\$Plugin\thumbs" }

$srcs = New-Object System.Collections.Generic.List[string]
if ($Path) { foreach ($p in $Path) { if ($p) { $srcs.Add($p) } } }
if ($List -and (Test-Path $List)) { foreach ($l in Get-Content $List) { if ($l.Trim()) { $srcs.Add($l.Trim()) } } }
if ($srcs.Count -eq 0) { Write-Output 'THUMB_COUNT=0'; Write-Output 'THUMB_NOTE=no input paths (-Path or -List)'; return }

Add-Type -AssemblyName System.Drawing | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Output ('THUMB_DIR=' + $OutDir)

# Pick the square crop window centred on the BRIGHTEST region (not the geometric
# centre) so a fill-crop of a night/illumination photo keeps the lit subject instead
# of cropping to black sky. Returns @(srcX, srcY, side). Uses a tiny luminance map.
function Get-BrightCrop($img) {
    $W = $img.Width; $H = $img.Height; $side = [math]::Min($W, $H)
    $sl = 48.0 / [double][math]::Max($W, $H); if ($sl -gt 1) { $sl = 1 }
    $sw = [math]::Max(1, [int]($W * $sl)); $sh = [math]::Max(1, [int]($H * $sl))
    $sb = New-Object Drawing.Bitmap($sw, $sh)
    $sg = [Drawing.Graphics]::FromImage($sb); $sg.DrawImage($img, 0, 0, $sw, $sh); $sg.Dispose()
    if ($W -eq $H) {
        $s = 0.0; for ($yy = 0; $yy -lt $sh; $yy++) { for ($xx = 0; $xx -lt $sw; $xx++) { $p = $sb.GetPixel($xx, $yy); $s += 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B } }
        $sb.Dispose(); return @{ sx = 0; sy = 0; side = $side; bri = ($s / ($sw * $sh)) }
    }
    if ($W -gt $H) {
        $win = $sh; $col = New-Object 'double[]' $sw
        for ($xx = 0; $xx -lt $sw; $xx++) { $s = 0.0; for ($yy = 0; $yy -lt $sh; $yy++) { $p = $sb.GetPixel($xx, $yy); $s += 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B }; $col[$xx] = $s }
        $best = -1; $bestX = 0; $cur = 0.0
        for ($xx = 0; $xx -lt $sw; $xx++) { $cur += $col[$xx]; if ($xx -ge $win) { $cur -= $col[$xx - $win] }; if ($xx -ge ($win - 1) -and $cur -gt $best) { $best = $cur; $bestX = $xx - $win + 1 } }
        $sb.Dispose(); $sx = [int][math]::Round($bestX / $sl); if ($sx + $side -gt $W) { $sx = $W - $side }; if ($sx -lt 0) { $sx = 0 }
        return @{ sx = $sx; sy = 0; side = $side; bri = ($best / ($win * $win)) }
    }
    else {
        $win = $sw; $row = New-Object 'double[]' $sh
        for ($yy = 0; $yy -lt $sh; $yy++) { $s = 0.0; for ($xx = 0; $xx -lt $sw; $xx++) { $p = $sb.GetPixel($xx, $yy); $s += 0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B }; $row[$yy] = $s }
        $best = -1; $bestY = 0; $cur = 0.0
        for ($yy = 0; $yy -lt $sh; $yy++) { $cur += $row[$yy]; if ($yy -ge $win) { $cur -= $row[$yy - $win] }; if ($yy -ge ($win - 1) -and $cur -gt $best) { $best = $cur; $bestY = $yy - $win + 1 } }
        $sb.Dispose(); $sy = [int][math]::Round($bestY / $sl); if ($sy + $side -gt $H) { $sy = $H - $side }; if ($sy -lt 0) { $sy = 0 }
        return @{ sx = 0; sy = $sy; side = $side; bri = ($best / ($win * $win)) }
    }
}

# TRIAGE: tile many stills into index-stamped contact sheets (one read buckets N
# images). Each cell carries its GLOBAL 1-based index (= -List line) so a cell maps
# UNAMBIGUOUSLY back to its file. Off unless -Sheet > 0.
if ($Sheet -gt 0) {
    $imgExtsLocal = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')
    $cols = if ($Cols -gt 0) { $Cols } else { [int][math]::Ceiling([math]::Sqrt([double]$Sheet)) }
    $rows = [int][math]::Ceiling($Sheet / [double]$cols)
    # -Dense: zero gaps + no index badges -> packs far more per sheet for pure
    # eyeballing (you reference by grid POSITION, not a stamped number).
    $pad = if ($Dense) { 0 } else { 4 }
    $cell = $SheetCell
    $gw = $cols * $cell + ($cols + 1) * $pad
    $gh = $rows * $cell + ($rows + 1) * $pad
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $lines = New-Object System.Collections.Generic.List[string]
    $sheetNo = 0
    for ($base = 0; $base -lt $srcs.Count; $base += $Sheet) {
        $last = [math]::Min($base + $Sheet - 1, $srcs.Count - 1)
        $bmp = New-Object Drawing.Bitmap($gw, $gh)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.Clear([Drawing.Color]::FromArgb(20, 20, 20))
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $font = New-Object Drawing.Font('Consolas', 13, [Drawing.FontStyle]::Bold)
        for ($j = $base; $j -le $last; $j++) {
            $k = $j - $base; $idx = $j + 1
            $s = $srcs[$j]
            # NB: [int](a/b) in PowerShell ROUNDS (banker's), it does NOT truncate -
            # [int](5/8)=1, not 0 - so use [math]::Floor for the row, else cells stomp
            # each other and leave blanks. (Same applies anywhere a grid row is derived.)
            $r = [int][math]::Floor($k / $cols); $c = $k % $cols
            $x = $pad + $c * ($cell + $pad); $y = $pad + $r * ($cell + $pad)
            if (-not (Test-Path -LiteralPath $s)) { continue }
            if ($imgExtsLocal -notcontains [IO.Path]::GetExtension($s).ToLower()) { continue }
            try {
                $ms2 = New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $s).Path))
                $src = [Drawing.Image]::FromStream($ms2)
                # Downscale huge phone photos (20MP+) to a bounded working bitmap FIRST
                # (cheap Bilinear), then draw the SMALL copy into the cell. Drawing giant
                # sources repeatedly makes GDI+ SILENTLY stop drawing them after many
                # iterations (blank cells, no exception) - bounding the size avoids it.
                $img = $src; $tmpW = $null
                $cap = [math]::Max(1000, $cell * 3); $msd = [math]::Max($src.Width, $src.Height)
                if ($msd -gt $cap) {
                    $ws = $cap / [double]$msd; $ww = [int]($src.Width * $ws); $wh = [int]($src.Height * $ws)
                    $tmpW = New-Object Drawing.Bitmap($ww, $wh); $wg = [Drawing.Graphics]::FromImage($tmpW)
                    $wg.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::Bilinear
                    $wg.DrawImage($src, 0, 0, $ww, $wh); $wg.Dispose(); $img = $tmpW
                }
                if ($Dense) {
                    # COVER + center-crop: fill the whole square cell, gapless.
                    $side = [math]::Min($img.Width, $img.Height)
                    $sx = [int](($img.Width - $side) / 2); $sy = [int](($img.Height - $side) / 2)
                    $g.DrawImage($img, (New-Object Drawing.Rectangle($x, $y, $cell, $cell)), [int]$sx, [int]$sy, [int]$side, [int]$side, [Drawing.GraphicsUnit]::Pixel)
                }
                else {
                    # CONTAIN (no crop) - whole image visible, for cell-by-cell classification.
                    $scale = $cell / [math]::Max($img.Width, $img.Height); if ($scale -gt 1) { $scale = 1 }
                    $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
                    $g.DrawImage($img, ($x + [int](($cell - $w) / 2)), ($y + [int](($cell - $h) / 2)), $w, $h)
                }
                $src.Dispose(); if ($tmpW) { $tmpW.Dispose() }; $ms2.Dispose()
            }
            catch {}
            if (-not $Dense) {
                $label = '{0:D3}' -f $idx
                $tsz = $g.MeasureString($label, $font)
                $g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(220, 0, 0, 0))), $x, $y, $tsz.Width + 6, $tsz.Height + 2)
                $g.DrawString($label, $font, [Drawing.Brushes]::Yellow, $x + 3, $y + 1)
            }
        }
        $font.Dispose(); $g.Dispose()
        $sheetNo++
        $dest = Join-Path $OutDir ('sheet{0:D3}.png' -f $sheetNo)
        $bmp.Save($dest, [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
        $lines.Add($dest + "`t" + ($base + 1) + "-" + ($last + 1))
    }
    $sw.Stop()
    Write-Output ("SHEET_COUNT=$sheetNo")
    Write-Output ("SHEET_PERSHEET=$Sheet")
    Write-Output ("SHEET_SECONDS=" + ('{0:0.0}' -f $sw.Elapsed.TotalSeconds))
    foreach ($l in $lines) { Write-Output $l }
    return
}

$videoExts = @('.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp', '.3g2', '.wmv', '.mpg', '.mpeg', '.mts', '.m2ts')
$audioExts = @('.mp3', '.m4a', '.wav', '.aac', '.ogg', '.oga', '.opus', '.flac', '.wma', '.amr', '.aiff', '.aif')
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue)
$ffprobe = (Get-Command ffprobe -ErrorAction SilentlyContinue)

# Build a CONTACT SHEET for a video: sample $Frames frames evenly across the whole
# clip (so the grid represents the entire video, not just the opening title card)
# and tile them into ONE bitmap the model reads like any still. Returns a Bitmap
# (full-res grid; the caller downscales + index-stamps it via the shared path) or
# $null when ffmpeg can't decode it. Falls back to ffmpeg's own thumbnail+tile
# single pass when ffprobe (duration) is unavailable.
function New-VideoContactSheet {
    param($VideoPath, [int]$Frames, [int]$Cols, $WorkRoot)
    $tmp = Join-Path $WorkRoot ('_vf_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $inv = [Globalization.CultureInfo]::InvariantCulture
    try {
        $dur = 0.0
        if ($ffprobe) {
            $d = & $ffprobe.Source -v error -show_entries format=duration -of csv=p=0 -- "$VideoPath" 2>$null
            [double]::TryParse(("$($d | Select-Object -First 1)").Trim(), [Globalization.NumberStyles]::Float, $inv, [ref]$dur) | Out-Null
        }
        $framePaths = @()
        if ($dur -gt 0.2) {
            for ($k = 0; $k -lt $Frames; $k++) {
                $t = $dur * ($k + 0.5) / $Frames
                $fp = Join-Path $tmp ('{0:D3}.png' -f $k)
                & $ffmpeg.Source -nostdin -loglevel error -y -ss ([string]::Format($inv, '{0:0.000}', $t)) -i "$VideoPath" -frames:v 1 -q:v 3 -- "$fp" 2>$null
                if (Test-Path -LiteralPath $fp) { $framePaths += $fp }
            }
        }
        $rows = [int][math]::Ceiling($Frames / [double]$Cols)
        if ($framePaths.Count -eq 0) {
            # No per-timestamp frames (no ffprobe / odd container): let ffmpeg pick
            # representative frames and tile them itself in one pass.
            $grid = Join-Path $tmp 'grid.png'
            & $ffmpeg.Source -nostdin -loglevel error -y -i "$VideoPath" -frames:v 1 -vf "thumbnail=100,tile=${Cols}x${rows}" -- "$grid" 2>$null
            if (-not (Test-Path -LiteralPath $grid)) { return $null }
            return [Drawing.Image]::FromStream((New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes($grid))))
        }
        $cells = @()
        foreach ($fp in $framePaths) {
            try { $cells += [Drawing.Image]::FromStream((New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes($fp)))) } catch {}
        }
        if ($cells.Count -eq 0) { return $null }
        $cellMax = 420
        $aw = $cells[0].Width; $ah = $cells[0].Height
        $cs = $cellMax / [math]::Max($aw, $ah); if ($cs -gt 1) { $cs = 1 }
        $cw = [int]($aw * $cs); $ch = [int]($ah * $cs); $pad = 4
        $gw = $Cols * $cw + ($Cols + 1) * $pad
        $gh = $rows * $ch + ($rows + 1) * $pad
        $bmp = New-Object Drawing.Bitmap($gw, $gh)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.Clear([Drawing.Color]::Black)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        for ($idx = 0; $idx -lt $cells.Count; $idx++) {
            $r = [int][math]::Floor($idx / $Cols); $c = $idx % $Cols
            $x = $pad + $c * ($cw + $pad); $y = $pad + $r * ($ch + $pad)
            $g.DrawImage($cells[$idx], $x, $y, $cw, $ch)
        }
        $g.Dispose(); foreach ($cimg in $cells) { $cimg.Dispose() }
        return $bmp
    }
    catch { return $null }
    finally { Remove-Item -Recurse -Force -LiteralPath $tmp -ErrorAction SilentlyContinue }
}

$n = 0; $i = 0; $nv = 0
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$lines = New-Object System.Collections.Generic.List[string]
foreach ($s in $srcs) {
    $i++
    try {
        if (-not (Test-Path -LiteralPath $s)) { continue }
        $ms = $null; $isVid = $false
        $extLc = [IO.Path]::GetExtension($s).ToLower()
        # Audio has no frames - there is nothing to thumbnail. Flag it so the rune
        # knows to group it by time/cluster (never by content) and moves on.
        if ($audioExts -contains $extLc) { Write-Output ("THUMB_SKIP_AUDIO`t" + (Resolve-Path -LiteralPath $s).Path); continue }
        if ($videoExts -contains $extLc) {
            $isVid = $true
            $rp = (Resolve-Path -LiteralPath $s).Path
            if (-not $ffmpeg) { Write-Output ("THUMB_SKIP_VIDEO`t" + $rp); continue }
            # ONE contact-sheet bitmap stands in for the clip; the shared downscale +
            # index-stamp + save below treats it exactly like a still thumbnail.
            $img = New-VideoContactSheet -VideoPath $rp -Frames $VideoFrames -Cols 4 -WorkRoot $OutDir
            if (-not $img) { Write-Output ("THUMB_SKIP_VIDEO`t" + $rp); continue }
        }
        else {
            $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $s))
            $ms = New-Object IO.MemoryStream(, $bytes)
            $img = [Drawing.Image]::FromStream($ms)
        }
        $scale = $Max / [math]::Max($img.Width, $img.Height)
        if ($scale -gt 1) { $scale = 1 }   # never upscale
        $w = [int][math]::Round($img.Width * $scale)
        $h = [int][math]::Round($img.Height * $scale)
        $bmp = New-Object Drawing.Bitmap($w, $h)
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, $w, $h)
        # STAMP the index badge (top-left): the model maps each thumbnail to its
        # source by the VISIBLE number, not by read order - kills the off-by-one
        # mislabel when many thumbnails are read in one message.
        $label = '{0:D3}' -f $i
        $fs2 = [single]([math]::Max(16, [math]::Round($h * 0.05)))
        $font = New-Object Drawing.Font('Consolas', $fs2, [Drawing.FontStyle]::Bold)
        $tsz = $g.MeasureString($label, $font)
        $g.FillRectangle((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(220, 0, 0, 0))), 0, 0, $tsz.Width + 8, $tsz.Height + 4)
        $g.DrawString($label, $font, [Drawing.Brushes]::Yellow, 4, 1)
        $font.Dispose(); $g.Dispose()
        $name = ('{0:D3}_' -f $i) + [IO.Path]::GetFileNameWithoutExtension($s) + '.png'
        $dest = Join-Path $OutDir $name
        $bmp.Save($dest, [Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose(); $img.Dispose(); if ($ms) { $ms.Dispose() }
        $lines.Add($dest + "`t" + (Resolve-Path -LiteralPath $s).Path)
        $n++; if ($isVid) { $nv++ }
    }
    catch { }
}
$sw.Stop()
Write-Output ('THUMB_COUNT=' + $n)
Write-Output ('THUMB_VIDEOS=' + $nv)
Write-Output ('THUMB_SECONDS=' + ('{0:0.0}' -f ($sw.Elapsed.TotalSeconds)))
foreach ($l in $lines) { Write-Output $l }
