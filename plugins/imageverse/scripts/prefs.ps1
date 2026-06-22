<#
  prefs - remember the organize scheme used for a given directory, so next time
  img-organize can RECOMMEND it. Per-plugin store (a tab-separated table, no jq
  dependency) at %LOCALAPPDATA%\runes\<plugin>\prefs.tsv, keyed by folder.

    get -Dir <folder>                 print the remembered scheme, or PREFS_NONE
    set -Dir <folder> -Albums a,b,c [-Op move|copy] [-Scheme albums]

  get prints PREFS_DIR / PREFS_SCHEME / PREFS_OP / PREFS_ALBUMS / PREFS_UPDATED.
#>
param(
    [Parameter(Position = 0)][string]$Action = 'get',
    [string]$Dir,
    [string]$Albums,
    [string]$Op = 'move',
    [string]$Scheme = 'albums',
    [string]$Plugin = 'imageverse'
)
$ErrorActionPreference = 'Stop'
if (-not $Dir) { Write-Output 'PREFS_ERROR=missing -Dir'; exit 1 }
$dataBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA }
elseif ($env:APPDATA) { $env:APPDATA }
elseif ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME }
else { Join-Path $HOME '.local/share' }
$file = Join-Path $dataBase "runes\$Plugin\prefs.tsv"
$key = ([IO.Path]::GetFullPath($Dir)).TrimEnd('\', '/').ToLowerInvariant()
$lines = if (Test-Path $file) { @(Get-Content $file) } else { @() }

switch ($Action.ToLower()) {
    'set' {
        $kept = @($lines | Where-Object { $_.Trim() -and ($_ -split "`t")[0] -ne $key })
        $rec = @($key, $Dir, $Scheme, $Op, $Albums, (Get-Date -Format 'o')) -join "`t"
        $fdir = Split-Path -Parent $file
        if ($fdir -and -not (Test-Path $fdir)) { New-Item -ItemType Directory -Force -Path $fdir | Out-Null }
        ($kept + $rec) | Set-Content -Path $file -Encoding UTF8
        Write-Output "PREFS_SAVED=$Dir"
    }
    default {
        $line = $lines | Where-Object { ($_ -split "`t")[0] -eq $key } | Select-Object -First 1
        if (-not $line) { Write-Output 'PREFS_NONE=1'; return }
        $f = $line -split "`t"
        Write-Output ('PREFS_DIR=' + $f[1])
        Write-Output ('PREFS_SCHEME=' + $f[2])
        Write-Output ('PREFS_OP=' + $f[3])
        Write-Output ('PREFS_ALBUMS=' + $f[4])
        Write-Output ('PREFS_UPDATED=' + $f[5])
    }
}
