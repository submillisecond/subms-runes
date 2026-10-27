# settings: the imageverse settings store (home, people, objects, defaults) under %LOCALAPPDATA%\runes\imageverse\settings.
# settings.ps1 [show] | get | home -Lat -Lon [-Town] [-RadiusKm] | person add|list|remove|rename | object add|list|remove | default -Key -Value
param(
    [Parameter(Position = 0)][string]$Cmd = 'show',
    [Parameter(Position = 1)][string]$Sub,
    [string]$Name,
    [string]$Label,
    [string]$To,
    [string]$Images,
    [double]$Lat = [double]::NaN,
    [double]$Lon = [double]::NaN,
    [string]$Town,
    [double]$RadiusKm = 0,
    [string]$Key,
    [string]$Value,
    [string]$Plugin = 'imageverse'
)
$ErrorActionPreference = 'Stop'

$dataBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA }
elseif ($env:APPDATA) { $env:APPDATA }
elseif ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME }
else { Join-Path $HOME '.local/share' }
$root = Join-Path $dataBase "runes\$Plugin\settings"
$peopleDir = Join-Path $root 'people'
$objectsDir = Join-Path $root 'objects'
$jsonPath = Join-Path $root 'settings.json'
New-Item -ItemType Directory -Force -Path $root, $peopleDir, $objectsDir | Out-Null

$imgExts = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')

function Load-Json {
    if (Test-Path $jsonPath) {
        try { return (Get-Content -Raw $jsonPath | ConvertFrom-Json) } catch {}
    }
    [pscustomobject]@{ home = $null; defaults = [pscustomobject]@{} }
}
function Save-Json($o) { $o | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8 }

# Copy reference images into a label dir (dedup by content hash); returns count added.
function Add-Refs($destDir, $imagesCsv) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $existing = @{}
    foreach ($f in (Get-ChildItem -LiteralPath $destDir -File -ErrorAction SilentlyContinue)) {
        $existing[(Get-FileHash -Algorithm SHA1 -LiteralPath $f.FullName).Hash] = $true
    }
    $added = 0
    foreach ($raw in ($imagesCsv -split ',')) {
        $src = $raw.Trim(); if (-not $src) { continue }
        # accept a glob or a literal path
        $matches = @(Get-ChildItem -Path $src -File -ErrorAction SilentlyContinue)
        if ($matches.Count -eq 0 -and (Test-Path -LiteralPath $src)) { $matches = @(Get-Item -LiteralPath $src) }
        foreach ($m in $matches) {
            if ($imgExts -notcontains $m.Extension.ToLower()) { Write-Output ("SETTINGS_SKIP=not an image: " + $m.FullName); continue }
            $h = (Get-FileHash -Algorithm SHA1 -LiteralPath $m.FullName).Hash
            if ($existing.ContainsKey($h)) { continue }
            $existing[$h] = $true
            $dest = Join-Path $destDir ($h.Substring(0, 12) + $m.Extension.ToLower())
            Copy-Item -LiteralPath $m.FullName -Destination $dest
            $added++
        }
    }
    $added
}

function Count-Refs($dir) { @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue | Where-Object { $imgExts -contains $_.Extension.ToLower() }).Count }

