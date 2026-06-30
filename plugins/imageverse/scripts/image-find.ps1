<#
  image-find - the image-file finder for the images pack. Locates image files in
  a folder by predicate (recency / name / recurse), with a sortable date (EXIF
  DateTimeOriginal else file mtime) and optional content hash, and Screenshots
  auto-detect. One tool for all three uses: "recent screenshots" (img), whole-tree
  find + hashes (img-dedup), and recursive enumeration for re-organize (img-organize).

  Selection (combine freely; with NO filter + no -Dir, returns the single most recent):
    -Count N      last N (after the other filters)
    -Minutes X    modified within the last X minutes
    -Today / -Yesterday
    -Since "..." / -Until "..."   date-time bounds (any parseable form)
    -Within spec  calendar bucket (0=current,1=previous): t|today|0d, yesterday|1d, <N>h|d|w|m|y
    -Name glob    filename contains this
    -Dir path     where to scan: a literal path, OR the keyword `screenshots` /
                  `downloads` (resolved to the OS folders). Omit = `screenshots`.
    -Recurse      include subfolders (needed when RE-ORGANIZING a structured folder)
    -NoVideo      EXCLUDE video files. Videos (mp4/mov/...) are matched BY DEFAULT -
                  a photo library holds clips too, and leaving them behind is the
                  bug this fixes. Pass -NoVideo for an images-only scan. Videos carry
                  no GDI+ EXIF here, so they get the file-time date and blank
                  GPS/camera (like screenshots) - they still cluster by time and are
                  thumbnailed as contact sheets by `thumbs`.
    -NoAudio      EXCLUDE audio files. Audio (mp3/m4a/wav/...) is also matched BY
                  DEFAULT (voice memos in a camera roll). Audio has NO frames, so it
                  is never thumbnailed/content-classified - it is grouped purely by
                  time/cluster and moved (extension kept) like any file.
    -Hash         also emit a SHA1 per file (for dedup)
    -OutFile f    also write just the absolute paths (one per line) to f, so
                  `thumbs -List f` consumes them directly (one shell, one path)
    -TsvFile f    also write the full TSV (below) to f, so `build-manifest -Meta f`
                  can name/order by the true EXIF capture time incl. sub-second
  Prints IMG_DIR (each searched), IMG_COUNT, then one TSV line per file (newest
  first):  <yyyy-MM-dd HH:mm:ss[.fff]> \t <size> \t <sha1-or-empty> \t <path> \t
  <lat> \t <lon> \t <camera>.  The date carries EXIF SubSecTimeOriginal (`.fff`)
  when present (burst ordering). GPS/camera/subsec are ALWAYS read (free - the file
  is already open for the EXIF date); blank when absent (e.g. screenshots).
  Lists only; never moves or modifies files.
#>
param(
    [int]$Count = 0,
    [int]$Minutes = 0,
    [switch]$Today,
    [switch]$Yesterday,
    [string]$Since,
    [string]$Until,
    [string]$Within,
    [string]$Name,
    [string]$Dir,
    [switch]$Recurse,
    [switch]$NoVideo,
    [switch]$NoAudio,
    [switch]$Hash,
    [string]$OutFile,
    [string]$TsvFile,
    [string]$HashCache
)
$ErrorActionPreference = 'SilentlyContinue'
# Windows-only (GDI+). Off Windows the type is absent; degrade to file-time dates
# rather than dying at load - Read-Exif's own try/catch handles the missing type.
try { Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue | Out-Null } catch {}

function Get-ShotDirs {
    $c = @()
    if ($env:USERPROFILE) { $c += (Join-Path $env:USERPROFILE 'Pictures\Screenshots') }
    foreach ($od in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) { if ($od) { $c += (Join-Path $od 'Pictures\Screenshots') } }
    $reg = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).'{B7BEDE81-DF94-4682-A7D8-57A52620B86F}'
    if ($reg) { $c += [Environment]::ExpandEnvironmentVariables($reg) }
    $c
}
function Get-DownloadDirs {
    $c = @()
    if ($env:USERPROFILE) { $c += (Join-Path $env:USERPROFILE 'Downloads') }
    foreach ($od in @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial)) { if ($od) { $c += (Join-Path $od 'Downloads') } }
    $reg = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).'{374DE290-123F-4565-9164-39C4925E467B}'
    if ($reg) { $c += [Environment]::ExpandEnvironmentVariables($reg) }
    $c
}

