<#
  recent-shots - list recent screenshot files for the Read tool to open.
  Selection (combine freely; with none given, returns the single most recent):
    -Count N      last N (after the other filters)
    -Minutes X    modified within the last X minutes
    -Today        modified today
    -Yesterday    modified yesterday
    -Since "..."  modified at/after this date-time (any parseable form)
    -Until "..."  modified at/before this date-time
    -Name glob    filename contains this (wildcards allowed, e.g. *error*)
    -Dir path     search here instead of the auto-detected Screenshots folders
  Prints SHOTS_DIR (each searched), SHOTS_COUNT, then one absolute path per line
  (newest first). Lists only; never moves or modifies files.
#>
param(
    [int]$Count = 0,
    [int]$Minutes = 0,
    [switch]$Today,
    [switch]$Yesterday,
    [string]$Since,
    [string]$Until,
    [string]$Name,
    [string]$Dir
)
$ErrorActionPreference = 'SilentlyContinue'

$dirs = New-Object System.Collections.Generic.List[string]
if ($Dir) {
    $dirs.Add($Dir)
}
else {
    $cands = @()
    if ($env:USERPROFILE) { $cands += (Join-Path $env:USERPROFILE 'Pictures\Screenshots') }
    foreach ($od in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) {
        if ($od) { $cands += (Join-Path $od 'Pictures\Screenshots') }
    }
    $reg = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).'{B7BEDE81-DF94-4682-A7D8-57A52620B86F}'
    if ($reg) { $cands += [Environment]::ExpandEnvironmentVariables($reg) }
    foreach ($c in ($cands | Select-Object -Unique)) { if (Test-Path $c) { $dirs.Add($c) } }
}

if ($dirs.Count -eq 0) {
    Write-Output 'SHOTS_COUNT=0'
    Write-Output 'SHOTS_NOTE=no Screenshots folder found; pass -Dir <path>'
    return
}

$exts = '*.png', '*.jpg', '*.jpeg'
$files = foreach ($d in $dirs) {
    Get-ChildItem -Path (Join-Path $d '*') -Include $exts -File -ErrorAction SilentlyContinue
}
$files = $files | Sort-Object LastWriteTime -Descending

if ($Minutes -gt 0) { $cut = (Get-Date).AddMinutes(-$Minutes); $files = $files | Where-Object { $_.LastWriteTime -ge $cut } }
if ($Today) { $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today } }
if ($Yesterday) {
    $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today.AddDays(-1) -and $_.LastWriteTime -lt [datetime]::Today }
}
if ($Since) { $s = [datetime]$Since; $files = $files | Where-Object { $_.LastWriteTime -ge $s } }
if ($Until) { $u = [datetime]$Until; $files = $files | Where-Object { $_.LastWriteTime -le $u } }
if ($Name) { $files = $files | Where-Object { $_.Name -like "*$Name*" } }

$anyFilter = ($Count -gt 0) -or ($Minutes -gt 0) -or $Today -or $Yesterday -or $Since -or $Until -or $Name
if (-not $anyFilter) { $Count = 1 }
if ($Count -gt 0) { $files = $files | Select-Object -First $Count }

foreach ($d in $dirs) { Write-Output ('SHOTS_DIR=' + $d) }
Write-Output ('SHOTS_COUNT=' + @($files).Count)
foreach ($f in $files) { Write-Output $f.FullName }
