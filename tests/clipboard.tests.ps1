<#
  Functional tests for the clipboard backend scripts: the secret-detection engine
  and the typed history store. Runs each script as a child process against
  synthetic input and asserts its output contract. Runs under pwsh on Linux CI and
  powershell/pwsh locally. Exit 0 = all pass; non-zero = a failure (CI gate).
  (clipboard-io read needs a live OS clipboard, so it is exercised manually, not here.)
#>
$ErrorActionPreference = 'Stop'
$Scripts = Join-Path $PSScriptRoot '..\plugins\clipboard\scripts'
$HostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script:pass = 0; $script:fail = 0

function Run([string]$name, [string[]]$arguments) {
    $sp = Join-Path $Scripts $name
    (& $HostExe -NoProfile -ExecutionPolicy Bypass -File $sp @arguments 2>&1) | ForEach-Object { "$_" }
}
function NewTemp { $p = Join-Path ([IO.Path]::GetTempPath()) ("cbt-" + [Guid]::NewGuid().ToString('N').Substring(0, 8)); New-Item -ItemType Directory -Force $p | Out-Null; $p }
function Check([string]$desc, [bool]$cond) {
    if ($cond) { $script:pass++; Write-Host "  ok  $desc" }
    else { $script:fail++; Write-Host "  FAIL $desc" -ForegroundColor Red }
}
function Has($lines, $pattern) { @($lines | Select-String -SimpleMatch $pattern).Count -gt 0 }

Write-Host "clipboard functional tests"

# 1. secret-scan: detects vendor tokens + redacts; ignores benign code.
try {
    $o = Run 'secret-scan.ps1' @('-Text', 'use ghp_1234567890abcdefghijklmnopqrstuvwxyz here', '-Redact')
    Check 'secret-scan flags a GitHub PAT' (Has $o 'CLIP_SECRETS=github-pat')
    Check 'secret-scan redacts the token' (Has $o '[REDACTED:github-pat]')
    $o2 = Run 'secret-scan.ps1' @('-Text', 'function add(a,b){return a+b} // password = changeme')
    Check 'secret-scan ignores benign code (no false positive)' (Has $o2 'CLIP_SECRETS=' -and -not (Has $o2 'CLIP_SECRETS=g'))
    Check 'secret-scan count is 0 on benign code' (Has $o2 'CLIP_SECRET_COUNT=0')
    $o3 = Run 'secret-scan.ps1' @('-Text', 'AKIAIOSFODNN7EXAMPLE eyJabc123.eyJdef456.sigGHI789 postgres://u:p4ssw0rd-x9z@db/n -----BEGIN RSA PRIVATE KEY-----')
    Check 'secret-scan catches aws/jwt/db/private-key together' ((Has $o3 'aws-access-key') -and (Has $o3 'private-key') -and (Has $o3 'db-connection'))
    $o4 = Run 'secret-scan.ps1' @('-Text', 'api_key = "Zx9Kq2Lm8Pv4Rt6Wy1Bn3Cd5Ef7Gh"')
    Check 'secret-scan flags a high-entropy api_key assignment' (Has $o4 'generic-secret-assignment')
}
catch { $script:fail++; Write-Host "  FAIL secret-scan threw: $_" -ForegroundColor Red }

