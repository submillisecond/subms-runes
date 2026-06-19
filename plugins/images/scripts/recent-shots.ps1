<#
  recent-shots - list recent screenshot files for the Read tool to open.
  Selection (combine freely; with none given, returns the single most recent):
    -Count N      last N (after the other filters)
    -Minutes X    modified within the last X minutes
    -Today        modified today
    -Yesterday    modified yesterday
    -Since "..."  modified at/after this date-time (any parseable form)
    -Until "..."  modified at/before this date-time
    -Within spec  calendar bucket (0=current, 1=previous): t|today|0d, yesterday|1d,
                  <N>h|d|w|m|y  (0d today, 1d yesterday, 1w last week, 1m last month)
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
    [string]$Within,
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
if ($Within) {
    $w = $Within.Trim().ToLower()
    if ($w -eq 'today' -or $w -eq 't') {
        $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today }
    }
    elseif ($w -eq 'yesterday') {
        $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today.AddDays(-1) -and $_.LastWriteTime -lt [datetime]::Today }
    }
    elseif ($w -match '^(\d+)\s*([hdwmy])$') {
        # Calendar bucket: 0 = current period, 1 = previous, ... (0d=today, 1d=yesterday).
        $n = [int]$Matches[1]; $u = $Matches[2]; $now = Get-Date
        $cur = switch ($u) {
            'h' { $now.Date.AddHours($now.Hour) }
            'd' { $now.Date }
            'w' { $dw = [int]$now.DayOfWeek; if ($dw -eq 0) { $dw = 7 }; $now.Date.AddDays(-($dw - 1)) }
            'm' { [datetime]::new($now.Year, $now.Month, 1) }
            'y' { [datetime]::new($now.Year, 1, 1) }
        }
        $lower = switch ($u) { 'h' { $cur.AddHours(-$n) } 'd' { $cur.AddDays(-$n) } 'w' { $cur.AddDays(-7 * $n) } 'm' { $cur.AddMonths(-$n) } 'y' { $cur.AddYears(-$n) } }
        $k = $n - 1
        $upper = switch ($u) { 'h' { $cur.AddHours(-$k) } 'd' { $cur.AddDays(-$k) } 'w' { $cur.AddDays(-7 * $k) } 'm' { $cur.AddMonths(-$k) } 'y' { $cur.AddYears(-$k) } }
        $files = $files | Where-Object { $_.LastWriteTime -ge $lower -and $_.LastWriteTime -lt $upper }
    }
}
if ($Name) { $files = $files | Where-Object { $_.Name -like "*$Name*" } }

$anyFilter = ($Count -gt 0) -or ($Minutes -gt 0) -or $Today -or $Yesterday -or $Since -or $Until -or $Within -or $Name
if (-not $anyFilter) { $Count = 1 }
if ($Count -gt 0) { $files = $files | Select-Object -First $Count }

foreach ($d in $dirs) { Write-Output ('SHOTS_DIR=' + $d) }
Write-Output ('SHOTS_COUNT=' + @($files).Count)
foreach ($f in $files) { Write-Output $f.FullName }
