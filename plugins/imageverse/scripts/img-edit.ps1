<#
  img-edit - apply deterministic edits to an image and write a NEW image.
  Zero-dependency Windows backend over System.Drawing (GDI+).

  The original is never modified (the input is read fully into memory first, so
  even -Out == -In is a safe overwrite, not a self-lock). All COORDINATE ops
  (-Redact / -Box / -Text / -Crop) use ORIGINAL-image pixel space - the same
  pixels the Read tool shows the model - and are applied BEFORE the geometric
  ops. Fixed order: redact -> box -> text -> crop -> resize/scale -> rotate ->
  flip -> grayscale -> save.

  Params (only -In/-Out are needed; the *able ones repeat):
    -In   path         source image (png/jpg/jpeg/bmp/gif/tiff)
    -Out  path         destination; pixel format inferred from the extension
    -Redact "X,Y,W,H"  fill a rectangle (default black); repeatable
    -Box    "X,Y,W,H[,#RRGGBB[,T]]"  outline a rectangle (T = thickness px); repeatable
    -Text   "X,Y,SIZE,#RRGGBB,the text"  draw text (text may contain commas); repeatable
    -Crop   "X,Y,W,H"  crop to this rectangle (clamped to bounds)
    -Resize "WxH"      resize; put 0/auto on one side to keep aspect (e.g. 800x0)
    -Scale  f          scale by factor (0.5 = half); ignored when -Resize is given
    -Rotate deg        rotate clockwise; 90/180/270 are lossless RotateFlip
    -Flip   h|v        mirror horizontally or vertically
    -Grayscale         desaturate (luma ColorMatrix)
    -RedactColor #RRGGBB  fill colour for -Redact (default #000000)
    -Quality N         JPEG quality 1-100 (default 90)
  Prints EDIT_OUT / EDIT_FROM / EDIT_SIZE / EDIT_OPS / EDIT_BYTES, or EDIT_ERROR.
#>
param(
    [string]$In,
    [string]$Out,
    [string[]]$Redact,
    [string[]]$Box,
    [string[]]$Text,
    [string]$Crop,
    [string]$Resize,
    [double]$Scale = 0,
    [double]$Rotate = 0,
    [string]$Flip,
    [switch]$Grayscale,
    [string]$RedactColor = '#000000',
    [int]$Quality = 90
)
$ErrorActionPreference = 'Stop'

