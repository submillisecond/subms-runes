# clip-history: opt-in, searchable history of clipboard captures. Secrets are never stored.
# Verbs, store layout, env vars and output: ../contract/CONTRACTS.md.
param(
    [Parameter(Position = 0)][string]$Verb = 'status',
    [string]$Kind = 'text',
    [string]$Subtype = 'plain',
    [string]$Source = 'clip',
    [string]$Path,
    [string]$Id,
    [string]$Query,
    [int]$Count = 20
)
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$root = Join-Path $env:LOCALAPPDATA 'runes\clipboard\history'
$index = Join-Path $root 'index.tsv'
$flag = Join-Path $root '.enabled'

function Ensure-Store {
    if (-not (Test-Path $root)) {
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        # Owner-only: strip inheritance, grant the current user full control.
        try { icacls $root /inheritance:r /grant:r "${env:USERNAME}:(OI)(CI)F" *> $null } catch {}
    }
}
function Is-Enabled { ($env:RUNES_CLIP_HISTORY -eq '1') -or (Test-Path $flag) }
function Read-Index { if (Test-Path $index) { @(Get-Content $index | Where-Object { $_.Trim() }) } else { @() } }
function Preview([string]$s) {
    $one = ($s -replace "[`t`r`n]+", ' ').Trim()
    if ($one.Length -gt 100) { $one = $one.Substring(0, 97) + '...' }
    $one
}

