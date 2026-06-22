<#
  Functional tests for the imageverse backend scripts. Runs each script as a child
  process against synthetic fixtures and asserts its OUTPUT CONTRACT - the kind of
  regression (empty scan.tsv, miscounted clusters, dropped coverage) that a
  structural lint can't see. Runs under pwsh on Linux CI and powershell/pwsh locally.
  Exit code 0 = all pass; non-zero = a failure (CI gate).
#>
. (Join-Path $PSScriptRoot '..\lib\test\suite-lib.ps1')
Set-SuiteScripts (Join-Path $PSScriptRoot '..\plugins\imageverse\scripts')

Write-Host "imageverse functional tests"

# 1. image-find: -OutFile must ALSO auto-write scan.tsv, with one line per image,
#    even for no-EXIF screenshots (the -f-drops-empty-args regression).
try {
    $t = NewTemp; $pics = Join-Path $t 'pics'; New-Item -ItemType Directory -Force $pics | Out-Null
    1..4 | ForEach-Object { Set-Content (Join-Path $pics "p$_.png") 'x' }
    $sh = Join-Path $t 'shots.txt'; $sc = Join-Path $t 'scan.tsv'
    $o = Run 'image-find.ps1' @('-Dir', $pics, '-Count', '9', '-OutFile', $sh)
    Check 'image-find reports IMG_COUNT=4' (Has $o 'IMG_COUNT=4')
    Check 'image-find writes shots.txt' (Test-Path $sh)
    Check 'image-find AUTO-writes scan.tsv (no -TsvFile)' (Test-Path $sc)
    Check 'scan.tsv has one line per image (4)' ((Test-Path $sc) -and (@(Get-Content $sc).Count -eq 4))
    Check 'scan.tsv rows are 7-column TSV' ((Test-Path $sc) -and ((@(Get-Content $sc)[0] -split "`t").Count -eq 7))
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL image-find threw: $_" -ForegroundColor Red }

# 2. cluster: time-session split (no GPS).
try {
    $t = NewTemp; $sc = Join-Path $t 'scan.tsv'
    @(
        "2026-05-12 17:50:00`t1`t`t$t/a.png`t`t`t",
        "2026-05-12 17:50:30`t1`t`t$t/b.png`t`t`t",   # 30s -> same cluster
        "2026-05-13 09:00:00`t1`t`t$t/c.png`t`t`t"    # next day -> new cluster
    ) | Set-Content $sc
    $o = Run 'cluster.ps1' @('-Tsv', $sc)
    Check 'cluster groups by time into 2 clusters' (Has $o 'CLUSTER_COUNT=2')
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL cluster(time) threw: $_" -ForegroundColor Red }

# 3. cluster: geo split (haversine must not collapse - the $R/$r case-insensitive bug).
try {
    $t = NewTemp; $sc = Join-Path $t 'scan.tsv'
    @(
        "2026-06-01 12:00:00`t1`t`t$t/p1.jpg`t48.858`t2.294`t",
        "2026-06-01 12:05:00`t1`t`t$t/p2.jpg`t48.860`t2.295`t",   # same place -> same cluster
        "2026-06-01 12:10:00`t1`t`t$t/far.jpg`t40.700`t-74.000`t" # NYC -> geo split
    ) | Set-Content $sc
    $o = Run 'cluster.ps1' @('-Tsv', $sc)
    Check 'cluster splits a far GPS jump (haversine works)' (Has $o 'CLUSTER_COUNT=2')
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL cluster(geo) threw: $_" -ForegroundColor Red }

# 4. build-manifest: -Class is a DIR of batch files; expands index ranges; coverage clean.
try {
    $t = NewTemp; $src = Join-Path $t 'src'; $cls = Join-Path $t 'cls'
    New-Item -ItemType Directory -Force $src, $cls | Out-Null
    1..5 | ForEach-Object { Set-Content (Join-Path $src "img$_.png") 'x' }
    $sh = Join-Path $t 'shots.txt'; $sc = Join-Path $t 'scan.tsv'
    @(1..5 | ForEach-Object { Join-Path $src "img$_.png" }) | Set-Content $sh
    @(1..5 | ForEach-Object { "2026-05-1$_ 10:00:0$_`t1`t`t$(Join-Path $src "img$_.png")`t`t`t" }) | Set-Content $sc
    "a`t1-3" | Set-Content (Join-Path $cls 'batch01.tsv')
    "b`t4-5" | Set-Content (Join-Path $cls 'batch02.tsv')
    $o = Run 'build-manifest.ps1' @('-Class', $cls, '-Shots', $sh, '-Meta', $sc, '-Base', $t, '-Manifest', (Join-Path $t 'm.tsv'))
    Check 'build-manifest concatenates cls dir + expands ranges (5)' (Has $o 'MANIFEST_COUNT=5')
    Check 'build-manifest coverage clean (5 of 5, 0 unassigned)' (Has $o 'assigned 5 of 5; unassigned 0')
    Check 'build-manifest emits batch timings' (Has $o 'MANIFEST_BATCHES=2')
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL build-manifest threw: $_" -ForegroundColor Red }

# 5. build-manifest: coverage MUST catch a dropped image (the safety net).
try {
    $t = NewTemp; $src = Join-Path $t 'src'; $cls = Join-Path $t 'cls'
    New-Item -ItemType Directory -Force $src, $cls | Out-Null
    1..3 | ForEach-Object { Set-Content (Join-Path $src "img$_.png") 'x' }
    $sh = Join-Path $t 'shots.txt'
    @(1..3 | ForEach-Object { Join-Path $src "img$_.png" }) | Set-Content $sh
    "a`t1-2" | Set-Content (Join-Path $cls 'batch01.tsv')   # drops image 3
    $o = Run 'build-manifest.ps1' @('-Class', $cls, '-Shots', $sh, '-Base', $t, '-Manifest', (Join-Path $t 'm.tsv'))
    Check 'coverage flags the dropped image (unassigned 1)' (Has $o 'unassigned 1')
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL build-manifest(coverage) threw: $_" -ForegroundColor Red }

# 6. file-ops: apply a move, then restore it (round-trip via the journal).
try {
    $t = NewTemp; $src = Join-Path $t 'src'; New-Item -ItemType Directory -Force $src | Out-Null
    $a = Join-Path $src 'one.png'; Set-Content $a 'x'
    $dst = Join-Path $t 'album\one-2026.png'
    $man = Join-Path $t 'manifest.tsv'
    "move`t$a`t$dst" | Set-Content $man
    $o = Run 'file-ops.ps1' @('-Manifest', $man, '-Apply', '-Plugin', 'ivt')
    Check 'file-ops apply moves the file' ((Test-Path $dst) -and -not (Test-Path $a))
    $jr = ($o | Select-String 'OPS_JOURNAL=' | Select-Object -First 1) -replace '.*OPS_JOURNAL=', ''
    Check 'file-ops writes a journal' ($jr -and (Test-Path $jr.Trim()))
    $o2 = Run 'file-ops.ps1' @('-Manifest', $jr.Trim(), '-Restore', '-Plugin', 'ivt')
    Check 'file-ops restore puts it back' ((Test-Path $a) -and -not (Test-Path $dst))
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL file-ops threw: $_" -ForegroundColor Red }

# 7. prefs: set then get round-trips the scheme.
try {
    $t = NewTemp; $d = Join-Path $t 'folder'
    $env:RUNES_PREFS_DIR = $t  # isolate from the real prefs store if the script honors it
    Run 'prefs.ps1' @('set', '-Dir', $d, '-Plugin', 'ivt', '-Scheme', 'content-albums', '-Op', 'move', '-Albums', 'x,y') | Out-Null
    $o = Run 'prefs.ps1' @('get', '-Dir', $d, '-Plugin', 'ivt')
    Check 'prefs get returns the saved scheme' (Has $o 'content-albums')
    Remove-Item Env:\RUNES_PREFS_DIR -ErrorAction SilentlyContinue
    Remove-Item $t -Recurse -Force
}
catch { $script:fail++; Write-Host "  FAIL prefs threw: $_" -ForegroundColor Red }

Complete-Suite 'imageverse'