# 2-N. clip-history: sandbox LOCALAPPDATA so we never touch the real store.
$sandbox = NewTemp
$env:LOCALAPPDATA = $sandbox
$env:RUNES_CLIP_HISTORY = $null
try {
    Run 'clip-history.ps1' @('enable') | Out-Null
    $st = Run 'clip-history.ps1' @('status')
    Check 'clip-history enable -> status reports enabled' (Has $st 'HISTORY_ENABLED=1')

    $u = Join-Path $sandbox 'u.txt'; 'https://example.com/dash' | Set-Content $u
    $c = Join-Path $sandbox 'c.txt'; "def f(x):`n  return x*2" | Set-Content $c
    $sx = Join-Path $sandbox 's.txt'; 'token ghp_1234567890abcdefghijklmnopqrstuvwxyz' | Set-Content $sx
    Run 'clip-history.ps1' @('add', '-Kind', 'text', '-Subtype', 'url', '-Source', 'clip-copy', '-Path', $u) | Out-Null
    Run 'clip-history.ps1' @('add', '-Kind', 'text', '-Subtype', 'code', '-Source', 'clip-copy', '-Path', $c) | Out-Null
    $sk = Run 'clip-history.ps1' @('add', '-Kind', 'text', '-Subtype', 'plain', '-Source', 'clip-copy', '-Path', $sx)
    Check 'clip-history SKIPS a secret-bearing entry' (Has $sk 'HISTORY_SKIPPED=secret')

    $list = Run 'clip-history.ps1' @('list')
    Check 'clip-history list reports 2 entries (secret not stored)' (Has $list 'HISTORY_COUNT=2')
    Check 'clip-history list is typed (text/url)' (Has $list 'text/url')

    $get = Run 'clip-history.ps1' @('get', '-Id', '#1')
    Check 'clip-history get returns the newest payload (the code)' (Has $get 'return x*2')

    $search = Run 'clip-history.ps1' @('search', '-Query', 'example.com')
    Check 'clip-history search finds the url' (Has $search 'HISTORY_MATCHES=1')

    # disabled -> add is a no-op
    Run 'clip-history.ps1' @('disable') | Out-Null
    $dis = Run 'clip-history.ps1' @('add', '-Kind', 'text', '-Subtype', 'plain', '-Source', 'clip', '-Path', $u)
    Check 'clip-history add is a no-op when disabled' (Has $dis 'HISTORY_SKIPPED=disabled')

    # cap pruning
    Run 'clip-history.ps1' @('clear') | Out-Null
    Run 'clip-history.ps1' @('enable') | Out-Null
    $env:RUNES_HISTORY_MAX_ENTRIES = '2'
    1..3 | ForEach-Object { $f = Join-Path $sandbox "e$_.txt"; "entry number $_" | Set-Content $f; Run 'clip-history.ps1' @('add', '-Kind', 'text', '-Subtype', 'plain', '-Source', 'clip', '-Path', $f) | Out-Null }
    $capped = Run 'clip-history.ps1' @('list')
    Check 'clip-history prunes to RUNES_HISTORY_MAX_ENTRIES (2)' (Has $capped 'HISTORY_COUNT=2')
    Remove-Item Env:\RUNES_HISTORY_MAX_ENTRIES -ErrorAction SilentlyContinue

    $clr = Run 'clip-history.ps1' @('clear')
    Check 'clip-history clear empties the store' (Has $clr 'HISTORY_CLEARED=1')
}
catch { $script:fail++; Write-Host "  FAIL clip-history threw: $_" -ForegroundColor Red }
finally { Remove-Item Env:\LOCALAPPDATA -ErrorAction SilentlyContinue; Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue }

# clip-snippet: named library, text + image, secret-refusal, overwrite.
$snipbox = NewTemp
$env:LOCALAPPDATA = $snipbox
try {
    $h = Join-Path $snipbox 'h.txt'; '// SPDX-License-Identifier: MIT' | Set-Content $h
    $s = Join-Path $snipbox 's.txt'; 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMIK7MDENGbPxRfiCYEXAMPLEKEY12' | Set-Content $s
    $sv = Run 'clip-snippet.ps1' @('save', '-Name', 'MIT Header', '-Subtype', 'code', '-Path', $h)
    Check 'clip-snippet save sanitizes the name (MIT Header -> mit-header)' (Has $sv 'SNIPPET_SAVED=mit-header')
    $ref = Run 'clip-snippet.ps1' @('save', '-Name', 'creds', '-Subtype', 'env', '-Path', $s)
    Check 'clip-snippet REFUSES a secret-bearing snippet' (Has $ref 'SNIPPET_REFUSED=secret')
    'updated MIT' | Set-Content $h
    Run 'clip-snippet.ps1' @('save', '-Name', 'mit-header', '-Subtype', 'code', '-Path', $h) | Out-Null
    $ls = Run 'clip-snippet.ps1' @('list')
    Check 'clip-snippet overwrite keeps a single entry' (Has $ls 'SNIPPET_COUNT=1')
    $g = Run 'clip-snippet.ps1' @('get', '-Name', 'mit-header')
    Check 'clip-snippet get returns the updated body' (Has $g 'updated MIT')

    # image snippet
    Add-Type -AssemblyName System.Drawing | Out-Null
    $bmp = New-Object System.Drawing.Bitmap 6, 6
    $png = Join-Path $snipbox 'logo.png'; $bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    Run 'clip-snippet.ps1' @('save', '-Name', 'logo', '-Kind', 'image', '-Path', $png) | Out-Null
    $li = Run 'clip-snippet.ps1' @('list')
    Check 'clip-snippet stores an IMAGE snippet (kind=image)' (Has $li 'image')
    $gi = Run 'clip-snippet.ps1' @('get', '-Name', 'logo')
    Check 'clip-snippet get of an image returns SNIPPET_PATH' (Has $gi 'SNIPPET_PATH=')
}
catch { $script:fail++; Write-Host "  FAIL clip-snippet threw: $_" -ForegroundColor Red }
finally { Remove-Item Env:\LOCALAPPDATA -ErrorAction SilentlyContinue; Remove-Item $snipbox -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host ("clipboard tests: {0} passed, {1} failed" -f $script:pass, $script:fail)
if ($script:fail -gt 0) { exit 1 }