# -Dir accepts the special KEYWORDS `screenshots` / `downloads` (resolved to the OS
# folders) or a literal path; omitting -Dir defaults to `screenshots`.
$dirs = New-Object System.Collections.Generic.List[string]
$key = if ($Dir) { $Dir.Trim() } else { 'screenshots' }
switch -Regex ($key.ToLower()) {
    '^screenshots?$' { foreach ($c in (Get-ShotDirs | Select-Object -Unique)) { if (Test-Path $c) { $dirs.Add($c) } } }
    '^downloads?$' { foreach ($c in (Get-DownloadDirs | Select-Object -Unique)) { if (Test-Path $c) { $dirs.Add($c) } } }
    default { $dirs.Add($Dir) }
}

if ($dirs.Count -eq 0) {
    Write-Output 'IMG_COUNT=0'
    Write-Output ("IMG_NOTE=no folder resolved for '$key'; pass -Dir <path> or the keywords screenshots/downloads")
    return
}

$exts = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')
# Video + audio files live alongside photos in a camera roll (clips, voice memos),
# so BOTH are matched BY DEFAULT - a re-organize must sweep them into the trip's
# album, not leave them behind; -NoVideo / -NoAudio opt out. Kept SEPARATE from
# $exts so we can report how many of each matched (IMG_VIDEOS / IMG_AUDIO). Audio
# has no frames, so it is never thumbnailed - it is grouped purely by time/cluster.
$vexts = @('.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp', '.3g2', '.wmv', '.mpg', '.mpeg', '.mts', '.m2ts')
$aexts = @('.mp3', '.m4a', '.wav', '.aac', '.ogg', '.oga', '.opus', '.flac', '.wma', '.amr', '.aiff', '.aif')
$match = $exts
if (-not $NoVideo) { $match += $vexts }
if (-not $NoAudio) { $match += $aexts }
# `_duplicates` is the archive for perceptual-duplicate re-shares (see img-organize's
# dedup step) - it gets SPECIAL HANDLING: never scanned, so it is not re-organized,
# not re-flagged, and not used as a routing reference. Always excluded, even with -Recurse.
$files = foreach ($d in $dirs) {
    Get-ChildItem -Path $d -File -Recurse:$Recurse -ErrorAction SilentlyContinue |
        Where-Object { $match -contains $_.Extension.ToLower() -and $_.FullName -notmatch '[\\/]_duplicates[\\/]' }
}
$files = $files | Sort-Object LastWriteTime -Descending

if ($Minutes -gt 0) { $cut = (Get-Date).AddMinutes(-$Minutes); $files = $files | Where-Object { $_.LastWriteTime -ge $cut } }
if ($Today) { $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today } }
if ($Yesterday) {
    $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today.AddDays(-1) -and $_.LastWriteTime -lt [datetime]::Today }
}
if ($Since) { $s = [datetime]$Since; $files = $files | Where-Object { $_.LastWriteTime -ge $s } }
if ($Until) { $u = [datetime]$Until; $files = $files | Where-Object { $_.LastWriteTime -le $u } }
if ($Within) {
    $w = $Within.Trim().ToLower()
    if ($w -eq 'today' -or $w -eq 't') {
        $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today }
    }
    elseif ($w -eq 'yesterday') {
        $files = $files | Where-Object { $_.LastWriteTime -ge [datetime]::Today.AddDays(-1) -and $_.LastWriteTime -lt [datetime]::Today }
    }
    elseif ($w -match '^(\d+)\s*([hdwmy])$') {
        $n = [int]$Matches[1]; $u = $Matches[2]; $now = Get-Date
        $cur = switch ($u) {
            'h' { $now.Date.AddHours($now.Hour) }
            'd' { $now.Date }
            'w' { $dw = [int]$now.DayOfWeek; if ($dw -eq 0) { $dw = 7 }; $now.Date.AddDays(-($dw - 1)) }
            'm' { [datetime]::new($now.Year, $now.Month, 1) }
            'y' { [datetime]::new($now.Year, 1, 1) }
        }
        $lower = switch ($u) { 'h' { $cur.AddHours(-$n) } 'd' { $cur.AddDays(-$n) } 'w' { $cur.AddDays(-7 * $n) } 'm' { $cur.AddMonths(-$n) } 'y' { $cur.AddYears(-$n) } }
        $k = $n - 1
        $upper = switch ($u) { 'h' { $cur.AddHours(-$k) } 'd' { $cur.AddDays(-$k) } 'w' { $cur.AddDays(-7 * $k) } 'm' { $cur.AddMonths(-$k) } 'y' { $cur.AddYears(-$k) } }
        $files = $files | Where-Object { $_.LastWriteTime -ge $lower -and $_.LastWriteTime -lt $upper }
    }
}
if ($Name) { $files = $files | Where-Object { $_.Name -like "*$Name*" } }

$anyFilter = ($Count -gt 0) -or ($Minutes -gt 0) -or $Today -or $Yesterday -or $Since -or $Until -or $Within -or $Name -or $Dir
if (-not $anyFilter) { $Count = 1 }
if ($Count -gt 0) { $files = $files | Select-Object -First $Count }
$files = @($files)

