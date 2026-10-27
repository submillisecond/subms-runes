# cluster: group an image-find scan into trips and sessions by time gaps and GPS jumps, so classification runs per cluster.
# Flags and the CLUSTER line: ../contract/CONTRACTS.md 1.4, 2.3.
param(
    [Parameter(Mandatory)][string]$Tsv,
    [int]$GapMinutes = 2,       # NO-GPS (screenshots): a session gap > this starts a new cluster
    [double]$GeoKm = 2.0,       # GPS: a place jump > this km starts a new cluster
    [double]$TripGapHours = 8   # GPS + SAME place: a time gap > this (e.g. next day) starts a new cluster
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Tsv)) { Write-Output "CLUSTER_ERROR=no TSV at '$Tsv' - run image-find with -OutFile (it auto-writes scan.tsv alongside) or -TsvFile first"; exit 1 }

$recs = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($line in Get-Content $Tsv) {
    $i++
    if (-not $line.Trim()) { continue }
    $c = $line -split "`t"
    if ($c.Count -lt 4) { continue }
    $dt = $null
    if ($c[0] -match '^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}') { try { $dt = [datetime]::Parse(($c[0] -replace 'T', ' ')) } catch {} }
    $lat = $null; $lon = $null
    if ($c.Count -ge 6 -and $c[4] -match '^-?\d+(\.\d+)?$' -and $c[5] -match '^-?\d+(\.\d+)?$') { $lat = [double]$c[4]; $lon = [double]$c[5] }
    $recs.Add([pscustomobject]@{ idx = $i; dt = $dt; lat = $lat; lon = $lon })
}
if ($recs.Count -eq 0) { Write-Output 'CLUSTER_COUNT=0'; return }

function Haversine($la1, $lo1, $la2, $lo2) {
    # PowerShell variables are case-insensitive - do NOT use $R and $r together.
    $km = 6371.0; $deg = [math]::PI / 180
    $dLa = ($la2 - $la1) * $deg; $dLo = ($lo2 - $lo1) * $deg
    $a = [math]::Sin($dLa / 2) * [math]::Sin($dLa / 2) + [math]::Cos($la1 * $deg) * [math]::Cos($la2 * $deg) * [math]::Sin($dLo / 2) * [math]::Sin($dLo / 2)
    $km * 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))
}

# Sort by capture time (undated last), then segment into contiguous clusters.
$sorted = $recs | Sort-Object @{ Expression = { if ($_.dt) { $_.dt } else { [datetime]::MaxValue } } }, idx
$clusters = New-Object System.Collections.Generic.List[object]
$cur = $null
$prev = $null
$curHasGeo = $false   # does the RUNNING cluster have any GPS anchor yet?
foreach ($r in $sorted) {
    $brk = $false
    if (-not $cur) { $brk = $true }
    else {
        $bothGeo = ($null -ne $r.lat) -and ($null -ne $prev.lat)
        if ($bothGeo) {
            # GPS regime (phone photos): place dominates. Same place tolerates a
            # long within-trip time gap; only a different day/visit splits it.
            if ((Haversine $prev.lat $prev.lon $r.lat $r.lon) -gt $GeoKm) { $brk = $true }
            elseif ($r.dt -and $prev.dt -and (($r.dt - $prev.dt).TotalHours -gt $TripGapHours)) { $brk = $true }
        }
        elseif ($curHasGeo) {
            # A record with no GPS inside a GPS trip (usually a video) stays in the trip;
            # only a day-sized gap ends it.
            if ($r.dt -and $prev.dt) { if (($r.dt - $prev.dt).TotalHours -gt $TripGapHours) { $brk = $true } }
            elseif (($r.dt -and -not $prev.dt) -or (-not $r.dt -and $prev.dt)) { $brk = $true }
        }
        else {
            # No-GPS regime (screenshots): tight time-session gap.
            if ($r.dt -and $prev.dt) { if (($r.dt - $prev.dt).TotalMinutes -gt $GapMinutes) { $brk = $true } }
            elseif (($r.dt -and -not $prev.dt) -or (-not $r.dt -and $prev.dt)) { $brk = $true }
        }
    }
    if ($brk) { $cur = New-Object System.Collections.Generic.List[object]; $clusters.Add($cur); $curHasGeo = $false }
    $cur.Add($r); $prev = $r
    if ($null -ne $r.lat) { $curHasGeo = $true }
}

function Compress-Ranges($nums) {
    $s = @($nums | Sort-Object); if ($s.Count -eq 0) { return '' }
    $out = @(); $a = $s[0]; $b = $s[0]
    for ($k = 1; $k -lt $s.Count; $k++) {
        if ($s[$k] -eq $b + 1) { $b = $s[$k] }
        else { $out += $(if ($a -eq $b) { "$a" } else { "$a-$b" }); $a = $s[$k]; $b = $s[$k] }
    }
    $out += $(if ($a -eq $b) { "$a" } else { "$a-$b" })
    $out -join ','
}

# Emit newest cluster first (matches the rest of the UI).
Write-Output ("CLUSTER_COUNT=" + $clusters.Count)
$ordered = $clusters | Sort-Object @{ Expression = { $m = ($_ | Where-Object { $_.dt } | Select-Object -First 1); if ($m) { $m.dt } else { [datetime]::MinValue } }; Descending = $true }
$id = 0
foreach ($cl in $ordered) {
    $id++
    $byTime = @($cl | Sort-Object @{ Expression = { if ($_.dt) { $_.dt } else { [datetime]::MaxValue } } })
    $idxs = @($cl | ForEach-Object idx)
    $reps = @($byTime[0].idx)
    if ($byTime.Count -ge 3) { $reps += $byTime[[int]($byTime.Count / 2)].idx }
    if ($byTime.Count -ge 2) { $reps += $byTime[-1].idx }
    $reps = @($reps | Select-Object -Unique)
    $dated = @($byTime | Where-Object { $_.dt })
    $span = if ($dated.Count) { ('{0:yyyy-MM-dd HH:mm}..{1:HH:mm}' -f $dated[0].dt, $dated[-1].dt) } else { 'undated' }
    $geo = '-'
    $g = @($cl | Where-Object { $null -ne $_.lat })
    if ($g.Count) { $geo = '{0:0.000},{1:0.000}' -f (($g | Measure-Object lat -Average).Average), (($g | Measure-Object lon -Average).Average) }
    Write-Output ("CLUSTER`t$id`t$($idxs.Count)`t$span`t$geo`treps=$($reps -join ',')`t" + (Compress-Ranges $idxs))
}
