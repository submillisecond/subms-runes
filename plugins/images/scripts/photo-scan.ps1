<#
  photo-scan - list image files in a folder with a sortable date (EXIF
  DateTimeOriginal, else file modified time) and, optionally, a content hash for
  duplicate detection.
    -Dir PATH    folder to scan (required)
    -Recurse     include subfolders
    -Hash        also emit a SHA1 of each file (for dedup)
  Output:
    PHOTO_DIR=<resolved dir>
    PHOTO_COUNT=<n>
    then one TSV line per file:  <yyyy-MM-dd HH:mm:ss> \t <size-bytes> \t <sha1-or-empty> \t <path>
  The date is EXIF DateTimeOriginal when present, else the file's LastWriteTime.
#>
param(
    [Parameter(Mandatory)][string]$Dir,
    [switch]$Recurse,
    [switch]$Hash
)
$ErrorActionPreference = 'SilentlyContinue'
if (-not (Test-Path $Dir)) {
    Write-Output 'PHOTO_COUNT=0'
    Write-Output "PHOTO_NOTE=no such folder: $Dir"
    return
}
Add-Type -AssemblyName System.Drawing | Out-Null
$exts = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')

function Get-ExifDate($path) {
    try {
        $fs = [IO.File]::OpenRead($path)
        try {
            # validateImageData=$false reads metadata without decoding pixels (fast).
            $img = [System.Drawing.Image]::FromStream($fs, $false, $false)
            try {
                $prop = $img.GetPropertyItem(36867)  # 0x9003 DateTimeOriginal
                $s = ([Text.Encoding]::ASCII.GetString($prop.Value)).Trim([char]0).Trim()
                return [datetime]::ParseExact($s, 'yyyy:MM:dd HH:mm:ss', $null)
            }
            finally { $img.Dispose() }
        }
        finally { $fs.Close() }
    }
    catch { return $null }
}

$files = Get-ChildItem -Path $Dir -File -Recurse:$Recurse -ErrorAction SilentlyContinue |
    Where-Object { $exts -contains $_.Extension.ToLower() }

Write-Output ('PHOTO_DIR=' + (Resolve-Path $Dir).Path)
Write-Output ('PHOTO_COUNT=' + @($files).Count)
foreach ($f in $files) {
    $d = Get-ExifDate $f.FullName
    if (-not $d) { $d = $f.LastWriteTime }
    $h = ''
    if ($Hash) { $h = (Get-FileHash -Algorithm SHA1 -LiteralPath $f.FullName).Hash }
    Write-Output ("{0:yyyy-MM-dd HH:mm:ss}`t{1}`t{2}`t{3}" -f $d, $f.Length, $h, $f.FullName)
}
