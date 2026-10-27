# workspace: mint or remove a per-run temp dir under %TEMP%\runes\<plugin>\.
# workspace.ps1 new -Plugin p [-Skill s] -> WORKSPACE=<dir> | clean -Dir d (refused outside %TEMP%\runes).
param(
    [Parameter(Position = 0)][ValidateSet('new', 'clean')][string]$Action = 'new',
    [string]$Plugin = 'misc',
    [string]$Skill = 'run',
    [string]$Dir
)
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:TEMP 'runes'

switch ($Action) {
    'new' {
        $id = [guid]::NewGuid().ToString('N').Substring(0, 8)
        $ws = Join-Path $root (Join-Path $Plugin "$Skill-$id")
        New-Item -ItemType Directory -Force -Path $ws | Out-Null
        Write-Output ("WORKSPACE=" + $ws)
    }
    'clean' {
        if (-not $Dir) { Write-Output 'WORKSPACE_ERROR=missing -Dir'; exit 1 }
        $full = [IO.Path]::GetFullPath($Dir)
        # Guard: only ever delete inside %TEMP%\runes so a bad path can't nuke real data.
        if (-not $full.ToLowerInvariant().StartsWith(([IO.Path]::GetFullPath($root)).ToLowerInvariant())) {
            Write-Output "WORKSPACE_ERROR=refusing to clean outside $root : $full"; exit 1
        }
        if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
        Write-Output ("WORKSPACE_CLEANED=" + $full)
    }
}
