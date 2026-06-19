<#
  clipboard-io - shared clipboard I/O for the clipboard pack's runes.
    read           (default) capture the clipboard (files / image / text) and
                   print a CLIP_KIND summary; payloads are written to %TEMP%\runes-clip\.
    write -Path f  set the clipboard to the UTF-8 text in file f.
  STA is required: powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File clipboard-io.ps1 <mode> [-Path f]
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet('read', 'write')]
    [string]$Mode = 'read',
    [string]$Path
)
$ErrorActionPreference = 'SilentlyContinue'
$dir = Join-Path $env:TEMP 'runes-clip'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

if ($Mode -eq 'write') {
    if (-not $Path -or -not (Test-Path $Path)) { Write-Output 'CLIP_WRITE=error: missing or unreadable -Path'; exit 1 }
    $content = Get-Content -Raw -Path $Path
    Set-Clipboard -Value $content
    Write-Output 'CLIP_WRITE=ok'
    Write-Output ('CLIP_BYTES=' + [Text.Encoding]::UTF8.GetByteCount($content))
    return
}

# read
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'

# 1) Copied files (Explorer) - report original paths, read them in place.
$files = Get-Clipboard -Format FileDropList
if ($files) {
    Write-Output 'CLIP_KIND=files'
    Write-Output ('CLIP_COUNT=' + @($files).Count)
    foreach ($f in $files) { Write-Output $f }
    return
}

# 2) An image (screenshot / copied picture) - save as PNG.
$img = Get-Clipboard -Format Image
if ($img) {
    Add-Type -AssemblyName System.Drawing | Out-Null
    $p = Join-Path $dir ("clip-$stamp.png")
    $img.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output 'CLIP_KIND=image'
    Write-Output ('CLIP_PATH=' + $p)
    return
}

# 3) Text (plain, or rich text flattened to plain).
$text = Get-Clipboard -Raw
if ($text -and $text.Trim().Length -gt 0) {
    $p = Join-Path $dir ("clip-$stamp.txt")
    Set-Content -Path $p -Value $text -Encoding UTF8
    Write-Output 'CLIP_KIND=text'
    Write-Output ('CLIP_PATH=' + $p)
    Write-Output ('CLIP_BYTES=' + [Text.Encoding]::UTF8.GetByteCount($text))
    Write-Output ('CLIP_LINES=' + (($text -split "`n").Count))
    Write-Output '----- preview -----'
    ($text -split "`n" | Select-Object -First 30) -join "`n"
    return
}

Write-Output 'CLIP_KIND=empty'