# Guard: a tab or newline in a path would corrupt the TSV (field/line splitting)
# and silently misfile / break a revert downstream. Skip + warn rather than emit a
# poisoned record. (Impossible on Windows - illegal in NTFS names - but defensive.)
$skipped = @($files | Where-Object { $_.FullName -match "[`t`r`n]" })
if ($skipped.Count -gt 0) {
    $files = @($files | Where-Object { $_.FullName -notmatch "[`t`r`n]" })
    Write-Output ('IMG_SKIPPED=' + $skipped.Count + ' (path contains tab/newline)')
    foreach ($s in $skipped) { Write-Output ('IMG_SKIPPED_PATH=' + ($s.FullName -replace "[`t`r`n]", '?')) }
}

# EXIF reader: DateTimeOriginal + GPS lat/lon + camera, all from ONE open (the
# file is opened anyway for the date, so GPS/camera are essentially free). GPS is
# the strongest album signal for photo libraries (trip / location).
function Read-Exif($path) {
    $r = @{ date = $null; subsec = ''; lat = ''; lon = ''; cam = '' }
    try {
        $fs = [IO.File]::OpenRead($path)
        try {
            $img = [System.Drawing.Image]::FromStream($fs, $false, $false)
            try {
                $ids = $img.PropertyIdList
                if ($ids -contains 36867) {
                    $s = ([Text.Encoding]::ASCII.GetString($img.GetPropertyItem(36867).Value)).Trim([char]0).Trim()
                    try { $r.date = [datetime]::ParseExact($s, 'yyyy:MM:dd HH:mm:ss', $null) } catch {}
                }
                # SubSecTimeOriginal (0x9291) - fractional seconds, for burst ordering.
                if ($ids -contains 37521) {
                    $ss = ([Text.Encoding]::ASCII.GetString($img.GetPropertyItem(37521).Value)).Trim([char]0).Trim()
                    $ss = ($ss -replace '\D', ''); if ($ss) { $r.subsec = ($ss + '000').Substring(0, 3) }  # normalise to 3 digits, fraction-aligned
                }
                function Rat([byte[]]$b, [int]$o) { $n = [BitConverter]::ToUInt32($b, $o); $d = [BitConverter]::ToUInt32($b, $o + 4); if ($d -eq 0) { 0 } else { [double]$n / $d } }
                function Dms([byte[]]$b) { (Rat $b 0) + (Rat $b 8) / 60 + (Rat $b 16) / 3600 }
                if (($ids -contains 2) -and ($ids -contains 4)) {
                    $lat = Dms $img.GetPropertyItem(2).Value
                    $lon = Dms $img.GetPropertyItem(4).Value
                    if ($ids -contains 1) { $ref = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(1).Value).Trim([char]0); if ($ref -eq 'S') { $lat = -$lat } }
                    if ($ids -contains 3) { $ref = [Text.Encoding]::ASCII.GetString($img.GetPropertyItem(3).Value).Trim([char]0); if ($ref -eq 'W') { $lon = -$lon } }
                    $r.lat = '{0:0.000000}' -f $lat; $r.lon = '{0:0.000000}' -f $lon
                }
                if ($ids -contains 272) { $r.cam = ([Text.Encoding]::ASCII.GetString($img.GetPropertyItem(272).Value)).Trim([char]0).Trim() }
            }
            finally { $img.Dispose() }
        }
        finally { $fs.Close() }
    }
    catch {}
    $r
}

# Date from FILENAME, for files whose EXIF was stripped (WhatsApp re-encodes and
# drops EXIF + GPS; screenshots/Signal carry the date only in the name). Tried
# AFTER EXIF, BEFORE mtime - mtime on a shared/downloaded file is the SAVE date, not
# capture. Patterns: Android/screenshot `YYYYMMDD_HHMMSS`, WhatsApp `IMG-YYYYMMDD-WA`
# (date-only), ISO `YYYY-MM-DD`. Date-only gets 00:00:00 so a day's shares group.
function Get-NameDate($name) {
    if ($name -match '(20\d{2})[-_]?(\d{2})[-_]?(\d{2})[-_ T]+(\d{2})[-_:.]?(\d{2})[-_:.]?(\d{2})') {
        try { return [datetime]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4], [int]$Matches[5], [int]$Matches[6]) } catch {}
    }
    if ($name -match '(20\d{2})-(\d{2})-(\d{2})') {
        try { return [datetime]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], 0, 0, 0) } catch {}
    }
    if ($name -match '(20\d{2})(\d{2})(\d{2})') {
        try { return [datetime]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], 0, 0, 0) } catch {}
    }
    return $null
}

