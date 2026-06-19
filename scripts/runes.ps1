<#
  runes - manage the subms-runes Claude Code skill marketplace.
  Usage: runes <command> [packs...] [-Local]
  No packs given = all packs (every plugins/<dir> with .claude-plugin/plugin.json).
#>
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Targets,
    [switch]$Local
)
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Market = 'subms-runes'
$Gh = 'submillisecond/subms-runes'
$PluginsDir = Join-Path $Repo 'plugins'

function Get-Packs {
    if (-not (Test-Path $PluginsDir)) { return @() }
    Get-ChildItem $PluginsDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName '.claude-plugin\plugin.json') } |
        ForEach-Object Name
}
function Resolve-Targets { if ($Targets) { $Targets } else { Get-Packs } }
function Get-PackVersion($p) {
    $f = Join-Path $PluginsDir "$p\.claude-plugin\plugin.json"
    if (Test-Path $f) { (Get-Content $f -Raw | ConvertFrom-Json).version } else { '?' }
}

switch ($Command) {
    'deploy' {
        $src = if ($Local) { $Repo } else { $Gh }
        Write-Host "Adding marketplace from $src ..."
        claude plugin marketplace add $src 2>&1 | Out-Null
        foreach ($p in Resolve-Targets) {
            Write-Host "Installing $p@$Market ..."
            claude plugin install "$p@$Market" --scope user
        }
        Write-Host 'Done. Restart the Claude Code session to load the runes.'
    }
    'redeploy' {
        claude plugin marketplace update $Market 2>&1 | Out-Null
        foreach ($p in Resolve-Targets) {
            claude plugin uninstall "$p@$Market" 2>&1 | Out-Null
            claude plugin install "$p@$Market" --scope user
        }
        Write-Host 'Redeployed. Restart the session to apply.'
    }
    'remove' {
        foreach ($p in Resolve-Targets) { claude plugin uninstall "$p@$Market" 2>&1 | Out-Null }
        if (-not $Targets) { claude plugin marketplace remove $Market 2>&1 | Out-Null }
        Write-Host 'Removed.'
    }
    'dev' {
        if (-not $Targets) { throw 'Usage: runes dev <pack>' }
        $dir = Join-Path $PluginsDir $Targets[0]
        if (-not (Test-Path $dir)) { throw "No such pack: $($Targets[0])" }
        claude --plugin-dir $dir
    }
    'status' {
        $installed = (claude plugin list 2>&1) -join "`n"
        foreach ($p in Get-Packs) {
            $tree = Get-PackVersion $p
            $state = if ($installed -match [regex]::Escape("$p@$Market")) { 'installed' } else { 'not installed' }
            Write-Host ("{0,-16} tree=v{1,-10} {2}" -f $p, $tree, $state)
        }
    }
    'list' { claude plugin list }
    'validate' { & (Join-Path $PSScriptRoot 'validate.ps1') @Targets }
    'test' {
        if (-not $Targets) { throw 'Usage: runes test <pack> [rune]' }
        $pack = $Targets[0]; $rune = $Targets[1]
        $sdir = if ($rune) { Join-Path $PluginsDir "$pack\skills\$rune\scripts" } else { Join-Path $PluginsDir "$pack\scripts" }
        $s = Get-ChildItem $sdir -Filter *.ps1 -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $s) { throw "No script found under $sdir" }
        powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File $s.FullName
    }
    'new-pack' {
        if (-not $Targets) { throw 'Usage: runes new-pack <name>' }
        $name = $Targets[0]
        $pdir = Join-Path $PluginsDir $name
        if (Test-Path $pdir) { throw "Pack already exists: $name" }
        New-Item -ItemType Directory -Force -Path (Join-Path $pdir '.claude-plugin') | Out-Null
        New-Item -ItemType Directory -Force -Path (Join-Path $pdir 'skills') | Out-Null
        $pj = [ordered]@{
            name        = $name
            description = "$name runes for Claude Code."
            version     = '0.1.0'
            author      = [ordered]@{ name = 'Kieran Smith'; email = 'oss@submillisecond.com' }
        }
        ($pj | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $pdir '.claude-plugin\plugin.json') -Encoding UTF8
        $mf = Join-Path $Repo '.claude-plugin\marketplace.json'
        $m = Get-Content $mf -Raw | ConvertFrom-Json
        $entry = [ordered]@{ name = $name; source = "./plugins/$name"; description = "$name runes."; author = [ordered]@{ name = 'Kieran Smith' } }
        $m.plugins += $entry
        ($m | ConvertTo-Json -Depth 6) | Set-Content $mf -Encoding UTF8
        Write-Host "Created pack '$name'. Add a rune with: runes new-rune $name <rune>"
    }
    'new-rune' {
        if ($Targets.Count -lt 2) { throw 'Usage: runes new-rune <pack> <rune>' }
        $pack = $Targets[0]; $rune = $Targets[1]
        if (-not (Test-Path (Join-Path $PluginsDir $pack))) { throw "No such pack: $pack" }
        $rdir = Join-Path $PluginsDir "$pack\skills\$rune"
        if (Test-Path $rdir) { throw "Rune already exists: $pack/$rune" }
        New-Item -ItemType Directory -Force -Path (Join-Path $rdir 'scripts') | Out-Null
        $skill = @(
            '---',
            "name: $rune",
            "description: This skill should be used when the user asks to ""/$rune"" or ... (fill in concrete trigger phrases users would say).",
            'version: 0.1.0',
            '---',
            '',
            "# $rune",
            '',
            '(One paragraph: what this rune does.)',
            '',
            '## Steps',
            '',
            '1. (...)',
            '2. Answer the user''s question (the skill arguments).'
        ) -join "`r`n"
        $skill | Set-Content (Join-Path $rdir 'SKILL.md') -Encoding UTF8
        Write-Host "Created rune '$pack/$rune'. Edit $rdir\SKILL.md, then: runes dev $pack"
    }
    'tag' {
        foreach ($p in Resolve-Targets) { claude plugin tag (Join-Path $PluginsDir $p) }
    }
    default {
        $help = @(
            'runes - manage the subms-runes skill marketplace',
            'Usage: runes <command> [packs...] [-Local]',
            '',
            '  deploy [packs]          install packs from GitHub (official); -Local uses the working tree',
            '  redeploy [packs]        force-refresh installed packs (uninstall + reinstall)',
            '  remove [packs]          uninstall packs; drop the marketplace if none remain',
            '  dev <pack>              live-load one pack from the working tree (--plugin-dir)',
            '  status                  show working-tree vs installed version per pack',
            '  list                    claude plugin list',
            '  validate [packs]        structural checks (same as CI)',
            '  test <pack> [rune]      run a pack/rune script standalone (clipboard: runes test clipboard)',
            '  new-pack <name>         scaffold a new pack',
            '  new-rune <pack> <rune>  scaffold a new rune',
            '  tag [packs]             git release tag <pack>--vX.Y.Z',
            '',
            'No packs = all packs.'
        ) -join "`n"
        Write-Host $help
    }
}
