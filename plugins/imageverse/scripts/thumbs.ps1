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
    -Plugin name    calling plugin/pack; namespaces the default temp dir (default 'misc')
    -OutDir dir     output dir (default %TEMP%\runes\<plugin>\thumbs)

  Prints THUMB_DIR, THUMB_COUNT, then one `<thumb>\t<source>` line per image
  (index-prefixed names keep order + avoid basename collisions).
#>
param(
    [string[]]$Path,
    [string]$List,
    [int]$Max = 1600,
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

$n = 0; $i = 0
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$lines = New-Object System.Collections.Generic.List[string]
foreach ($s in $srcs) {
    $i++
    try {
        if (-not (Test-Path -LiteralPath $s)) { continue }
        $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $s))
        $ms = New-Object IO.MemoryStream(, $bytes)
        $img = [Drawing.Image]::FromStream($ms)
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
        $bmp.Dispose(); $img.Dispose(); $ms.Dispose()
        $lines.Add($dest + "`t" + (Resolve-Path -LiteralPath $s).Path)
        $n++
    }
    catch { }
}
$sw.Stop()
Write-Output ('THUMB_COUNT=' + $n)
Write-Output ('THUMB_SECONDS=' + ('{0:0.0}' -f ($sw.Elapsed.TotalSeconds)))
foreach ($l in $lines) { Write-Output $l }