foreach ($d in $dirs) { Write-Output ('IMG_DIR=' + $d) }
Write-Output ('IMG_COUNT=' + $files.Count)
if (-not $NoVideo) {
    Write-Output ('IMG_VIDEOS=' + @($files | Where-Object { $vexts -contains $_.Extension.ToLower() }).Count)
}
if (-not $NoAudio) {
    Write-Output ('IMG_AUDIO=' + @($files | Where-Object { $aexts -contains $_.Extension.ToLower() }).Count)
}
# When a caller asks for the paths file, always emit the sibling scan.tsv too
# (the EXIF/GPS data is computed regardless) so the cluster step never finds it
# missing - the canonical workspace path is <outfile-dir>\scan.tsv.
if ($OutFile -and -not $TsvFile) { $TsvFile = Join-Path (Split-Path -Parent $OutFile) 'scan.tsv' }
if ($OutFile) {
    @($files | ForEach-Object { $_.FullName }) | Set-Content -Path $OutFile -Encoding UTF8
    Write-Output ('IMG_OUTFILE=' + $OutFile)
}
# Optional tier-0 hash cache: avoid re-reading a file's bytes to rehash it when
# nothing about it changed. Keyed by path; signature = size + mtime + ctime ticks.
# ctime (creation time) is the file-IDENTITY proxy: a DIFFERENT file replacing a
# path gets a new creation time, so "same path, same size+mtime, different file"
# still misses the cache and forces a rehash (no FileId P/Invoke needed). The hash
# stays the authority - this only skips recomputation, never decides content.
$hcOld = @{}; $hcNew = @{}
if ($HashCache -and (Test-Path $HashCache)) {
    foreach ($l in Get-Content $HashCache) {
        $c = $l -split "`t"; if ($c.Count -ge 3) { $hcOld[$c[0]] = @{ sig = $c[1]; sha1 = $c[2] } }
    }
}

# TSV: <date[.subsec]> <size> <sha1-or-empty> <path> <lat> <lon> <camera>.
# The date carries EXIF sub-second (e.g. 2026-05-03 19:16:21.042) when present, so
# build-manifest can order/name bursts by true capture time (-Meta consumes this).
$tsv = New-Object System.Collections.Generic.List[string]
$dsExif = 0; $dsName = 0; $dsMtime = 0
foreach ($f in $files) {
    $ex = Read-Exif $f.FullName
    # Date priority: EXIF capture time > date parsed from filename > file mtime.
    if ($ex.date) { $dt = $ex.date; $dsExif++ }
    else {
        $nd = Get-NameDate $f.Name
        if ($nd) { $dt = $nd; $dsName++ } else { $dt = $f.LastWriteTime; $dsMtime++ }
    }
    $dtStr = '{0:yyyy-MM-dd HH:mm:ss}' -f $dt
    if ($ex.subsec) { $dtStr += '.' + $ex.subsec }
    $h = ''
    if ($Hash) {
        if ($HashCache) {
            $sig = "$($f.Length)_$($f.LastWriteTimeUtc.Ticks)_$($f.CreationTimeUtc.Ticks)"
            $cached = $hcOld[$f.FullName]
            if ($cached -and $cached.sig -eq $sig) { $h = $cached.sha1 }
            else { $h = (Get-FileHash -Algorithm SHA1 -LiteralPath $f.FullName).Hash }
            $hcNew[$f.FullName] = @{ sig = $sig; sha1 = $h }
        }
        else { $h = (Get-FileHash -Algorithm SHA1 -LiteralPath $f.FullName).Hash }
    }
    # -join, NOT -f: the format operator drops trailing null/empty args (lat/lon/cam
    # are empty for screenshots), throwing "index out of range" and emptying the TSV.
    $tsv.Add((@($dtStr, $f.Length, $h, $f.FullName, $ex.lat, $ex.lon, $ex.cam) -join "`t"))
}
Write-Output ("IMG_DATESRC=exif=$dsExif name=$dsName mtime=$dsMtime")
foreach ($l in $tsv) { Write-Output $l }
if ($TsvFile) {
    $tsv | Set-Content -Path $TsvFile -Encoding UTF8
    Write-Output ('IMG_TSVFILE=' + $TsvFile)
}
# Persist the tier-0 cache, REBUILT from this scan's files (self-pruning: entries
# for files no longer scanned drop out). Intended for full -Recurse indexing
# scans; a filtered scan simply shrinks the cache, which only costs recomputation
# next time. path <TAB> sig <TAB> sha1.
if ($HashCache -and $Hash) {
    $hcLines = $hcNew.GetEnumerator() | ForEach-Object { $_.Key + "`t" + $_.Value.sig + "`t" + $_.Value.sha1 }
    $hcLines | Set-Content -Path $HashCache -Encoding UTF8
    Write-Output ('IMG_HASHCACHE=' + $HashCache)
}
