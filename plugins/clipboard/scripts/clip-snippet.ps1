<#
  clip-snippet - a named, curated snippet library (distinct from clip-history's
  automatic chronological log). You explicitly save reusable boilerplate by name -
  license headers, config templates, command recipes, canned replies - and recall
  it onto the clipboard later. Always available (no enable flag); secrets are refused.

  Store: %LOCALAPPDATA%\runes\clipboard\snippets\
    index.tsv         name \t iso-ts \t subtype \t bytes \t preview
    <name>.txt        the snippet payload (name = sanitised key)

  Verbs:
    save -Name <n> -Subtype <t> -Path <payload>   create/UPDATE a named snippet
    get  -Name <n>                                 print + re-copy to the clipboard
    list                                           all snippets (name + preview)
    search -Query <q>                              match name/preview/content
    rm   -Name <n> | clear                         delete one / all
#>
param(
    [Parameter(Position = 0)][string]$Verb = 'list',
    [string]$Name,
    [string]$Kind = 'text',
    [string]$Subtype = 'plain',
    [string]$Path,
    [string]$Query
)
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$root = Join-Path $env:LOCALAPPDATA 'runes\clipboard\snippets'
$index = Join-Path $root 'index.tsv'

function Ensure-Store {
    if (-not (Test-Path $root)) {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        try { icacls $root /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" *> $null } catch {}
    }
}
function Read-Index { if (Test-Path $index) { @(Get-Content $index | Where-Object { $_.Trim() }) } else { @() } }
function Safe-Name([string]$n) { (($n.ToLower() -replace '[^a-z0-9._-]+', '-').Trim('-')) }
function Preview([string]$s) { $o = ($s -replace "[`t`r`n]+", ' ').Trim(); if ($o.Length -gt 100) { $o = $o.Substring(0, 97) + '...' }; $o }
function Write-Index($rows) { $rows | Set-Content -Path $index -Encoding UTF8 }

switch ($Verb) {
    'save' {
        $key = Safe-Name $Name
        if (-not $key) { Write-Output 'SNIPPET_ERROR=missing/invalid -Name'; break }
        if (-not $Path -or -not (Test-Path $Path)) { Write-Output 'SNIPPET_ERROR=missing -Path'; break }
        $isImage = ($Kind -eq 'image') -or ([IO.Path]::GetExtension($Path).ToLower() -in '.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tiff')
        if ($isImage) {
            $ext = [IO.Path]::GetExtension($Path); if (-not $ext) { $ext = '.png' }
            $prev = '[image]'
        }
        else {
            $body = Get-Content -Raw -Path $Path
            . (Join-Path $PSScriptRoot 'secret-scan.ps1')
            $sec = Find-Secrets $body
            if ($sec.count -gt 0) { Write-Output ('SNIPPET_REFUSED=secret:' + ($sec.types -join ',')); break }
            $ext = '.txt'; $prev = Preview $body
        }
        Ensure-Store
        Get-ChildItem $root -Filter "$key.*" | Remove-Item -Force -ErrorAction SilentlyContinue   # replace any prior payload/kind
        Copy-Item -LiteralPath $Path -Destination (Join-Path $root "$key$ext") -Force
        $rows = @(Read-Index | Where-Object { ($_ -split "`t")[0] -ne $key })
        $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        $rows += ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f $key, $ts, $(if ($isImage) { 'image' } else { 'text' }), $Subtype, (Get-Item $Path).Length, $prev)
        Write-Index ($rows | Sort-Object)
        Write-Output ('SNIPPET_SAVED=' + $key)
    }
    'get' {
        $key = Safe-Name $Name
        $cf = Get-ChildItem $root -Filter "$key.*" | Where-Object { $_.Name -ne "$key.meta" } | Select-Object -First 1
        if (-not $cf) { Write-Output "SNIPPET_ERROR=no snippet named '$key'"; break }
        powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File (Join-Path $PSScriptRoot 'clipboard-io.ps1') write -Path $cf.FullName *> $null
        Write-Output ('SNIPPET_NAME=' + $key)
        Write-Output 'SNIPPET_RECOPIED=clipboard'
        if ($cf.Extension -eq '.txt') {
            Write-Output '-----BEGIN CLIP TEXT-----'
            [Console]::Out.Write((Get-Content -Raw $cf.FullName))
            Write-Output ''
            Write-Output '-----END CLIP TEXT-----'
        }
        else { Write-Output ('SNIPPET_KIND=image'); Write-Output ('SNIPPET_PATH=' + $cf.FullName) }
    }
    'list' {
        $rows = Read-Index
        Write-Output ('SNIPPET_COUNT=' + $rows.Count)
        foreach ($r in ($rows | Sort-Object)) { $c = $r -split "`t"; Write-Output ("{0}`t{1}/{2}`t{3}B`t{4}" -f $c[0], $c[2], $c[3], $c[4], $c[5]) }
    }
    'search' {
        $rows = Read-Index
        $hits = @($rows | Where-Object {
                $k = ($_ -split "`t")[0]
                ($_ -match [regex]::Escape($Query)) -or (
                    (Test-Path (Join-Path $root "$k.txt")) -and ((Get-Content -Raw (Join-Path $root "$k.txt")) -match [regex]::Escape($Query))
                )
            })
        Write-Output ('SNIPPET_MATCHES=' + $hits.Count)
        foreach ($h in $hits) { $c = $h -split "`t"; Write-Output ("{0}`t{1}/{2}`t{3}" -f $c[0], $c[2], $c[3], $c[5]) }
    }
    'rm' {
        $key = Safe-Name $Name
        Get-ChildItem $root -Filter "$key.*" | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Index (Read-Index | Where-Object { ($_ -split "`t")[0] -ne $key })
        Write-Output ('SNIPPET_REMOVED=' + $key)
    }
    'clear' {
        if (Test-Path $root) { Get-ChildItem $root | Remove-Item -Force -ErrorAction SilentlyContinue }
        Write-Output 'SNIPPET_CLEARED=1'
    }
    default { Write-Output "SNIPPET_ERROR=unknown verb '$Verb'" }
}
