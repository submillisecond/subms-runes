# set-dates: set file times to the capture date in an organised name (...-YYYY-MM-DD-HHMMSS...). Content is untouched.
# set-dates.ps1 [-Dir d] [-NoRecurse]; prints DATES_SET and DATES_SKIPPED.
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