switch ($Verb) {
    'enable' { Ensure-Store; New-Item -ItemType File -Force -Path $flag | Out-Null; Write-Output 'HISTORY_ENABLED=1' }
    'disable' { Remove-Item $flag -Force -ErrorAction SilentlyContinue; Write-Output 'HISTORY_ENABLED=0' }
    'status' {
        Write-Output ('HISTORY_ENABLED=' + $(if (Is-Enabled) { '1' } else { '0' }))
        Write-Output ('HISTORY_DIR=' + $root)
        Write-Output ('HISTORY_COUNT=' + (Read-Index).Count)
    }
    'add' {
        if (-not (Is-Enabled)) { Write-Output 'HISTORY_SKIPPED=disabled'; break }
        if (-not $Path -or -not (Test-Path $Path)) { Write-Output 'HISTORY_ERROR=missing -Path'; break }
        Ensure-Store
        $maxBytes = if ($env:RUNES_HISTORY_MAX_BYTES) { [int]$env:RUNES_HISTORY_MAX_BYTES } else { 1048576 }
        $len = (Get-Item $Path).Length
        if ($len -gt $maxBytes) { Write-Output "HISTORY_SKIPPED=too_large ($len > $maxBytes)"; break }
        $body = if ($Kind -eq 'text') { Get-Content -Raw -Path $Path } else { '' }
        if ($env:RUNES_HISTORY_EXCLUDE -and $body -and ($body -match $env:RUNES_HISTORY_EXCLUDE)) { Write-Output 'HISTORY_SKIPPED=excluded'; break }
        # Never store secrets.
        if ($Kind -eq 'text' -and $body) {
            . (Join-Path $PSScriptRoot 'secret-scan.ps1')
            $sec = Find-Secrets $body
            if ($sec.count -gt 0) { Write-Output ('HISTORY_SKIPPED=secret:' + ($sec.types -join ',')); break }
        }
        $eid = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $ext = switch ($Kind) { 'image' { '.png' } 'files' { '.files.txt' } default { '.txt' } }
        Copy-Item -LiteralPath $Path -Destination (Join-Path $root ($eid + $ext)) -Force
        $prev = if ($Kind -eq 'text') { Preview $body } elseif ($Kind -eq 'files') { Preview ((Get-Content $Path) -join ', ') } else { '[image]' }
        $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $eid, $ts, $Kind, $Subtype, $len, $Source, $prev) | Add-Content -Path $index -Encoding UTF8
        # Prune to cap (oldest first; index is append-order = chronological).
        $maxN = if ($env:RUNES_HISTORY_MAX_ENTRIES) { [int]$env:RUNES_HISTORY_MAX_ENTRIES } else { 200 }
        $rows = Read-Index
        if ($rows.Count -gt $maxN) {
            $drop = $rows[0..($rows.Count - $maxN - 1)]
            foreach ($d in $drop) { $did = ($d -split "`t")[0]; Remove-Item (Join-Path $root "$did*") -Force -ErrorAction SilentlyContinue }
            $rows[($rows.Count - $maxN)..($rows.Count - 1)] | Set-Content -Path $index -Encoding UTF8
        }
        Write-Output ('HISTORY_ADDED=' + $eid)
    }
    'list' {
        $rows = Read-Index
        Write-Output ('HISTORY_COUNT=' + $rows.Count)
        $n = [math]::Min($Count, $rows.Count)
        for ($i = 0; $i -lt $n; $i++) {
            $r = $rows[$rows.Count - 1 - $i] -split "`t"
            # #num (newest=1) \t id \t kind/subtype \t bytes \t source \t preview
            Write-Output ("#{0}`t{1}`t{2}/{3}`t{4}B`t{5}`t{6}" -f ($i + 1), $r[0], $r[2], $r[3], $r[4], $r[5], $r[6])
        }
    }
    'search' {
        $rows = Read-Index
        $hits = @($rows | Where-Object { $_ -match [regex]::Escape($Query) })
        Write-Output ('HISTORY_MATCHES=' + $hits.Count)
        foreach ($h in $hits) { $r = $h -split "`t"; Write-Output ("{0}`t{1}/{2}`t{3}" -f $r[0], $r[2], $r[3], $r[6]) }
    }
    'get' {
        $rows = Read-Index
        $row = $null
        if ($Id -match '^#?(\d+)$' -and $Id.StartsWith('#')) {
            $k = [int]$Matches[1]; if ($k -ge 1 -and $k -le $rows.Count) { $row = $rows[$rows.Count - $k] }
        }
        if (-not $row) { $row = $rows | Where-Object { ($_ -split "`t")[0] -eq ($Id -replace '^#', '') } | Select-Object -First 1 }
        if (-not $row) { Write-Output 'HISTORY_ERROR=no such entry'; break }
        $r = $row -split "`t"; $eid = $r[0]; $kind = $r[2]
        $cf = Get-ChildItem $root -Filter "$eid*" | Where-Object { $_.Name -ne "$eid.meta" } | Select-Object -First 1
        if (-not $cf) { Write-Output 'HISTORY_ERROR=payload missing'; break }
        Write-Output ('HISTORY_ID=' + $eid)
        Write-Output ('HISTORY_KIND=' + $kind)
        if ($kind -eq 'text') {
            # Re-copy to clipboard and stream the content back.
            powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File (Join-Path $PSScriptRoot 'clipboard-io.ps1') write -Path $cf.FullName *> $null
            Write-Output 'HISTORY_RECOPIED=clipboard'
            Write-Output '-----BEGIN CLIP TEXT-----'
            [Console]::Out.Write((Get-Content -Raw $cf.FullName))
            Write-Output ''
            Write-Output '-----END CLIP TEXT-----'
        }
        else { Write-Output ('HISTORY_PATH=' + $cf.FullName) }
    }
    'rm' {
        $eid = $Id -replace '^#', ''
        Remove-Item (Join-Path $root "$eid*") -Force -ErrorAction SilentlyContinue
        $rows = Read-Index | Where-Object { ($_ -split "`t")[0] -ne $eid }
        $rows | Set-Content -Path $index -Encoding UTF8
        Write-Output ('HISTORY_REMOVED=' + $eid)
    }
    'clear' {
        if (Test-Path $root) { Get-ChildItem $root -Exclude '.enabled' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Output 'HISTORY_CLEARED=1'
    }
    default { Write-Output "HISTORY_ERROR=unknown verb '$Verb'" }
}
