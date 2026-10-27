# journal: list, show and revert file-ops journals. A revert writes its own journal, so it can be redone.
# journal.ps1 [list] | show <name> | revert <name>. Contract: ../contract/CONTRACTS.md 2.10.
param(
    [Parameter(Position = 0)][string]$Action = 'list',
    [Parameter(Position = 1)][string]$Name
)
$ErrorActionPreference = 'Stop'
$dataBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA }
elseif ($env:APPDATA) { $env:APPDATA }
elseif ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME }
else { Join-Path $HOME '.local/share' }
# Journals are per-plugin: %LOCALAPPDATA%\runes\<plugin>\journals\. Scan all plugins.
$root = Join-Path $dataBase 'runes'

if (-not (Test-Path $root)) { Write-Output "JOURNAL_ROOT=$root"; Write-Output 'JOURNAL_COUNT=0'; return }
$files = @(Get-ChildItem $root -Recurse -Filter *.tsv -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -eq 'journals' } | Sort-Object LastWriteTime -Descending)

function Resolve-Journal($n) {
    if (-not $n) { return $null }
    if (Test-Path -LiteralPath $n) { return (Get-Item -LiteralPath $n) }
    $files | Where-Object { $_.Name -eq $n -or $_.BaseName -eq $n } | Select-Object -First 1
}

switch ($Action.ToLower()) {
    'show' {
        $f = Resolve-Journal $Name
        if (-not $f) { Write-Output "JOURNAL_ERROR=no such journal '$Name'"; exit 1 }
        Get-Content $f.FullName
    }
    'revert' {
        $f = Resolve-Journal $Name
        if (-not $f) { Write-Output "JOURNAL_ERROR=no such journal '$Name'"; exit 1 }
        Write-Output ("Reverting " + $f.Name + " ...")
        # -Restore performs the reverse moves AND prunes any folders left empty,
        # and writes its own journal so the revert can itself be redone.
        $plugin = $f.Directory.Parent.Name
        & (Join-Path $PSScriptRoot 'file-ops.ps1') -Manifest $f.FullName -Restore -Plugin $plugin
    }
    default {
        Write-Output ("JOURNAL_ROOT=" + $root)
        Write-Output ("JOURNAL_COUNT=" + $files.Count)
        foreach ($f in $files) {
            $plugin = $f.Directory.Parent.Name
            $moves = @(Get-Content $f.FullName | Where-Object { $_ -match "^move`t" })
            $roots = $moves | ForEach-Object { $p = $_ -split "`t"; if ($p.Count -ge 2) { Split-Path -Leaf (Split-Path -Parent $p[1]) } } | Sort-Object -Unique
            Write-Output ("  [{0}] {1}  {2}  {3} moves  -> {4}" -f $plugin, $f.Name, $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $moves.Count, ($roots -join ', '))
        }
    }
}