switch ($Cmd.ToLower()) {
    'home' {
        $o = Load-Json
        $h = if ($o.home) { $o.home } else { [pscustomobject]@{ lat = $null; lon = $null; town = $null; radiusKm = 25 } }
        if (-not [double]::IsNaN($Lat)) { $h.lat = $Lat }
        if (-not [double]::IsNaN($Lon)) { $h.lon = $Lon }
        if ($Town) { $h.town = $Town }
        if ($RadiusKm -gt 0) { $h.radiusKm = $RadiusKm }
        if (-not $h.radiusKm) { $h.radiusKm = 25 }
        $o.home = $h; Save-Json $o
        Write-Output ("SETTINGS_HOME=lat=$($h.lat) lon=$($h.lon) town=$($h.town) radiusKm=$($h.radiusKm)")
    }
    'default' {
        if (-not $Key) { Write-Output 'SETTINGS_ERROR=default needs -Key'; exit 1 }
        $o = Load-Json
        if (-not $o.defaults) { $o | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force }
        $o.defaults | Add-Member -NotePropertyName $Key -NotePropertyValue $Value -Force
        Save-Json $o
        Write-Output ("SETTINGS_DEFAULT=$Key=$Value")
    }
    'person' {
        switch ($Sub) {
            'add' {
                if (-not $Name -or -not $Images) { Write-Output 'SETTINGS_ERROR=person add needs -Name and -Images'; exit 1 }
                $d = Join-Path $peopleDir $Name
                $n = Add-Refs $d $Images
                if (-not (Test-Path (Join-Path $d 'meta.json'))) { [pscustomobject]@{ aliases = @() } | ConvertTo-Json | Set-Content (Join-Path $d 'meta.json') -Encoding UTF8 }
                Write-Output ("SETTINGS_PERSON_ADD=$Name added=$n total=" + (Count-Refs $d))
            }
            'refs' {
                # SETTINGS_REF<TAB><person><TAB><path> per reference image; -Name for one person.
                $img = @('.jpg', '.jpeg', '.png', '.heic', '.heif', '.gif', '.bmp', '.tif', '.tiff', '.webp')
                $targets = if ($Name) { @(Join-Path $peopleDir $Name) } else { @((Get-ChildItem -LiteralPath $peopleDir -Directory -ErrorAction SilentlyContinue).FullName) }
                foreach ($d in $targets) {
                    if (-not $d -or -not (Test-Path -LiteralPath $d)) { continue }
                    $nm = Split-Path $d -Leaf
                    foreach ($f in (Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue | Where-Object { $img -contains $_.Extension.ToLower() })) {
                        Write-Output ("SETTINGS_REF`t$nm`t" + $f.FullName)
                    }
                }
            }
            'remove' { if ($Name) { Remove-Item -Recurse -Force -LiteralPath (Join-Path $peopleDir $Name) -ErrorAction SilentlyContinue; Write-Output "SETTINGS_PERSON_REMOVE=$Name" } }
            'rename' { if ($Name -and $To) { Move-Item -LiteralPath (Join-Path $peopleDir $Name) -Destination (Join-Path $peopleDir $To); Write-Output "SETTINGS_PERSON_RENAME=$Name->$To" } }
            default { foreach ($p in (Get-ChildItem -LiteralPath $peopleDir -Directory -ErrorAction SilentlyContinue)) { Write-Output ("SETTINGS_PERSON`t" + $p.Name + "`t" + $p.FullName + "`t" + (Count-Refs $p.FullName)) } }
        }
    }
    'object' {
        switch ($Sub) {
            'add' {
                if (-not $Label -or -not $Images) { Write-Output 'SETTINGS_ERROR=object add needs -Label and -Images'; exit 1 }
                $d = Join-Path $objectsDir $Label
                $n = Add-Refs $d $Images
                Write-Output ("SETTINGS_OBJECT_ADD=$Label added=$n total=" + (Count-Refs $d))
            }
            'remove' { if ($Label) { Remove-Item -Recurse -Force -LiteralPath (Join-Path $objectsDir $Label) -ErrorAction SilentlyContinue; Write-Output "SETTINGS_OBJECT_REMOVE=$Label" } }
            default { foreach ($p in (Get-ChildItem -LiteralPath $objectsDir -Directory -ErrorAction SilentlyContinue)) { Write-Output ("SETTINGS_OBJECT`t" + $p.Name + "`t" + $p.FullName + "`t" + (Count-Refs $p.FullName)) } }
        }
    }
    'get' {
        $o = Load-Json
        Write-Output ("SETTINGS_ROOT=" + $root)
        if ($o.home) { Write-Output ("SETTINGS_HOME_LAT=" + $o.home.lat); Write-Output ("SETTINGS_HOME_LON=" + $o.home.lon); Write-Output ("SETTINGS_HOME_TOWN=" + $o.home.town); Write-Output ("SETTINGS_HOME_RADIUS_KM=" + $o.home.radiusKm) }
        foreach ($p in (Get-ChildItem -LiteralPath $peopleDir -Directory -ErrorAction SilentlyContinue)) { Write-Output ("SETTINGS_PERSON`t" + $p.Name + "`t" + $p.FullName + "`t" + (Count-Refs $p.FullName)) }
        foreach ($p in (Get-ChildItem -LiteralPath $objectsDir -Directory -ErrorAction SilentlyContinue)) { Write-Output ("SETTINGS_OBJECT`t" + $p.Name + "`t" + $p.FullName + "`t" + (Count-Refs $p.FullName)) }
        if ($o.defaults) { foreach ($pr in $o.defaults.PSObject.Properties) { Write-Output ("SETTINGS_DEFAULT`t" + $pr.Name + "`t" + $pr.Value) } }
    }
    default {
        # show
        $o = Load-Json
        Write-Output ("SETTINGS_ROOT=" + $root)
        if ($o.home -and $o.home.lat) { Write-Output ("SETTINGS_HOME=" + $o.home.town + " (" + $o.home.lat + "," + $o.home.lon + ") radius " + $o.home.radiusKm + "km") }
        else { Write-Output "SETTINGS_HOME=(not set - run: settings home -Lat <d> -Lon <d> -Town <name>)" }
        $ppl = @(Get-ChildItem -LiteralPath $peopleDir -Directory -ErrorAction SilentlyContinue)
        Write-Output ("SETTINGS_PEOPLE=" + $ppl.Count)
        foreach ($p in $ppl) { Write-Output ("  person`t" + $p.Name + "`t" + (Count-Refs $p.FullName) + " ref(s)") }
        $obj = @(Get-ChildItem -LiteralPath $objectsDir -Directory -ErrorAction SilentlyContinue)
        Write-Output ("SETTINGS_OBJECTS=" + $obj.Count)
        foreach ($p in $obj) { Write-Output ("  object`t" + $p.Name + "`t" + (Count-Refs $p.FullName) + " ref(s)") }
        if ($o.defaults) { foreach ($pr in $o.defaults.PSObject.Properties) { Write-Output ("  default`t" + $pr.Name + "=" + $pr.Value) } }
    }
}
