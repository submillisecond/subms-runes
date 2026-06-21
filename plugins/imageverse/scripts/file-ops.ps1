<#
  file-ops - apply a batch of file operations from a manifest, collision-safe,
  with a revert JOURNAL. The img-organize / img-save / img-dedup runes build a
  PLAN (the manifest IS the dry-run preview) and apply it here instead of
  hand-rolling Move/Copy loops.

  Manifest lines are tab-separated; blank lines and # comments are ignored:
     move <TAB> <src> <TAB> <dest>
     copy <TAB> <src> <TAB> <dest>

  MODES (default is a DRY RUN - prints PLAN lines, performs nothing):
    -Apply     perform the FORWARD migration (e.g. files -> album subfolders).
    -Restore   perform a REVERSE/undo run: same moves, but ALSO prune folders
               left empty by the moves (so reverting an organize cleans up the
               now-empty album dirs). Used by `journal revert`.
  Both -Apply and -Restore write a fresh durable journal, so an apply is
  revertible and a restore is re-doable (re-run the next journal). Never
  overwrites: an existing dest gets ' (2)', ' (3)', ...

  The journal is the REVERSE manifest (each `move <src> <dest>` -> `move <dest>
  <src>`), written to the per-plugin app-data dir
  (`%LOCALAPPDATA%\runes\<plugin>\journals\`), NOT the temp workspace.

    -Manifest file   the operations manifest
    -Apply           forward migration (omit both -Apply/-Restore for a dry run)
    -Restore         reverse/undo run (implies -Prune)
    -Prune           after moving, remove any SOURCE folder this run leaves empty
                     (use with -Apply when RE-ORGANIZING into a new scheme, which
                     vacates the old album folders). Truly-empty dirs only.
    -Plugin name     calling plugin/pack (namespaces the journal dir; default 'misc')
    -Journal file    override the auto app-data journal path
#>
param(
    [string]$Manifest,
    [switch]$Apply,
    [switch]$Restore,
    [switch]$Prune,
    [string]$Plugin = 'misc',
    [string]$Journal
)
$ErrorActionPreference = 'Stop'
if (-not $Manifest -or -not (Test-Path $Manifest)) { Write-Output 'OPS_ERROR=missing or unreadable -Manifest'; exit 1 }
$run = $Apply -or $Restore
$doPrune = $Restore -or $Prune

# Default the journal to a DURABLE, per-PLUGIN app-data location (never temp).
if ($run -and -not $Journal) {
    $dataBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA }
    elseif ($env:APPDATA) { $env:APPDATA }
    elseif ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME }
    else { Join-Path $HOME '.local/share' }
    $tag = if ($Restore) { 'restore' } else { 'apply' }
    $Journal = Join-Path $dataBase ("runes\$Plugin\journals\$tag-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + "-$PID.tsv")
}

$rows = Get-Content $Manifest | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') }
$done = 0; $skip = 0; $errs = 0
$rev = New-Object System.Collections.Generic.List[string]
$rev.Add('# runes journal (reverse manifest) - undo/redo this run with: journal revert "<this file name>"')
# Snapshot which dest dirs ALREADY EXIST before we create any, for new-vs-existing
# reporting. Track source dirs too so -Restore can prune the ones it empties.
$dirState = [ordered]@{}
$srcDirs = [ordered]@{}
foreach ($r in $rows) {
    $p = $r -split "`t"; if ($p.Count -lt 3) { continue }
    $d = Split-Path -Parent ($p[2].Trim())
    if ($d -and -not $dirState.Contains($d)) { $dirState[$d] = (Test-Path -LiteralPath $d) }
    $sd = Split-Path -Parent ($p[1].Trim())
    if ($sd) { $srcDirs[$sd] = $true }
}
foreach ($r in $rows) {
    $p = $r -split "`t"
    if ($p.Count -lt 3) { $errs++; Write-Output ('OPS_BAD=' + $r); continue }
    $op = $p[0].Trim().ToLower(); $src = $p[1].Trim(); $dest = $p[2].Trim()
    if ($op -ne 'move' -and $op -ne 'copy') { $errs++; Write-Output ('OPS_BAD_OP=' + $op); continue }
    if (-not (Test-Path -LiteralPath $src)) { $skip++; Write-Output ("SKIP_MISSING`t" + $src); continue }
    $dir = Split-Path -Parent $dest
    $stem = [IO.Path]::GetFileNameWithoutExtension($dest); $ext = [IO.Path]::GetExtension($dest)
    $final = $dest; $k = 2
    while (Test-Path -LiteralPath $final) { $final = Join-Path $dir ("$stem ($k)$ext"); $k++ }
    if ($run) {
        try {
            if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
            if ($op -eq 'move') { Move-Item -LiteralPath $src -Destination $final; $rev.Add("move`t$final`t$src") }
            else { Copy-Item -LiteralPath $src -Destination $final; $rev.Add("# copy - to undo, delete: $final") }
            $done++; Write-Output ("DONE`t$op`t$src`t$final")
        }
        catch { $errs++; Write-Output ("OPS_ERR`t$src`t" + $_.Exception.Message) }
    }
    else {
        $done++; Write-Output ("PLAN`t$op`t$src`t$final")
    }
}
if ($run -and $Journal -and $done -gt 0) {
    $jdir = Split-Path -Parent $Journal
    if ($jdir -and -not (Test-Path $jdir)) { New-Item -ItemType Directory -Force -Path $jdir | Out-Null }
    $rev | Set-Content -Path $Journal -Encoding UTF8
    Write-Output ("OPS_JOURNAL=$Journal")
}
# Prune the source folders this run emptied (vacated album dirs) - on -Restore
# (undo) or explicit -Prune (re-organize into a new scheme).
$pruned = 0
if ($doPrune) {
    foreach ($sd in $srcDirs.Keys) {
        if ((Test-Path -LiteralPath $sd) -and @(Get-ChildItem -LiteralPath $sd -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $sd -Force; $pruned++; Write-Output ("PRUNED`t$sd")
        }
    }
}
# Per-destination-dir summary: NEW vs EXISTING album folder + files added this run
# + TOTAL files now (incl. pre-existing) + subfolder count.
$added = @{}
foreach ($r in $rows) { $p = $r -split "`t"; if ($p.Count -ge 3) { $d = Split-Path -Parent ($p[2].Trim()); if ($d) { $added[$d] = ([int]$added[$d]) + 1 } } }
$newDirs = 0; $exDirs = 0
foreach ($d in $dirState.Keys) {
    $wasNew = -not $dirState[$d]
    if ($wasNew) { $newDirs++ } else { $exDirs++ }
    $tag = if ($wasNew) { 'new' } else { 'existing' }
    $total = 0; $subs = 0
    if (Test-Path -LiteralPath $d) {
        $total = @(Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue).Count
        $subs = @(Get-ChildItem -LiteralPath $d -Directory -ErrorAction SilentlyContinue).Count
    }
    Write-Output ("OPS_DIR`t$d`t$tag`t" + ([int]$added[$d]) + "`t$total`t$subs")
}
$mode = if ($Restore) { 'restore' } elseif ($Apply) { 'apply' } else { 'dry-run' }
Write-Output ("OPS_MODE=$mode")
Write-Output ("OPS_DIRS_NEW=$newDirs OPS_DIRS_EXISTING=$exDirs OPS_PRUNED=$pruned")
Write-Output ("OPS_DONE=$done OPS_SKIP=$skip OPS_ERR=$errs")
