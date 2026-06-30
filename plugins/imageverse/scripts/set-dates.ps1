<#
  set-dates - set each file's modified-time (and creation-time) to its CAPTURE date,
  read from the organised filename (`...-YYYY-MM-DD-HHMMSS[-fff]...`). WhatsApp/messenger
  images lose EXIF, so after organizing they carry the DOWNLOAD date and sort wrong in
  Explorer/Finder/Photos - this rewrites the timestamp to the real/inferred capture
  date the organiser put in the name. Read-only on content; only touches timestamps.
  Cross-platform: set-dates.sh is the macOS/Linux backend.

    -Dir folder      folder to walk (default: current dir)
    -Recurse         include subfolders (default ON)
    -NoRecurse       top level only
  Prints DATES_SET=<n> DATES_SKIPPED=<n> (skipped = no parseable date in the name).
#>
param(
    [string]$Dir = '.',
    [switch]$NoRecurse
)
$ErrorActionPreference = 'SilentlyContinue'
if (-not (Test-Path -LiteralPath $Dir)) { Write-Output "DATES_ERROR=no such dir: $Dir"; exit 1 }
$set = 0; $skip = 0
$files = Get-ChildItem -LiteralPath $Dir -File -Recurse:(-not $NoRecurse)
foreach ($f in $files) {
    # match the organiser's name stamp: <name>-YYYY-MM-DD-HHMMSS[-fff][-N].ext
    if ($f.Name -match '(\d{4})-(\d{2})-(\d{2})-(\d{2})(\d{2})(\d{2})') {
        try {
            $dt = [datetime]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4], [int]$Matches[5], [int]$Matches[6])
            $f.LastWriteTime = $dt
            $f.CreationTime = $dt
            $set++
        }
        catch { $skip++ }
    }
    else { $skip++ }
}
Write-Output "DATES_SET=$set DATES_SKIPPED=$skip"
