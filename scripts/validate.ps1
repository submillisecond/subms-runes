<#
  Structural validation for the subms-runes marketplace. Used by `runes validate`
  and by CI - no Claude CLI dependency. Exits non-zero on any failure.
  Usage: validate.ps1 [packs...]   (no packs = all)
#>
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Only)
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$PluginsDir = Join-Path $Repo 'plugins'
$MarketFile = Join-Path $Repo '.claude-plugin/marketplace.json'
$errs = New-Object System.Collections.Generic.List[string]
function Fail($m) { $errs.Add($m) }

$market = $null
if (-not (Test-Path $MarketFile)) {
    Fail 'missing .claude-plugin/marketplace.json'
}
else {
    try { $market = Get-Content $MarketFile -Raw | ConvertFrom-Json }
    catch { Fail "marketplace.json invalid JSON: $_" }
}

$onDisk = @()
if (Test-Path $PluginsDir) {
    $onDisk = Get-ChildItem $PluginsDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName '.claude-plugin/plugin.json') } |
        ForEach-Object Name
}
$packs = if ($Only) { $Only } else { $onDisk }
$semver = '^\d+\.\d+\.\d+$'

foreach ($p in $packs) {
    $pdir = Join-Path $PluginsDir $p
    $pj = Join-Path $pdir '.claude-plugin/plugin.json'
    if (-not (Test-Path $pj)) { Fail "${p}: missing plugin.json"; continue }
    $man = $null
    try { $man = Get-Content $pj -Raw | ConvertFrom-Json } catch { Fail "${p}: plugin.json invalid JSON: $_"; continue }
    if ($man.name -ne $p) { Fail "${p}: plugin.json name '$($man.name)' != dir '$p'" }
    if ($man.version -notmatch $semver) { Fail "${p}: version '$($man.version)' is not semver" }

    $sdir = Join-Path $pdir 'skills'
    if (Test-Path $sdir) {
        foreach ($skill in Get-ChildItem $sdir -Directory) {
            $sf = Join-Path $skill.FullName 'SKILL.md'
            if (-not (Test-Path $sf)) { Fail "$p/$($skill.Name): missing SKILL.md"; continue }
            $raw = Get-Content $sf -Raw
            if ($raw -notmatch '(?s)^\s*---.*?---') { Fail "$p/$($skill.Name): SKILL.md missing frontmatter block" }
            if ($raw -notmatch '(?m)^name:\s*\S') { Fail "$p/$($skill.Name): SKILL.md frontmatter missing name" }
            if ($raw -notmatch '(?m)^description:\s*\S') { Fail "$p/$($skill.Name): SKILL.md frontmatter missing description" }
            $scd = Join-Path $skill.FullName 'scripts'
            if (Test-Path $scd) {
                foreach ($ps in Get-ChildItem $scd -Filter *.ps1) {
                    $tok = $null; $perr = $null
                    [System.Management.Automation.Language.Parser]::ParseFile($ps.FullName, [ref]$tok, [ref]$perr) | Out-Null
                    if ($perr -and $perr.Count) { Fail "$p/$($skill.Name)/$($ps.Name): PowerShell parse error" }
                }
            }
        }
    }

    # Pack-level shared scripts (e.g. clipboard-io.ps1).
    $packScripts = Join-Path $pdir 'scripts'
    if (Test-Path $packScripts) {
        foreach ($ps in Get-ChildItem $packScripts -Filter *.ps1) {
            $tok = $null; $perr = $null
            [System.Management.Automation.Language.Parser]::ParseFile($ps.FullName, [ref]$tok, [ref]$perr) | Out-Null
            if ($perr -and $perr.Count) { Fail "$p/scripts/$($ps.Name): PowerShell parse error" }
        }
    }
}

if ($market) {
    $listed = @($market.plugins | ForEach-Object name)
    foreach ($m in ($onDisk | Where-Object { $_ -notin $listed })) { Fail "pack '$m' on disk but not in marketplace.json" }
    foreach ($m in ($listed | Where-Object { $_ -notin $onDisk })) { Fail "marketplace.json lists '$m' but no such pack on disk" }
}

# Syntax-check any .sh backends with bash -n (skipped if bash is unavailable).
$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash) {
    foreach ($p in $packs) {
        $pdir = Join-Path $PluginsDir $p
        if (-not (Test-Path $pdir)) { continue }
        foreach ($sh in Get-ChildItem $pdir -Recurse -Filter *.sh -ErrorAction SilentlyContinue) {
            # Forward slashes: git-bash on Windows treats backslashes as escapes.
            & bash -n ($sh.FullName -replace '\\', '/') 2>$null
            if ($LASTEXITCODE -ne 0) { Fail "${p}: bash -n failed for $($sh.Name)" }
        }
    }
}

# Rich rollup on the GitHub Actions run page (no-op locally).
if ($env:GITHUB_STEP_SUMMARY) {
    $ok = $errs.Count -eq 0
    $badge = if ($ok) { ':white_check_mark: passed' } else { ":x: failed ($($errs.Count))" }
    $md = New-Object System.Collections.Generic.List[string]
    $md.Add(":mag: **validate** - $badge")
    $md.Add('')
    $md.Add('| Pack | Version | Runes | Scripts |')
    $md.Add('|---|---|---|---|')
    foreach ($p in ($onDisk | Sort-Object)) {
        $pdir = Join-Path $PluginsDir $p
        $ver = (Get-Content (Join-Path $pdir '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json).version
        $runes = (@(Get-ChildItem (Join-Path $pdir 'skills') -Directory -ErrorAction SilentlyContinue | ForEach-Object Name) | Sort-Object) -join ', '
        $nscripts = @(Get-ChildItem $pdir -Recurse -Include '*.ps1', '*.sh' -ErrorAction SilentlyContinue).Count
        $md.Add("| $p | $ver | $runes | $nscripts |")
    }
    if (-not $ok) {
        $md.Add('')
        $md.Add('### Failures')
        foreach ($e in $errs) { $md.Add("- $e") }
    }
    ($md -join "`n") | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding utf8
}

if ($errs.Count) {
    Write-Host "VALIDATION FAILED ($($errs.Count)):"
    $errs | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "validate: OK ($(@($packs).Count) pack(s))"
