# suite-lib: helpers for tests/*.tests.ps1 (Set-SuiteScripts, Run, NewTemp, Check, Has, Complete-Suite). Dot-sourced.
# Test tooling only; contract-lib.sh is the bash peer.
$ErrorActionPreference = 'Stop'
$script:pass = 0; $script:fail = 0
$script:HostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script:SuiteScripts = ''

# Point Run at a pack's scripts dir.
function Set-SuiteScripts([string]$dir) { $script:SuiteScripts = $dir }

# Run a backend script as a child of this host (pwsh on CI, powershell/pwsh local),
# capturing stdout+stderr as string lines.
function Run([string]$name, [string[]]$arguments) {
    $sp = Join-Path $script:SuiteScripts $name
    (& $script:HostExe -NoProfile -ExecutionPolicy Bypass -File $sp @arguments 2>&1) | ForEach-Object { "$_" }
}

# A fresh isolated temp dir (caller cleans it).
function NewTemp { $p = Join-Path ([IO.Path]::GetTempPath()) ("rt-" + [Guid]::NewGuid().ToString('N').Substring(0, 8)); New-Item -ItemType Directory -Force $p | Out-Null; $p }

function Check([string]$desc, [bool]$cond) {
    if ($cond) { $script:pass++; Write-Host "  ok  $desc" }
    else { $script:fail++; Write-Host "  FAIL $desc" -ForegroundColor Red }
}

function Has($lines, $pattern) { @($lines | Select-String -SimpleMatch $pattern).Count -gt 0 }

# Print the tally; exit non-zero on any failure (CI gate). Call last.
function Complete-Suite([string]$label) {
    Write-Host ""
    Write-Host ("$label tests: {0} passed, {1} failed" -f $script:pass, $script:fail)
    if ($script:fail -gt 0) { exit 1 }
}
