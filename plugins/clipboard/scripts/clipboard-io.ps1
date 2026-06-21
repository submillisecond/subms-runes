<#
  clipboard-io - shared clipboard I/O for the clipboard pack's runes.
    read           (default) capture the clipboard (files / image / text) and
                   print a CLIP_KIND summary. TEXT is streamed to stdout between
                   -----BEGIN/END CLIP TEXT----- markers (no file). Only an IMAGE
                   is written to a file (%TEMP%\runes\clipboard\), since the Read
                   tool needs a path; FILES report their original paths.
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
# Emit UTF-8 so Unicode/emoji reach the caller intact (the default OEM console
# codepage turns them into `??`). Text is streamed to stdout, not a file.
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$OutputEncoding = [Text.Encoding]::UTF8
$dir = Join-Path $env:TEMP 'runes\clipboard'

if ($Mode -eq 'write') {
    if (-not $Path -or -not (Test-Path $Path)) { Write-Output 'CLIP_WRITE=error: missing or unreadable -Path'; exit 1 }
    # An image file -> put the IMAGE on the clipboard (needs STA). Otherwise text.
    if ([IO.Path]::GetExtension($Path).ToLower() -in '.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff') {
        Add-Type -AssemblyName System.Windows.Forms, System.Drawing | Out-Null
        $bytes = [IO.File]::ReadAllBytes($Path)
        $ms = New-Object IO.MemoryStream(, $bytes)
        $img = [System.Drawing.Image]::FromStream($ms)
        try { [System.Windows.Forms.Clipboard]::SetImage($img); Write-Output 'CLIP_WRITE=ok'; Write-Output 'CLIP_KIND=image' }
        finally { $img.Dispose(); $ms.Dispose() }
        return
    }
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

# 2) An image (screenshot / copied picture) - save as PNG. Only IMAGES need a file:
# the Read tool renders an image from a path, it cannot take inline bytes.
$img = Get-Clipboard -Format Image
if ($img) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    # Prune stale bridge files (>24h) so this TEMP dir does not grow without bound.
    # Only the ephemeral capture/ocr/copy temps live here - saved clips (Downloads),
    # snippets + history (LOCALAPPDATA) are elsewhere and untouched.
    Get-ChildItem $dir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-24) } |
        Remove-Item -Force -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.Drawing | Out-Null
    $p = Join-Path $dir ("clip-$stamp.png")
    $img.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output 'CLIP_KIND=image'
    Write-Output ('CLIP_PATH=' + $p)
    return
}

# 3) Text (plain, or rich text flattened to plain) - STREAMED to stdout, no file.
# The full content lives between the BEGIN/END markers; the caller reads it inline.
$text = Get-Clipboard -Raw
if ($text -and $text.Trim().Length -gt 0) {
    Write-Output 'CLIP_KIND=text'
    Write-Output ('CLIP_BYTES=' + [Text.Encoding]::UTF8.GetByteCount($text))
    Write-Output ('CLIP_LINES=' + (($text -split "`n").Count))
    # Flag credentials so the rune can warn before the content is surfaced.
    . (Join-Path $PSScriptRoot 'secret-scan.ps1')
    $sec = Find-Secrets $text
    if ($sec.count -gt 0) { Write-Output ('CLIP_SECRETS=' + ($sec.types -join ',')); Write-Output ('CLIP_SECRET_COUNT=' + $sec.count) }
    Write-Output '-----BEGIN CLIP TEXT-----'
    [Console]::Out.Write($text)
    if (-not $text.EndsWith("`n")) { [Console]::Out.Write("`n") }
    Write-Output '-----END CLIP TEXT-----'
    return
}

Write-Output 'CLIP_KIND=empty'