try {
    if (-not $In -or -not (Test-Path -LiteralPath $In)) { Write-Output "EDIT_ERROR=input not found: $In"; exit 1 }
    if (-not $Out) { Write-Output 'EDIT_ERROR=missing -Out'; exit 1 }
    Add-Type -AssemblyName System.Drawing | Out-Null

    # GDI+ Image.FromFile keeps the file locked for the object's lifetime, which
    # blocks an in-place overwrite. Read the bytes first, then detach into a
    # standalone Bitmap so the source handle is released immediately.
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $In))
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    $loaded = [System.Drawing.Image]::FromStream($ms)
    $img = New-Object System.Drawing.Bitmap($loaded)
    $loaded.Dispose(); $ms.Dispose()

    $ops = New-Object System.Collections.Generic.List[string]

    function Get-HexColor([string]$s, $fallback) {
        if (-not $s) { return $fallback }
        $h = $s.TrimStart('#')
        if ($h.Length -eq 6) {
            return [System.Drawing.Color]::FromArgb(
                [Convert]::ToInt32($h.Substring(0, 2), 16),
                [Convert]::ToInt32($h.Substring(2, 2), 16),
                [Convert]::ToInt32($h.Substring(4, 2), 16))
        }
        return $fallback
    }
    function Get-Ints([string]$csv, [int]$n) {
        $p = $csv.Split(',')
        if ($p.Count -lt $n) { return $null }
        return @($p[0..($n - 1)] | ForEach-Object { [int]$_.Trim() })
    }

    # --- annotations, in original pixel space ---
    if ($Redact -or $Box -or $Text) {
        $g = [System.Drawing.Graphics]::FromImage($img)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
        foreach ($r in @($Redact)) {
            if (-not $r) { continue }
            $c = Get-Ints $r 4; if (-not $c) { continue }
            $br = New-Object System.Drawing.SolidBrush((Get-HexColor $RedactColor ([System.Drawing.Color]::Black)))
            $g.FillRectangle($br, $c[0], $c[1], $c[2], $c[3]); $br.Dispose(); $ops.Add('redact')
        }
        foreach ($b in @($Box)) {
            if (-not $b) { continue }
            $p = $b.Split(','); $c = Get-Ints $b 4; if (-not $c) { continue }
            $col = if ($p.Count -ge 5) { Get-HexColor $p[4] ([System.Drawing.Color]::Red) } else { [System.Drawing.Color]::Red }
            $t = if ($p.Count -ge 6) { [int]$p[5].Trim() } else { 3 }
            $pen = New-Object System.Drawing.Pen($col, $t)
            $g.DrawRectangle($pen, $c[0], $c[1], $c[2], $c[3]); $pen.Dispose(); $ops.Add('box')
        }
        foreach ($t in @($Text)) {
            if (-not $t) { continue }
            $p = $t -split ',', 5; if ($p.Count -lt 5) { continue }
            $col = Get-HexColor $p[3] ([System.Drawing.Color]::Red)
            $font = New-Object System.Drawing.Font('Segoe UI', [single]$p[2].Trim(), [System.Drawing.GraphicsUnit]::Pixel)
            $br = New-Object System.Drawing.SolidBrush($col)
            $g.DrawString($p[4], $font, $br, [single]([int]$p[0].Trim()), [single]([int]$p[1].Trim()))
            $font.Dispose(); $br.Dispose(); $ops.Add('text')
        }
        $g.Dispose()
    }

    # --- crop (clamped to bounds) ---
    if ($Crop) {
        $c = Get-Ints $Crop 4
        if ($c) {
            $x = [math]::Max(0, $c[0]); $y = [math]::Max(0, $c[1])
            $w = [math]::Min($c[2], $img.Width - $x); $h = [math]::Min($c[3], $img.Height - $y)
            if ($w -gt 0 -and $h -gt 0) {
                $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
                $cropped = $img.Clone($rect, $img.PixelFormat)
                $img.Dispose(); $img = $cropped; $ops.Add('crop')
            }
        }
    }

    # --- resize / scale ---
    $newW = 0; $newH = 0
    if ($Resize) {
        $m = $Resize.ToLower().Split('x')
        $wv = if ($m[0].Trim() -in @('', 'auto')) { 0 } else { [int]$m[0].Trim() }
        $hv = if ($m.Count -lt 2 -or $m[1].Trim() -in @('', 'auto')) { 0 } else { [int]$m[1].Trim() }
        if ($wv -gt 0 -and $hv -le 0) { $hv = [int][math]::Round($img.Height * ($wv / $img.Width)) }
        elseif ($hv -gt 0 -and $wv -le 0) { $wv = [int][math]::Round($img.Width * ($hv / $img.Height)) }
        $newW = $wv; $newH = $hv
    }
    elseif ($Scale -gt 0) {
        $newW = [int][math]::Round($img.Width * $Scale); $newH = [int][math]::Round($img.Height * $Scale)
    }
    if ($newW -gt 0 -and $newH -gt 0) {
        $dst = New-Object System.Drawing.Bitmap($newW, $newH)
        $g = [System.Drawing.Graphics]::FromImage($dst)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.DrawImage($img, 0, 0, $newW, $newH)
        $g.Dispose(); $img.Dispose(); $img = $dst; $ops.Add('resize')
    }

    # --- rotate ---
    if ($Rotate -ne 0) {
        $deg = (($Rotate % 360) + 360) % 360
        if ($deg -in @(90, 180, 270)) {
            $rf = switch ($deg) { 90 { 'Rotate90FlipNone' } 180 { 'Rotate180FlipNone' } 270 { 'Rotate270FlipNone' } }
            $img.RotateFlip([System.Drawing.RotateFlipType]::$rf); $ops.Add("rotate$deg")
        }
        else {
            $rad = $deg * [math]::PI / 180
            $cos = [math]::Abs([math]::Cos($rad)); $sin = [math]::Abs([math]::Sin($rad))
            $nw = [int][math]::Ceiling($img.Width * $cos + $img.Height * $sin)
            $nh = [int][math]::Ceiling($img.Width * $sin + $img.Height * $cos)
            $dst = New-Object System.Drawing.Bitmap($nw, $nh)
            $g = [System.Drawing.Graphics]::FromImage($dst)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.TranslateTransform($nw / 2, $nh / 2)
            $g.RotateTransform([single]$deg)
            $g.TranslateTransform(-$img.Width / 2, -$img.Height / 2)
            $g.DrawImage($img, 0, 0)
            $g.Dispose(); $img.Dispose(); $img = $dst; $ops.Add("rotate$([int]$deg)")
        }
    }

    # --- flip ---
    if ($Flip) {
        switch ($Flip.ToLower()) {
            'h' { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX); $ops.Add('flipH') }
            'v' { $img.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipY); $ops.Add('flipV') }
        }
    }

    # --- grayscale ---
    if ($Grayscale) {
        $dst = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
        $g = [System.Drawing.Graphics]::FromImage($dst)
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix00 = 0.299; $cm.Matrix01 = 0.299; $cm.Matrix02 = 0.299
        $cm.Matrix10 = 0.587; $cm.Matrix11 = 0.587; $cm.Matrix12 = 0.587
        $cm.Matrix20 = 0.114; $cm.Matrix21 = 0.114; $cm.Matrix22 = 0.114
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $rect = New-Object System.Drawing.Rectangle(0, 0, $img.Width, $img.Height)
        $g.DrawImage($img, $rect, 0, 0, $img.Width, $img.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $g.Dispose(); $ia.Dispose(); $img.Dispose(); $img = $dst; $ops.Add('grayscale')
    }

    # --- save ---
    $full = [System.IO.Path]::GetFullPath($Out)
    $outDir = [System.IO.Path]::GetDirectoryName($full)
    if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
    $ext = [System.IO.Path]::GetExtension($full).ToLower().TrimStart('.')
    switch -Regex ($ext) {
        '^(jpg|jpeg)$' {
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
            $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $q = [math]::Max(1, [math]::Min(100, $Quality))
            $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$q)
            # JPEG has no alpha; flatten onto white so transparency does not go black.
            $flat = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
            $g = [System.Drawing.Graphics]::FromImage($flat)
            $g.Clear([System.Drawing.Color]::White); $g.DrawImage($img, 0, 0); $g.Dispose()
            $flat.Save($full, $codec, $ep); $flat.Dispose()
        }
        '^bmp$' { $img.Save($full, [System.Drawing.Imaging.ImageFormat]::Bmp) }
        '^gif$' { $img.Save($full, [System.Drawing.Imaging.ImageFormat]::Gif) }
        '^(tif|tiff)$' { $img.Save($full, [System.Drawing.Imaging.ImageFormat]::Tiff) }
        default { $img.Save($full, [System.Drawing.Imaging.ImageFormat]::Png) }
    }

    $finalW = $img.Width; $finalH = $img.Height
    $img.Dispose()
    Write-Output ('EDIT_OUT=' + $full)
    Write-Output ('EDIT_FROM=' + (Resolve-Path -LiteralPath $In))
    Write-Output ('EDIT_SIZE=' + $finalW + 'x' + $finalH)
    Write-Output ('EDIT_OPS=' + (@($ops) -join ','))
    Write-Output ('EDIT_BYTES=' + (Get-Item -LiteralPath $full).Length)
}
catch {
    Write-Output ('EDIT_ERROR=' + $_.Exception.Message)
    exit 1
}
