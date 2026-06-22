<#
  geocode - bridge between place names and coordinates via OpenStreetMap
  Nominatim. Two modes:

    REVERSE  -Lat <deg> -Lon <deg>     coordinate -> place name
    FORWARD  -Query "<place>"          place name -> coordinate + bbox + radius

  NETWORK + PRIVACY: this calls a third-party API (nominatim.openstreetmap.org).
  REVERSE sends a lat/lon; FORWARD sends only a place NAME (no user coordinates).
  img-organize calls REVERSE only on cluster CENTROIDS after the user confirms;
  img-search calls FORWARD to resolve "near <place>" into a -Geo filter. Never
  per-photo, never without opt-in.

  REVERSE prints GEOCODE_PLACE=<city/town>, <country> (or GEOCODE_NONE).
  FORWARD prints GEOCODE_LATLON=<lat>,<lon>, GEOCODE_BBOX=<south>,<west>,<north>,<east>,
  and GEOCODE_RADIUS_KM=<km> (center -> NE corner; a sensible "near here" radius
  that scales with the place), or GEOCODE_NONE.

  Nominatim usage policy: <=1 req/s, a real User-Agent (set below). For heavy use
  run your own instance and point -BaseUrl at it.
#>
param(
    [double]$Lat,
    [double]$Lon,
    [string]$Query,
    [string]$BaseUrl = 'https://nominatim.openstreetmap.org'
)
$ErrorActionPreference = 'Stop'
$headers = @{ 'User-Agent' = 'subms-runes-imageverse/0.1 (image organiser)' }

function Haversine($la1, $lo1, $la2, $lo2) {
    $deg = [math]::PI / 180
    $dLa = ($la2 - $la1) * $deg; $dLo = ($lo2 - $lo1) * $deg
    $a = [math]::Sin($dLa / 2) * [math]::Sin($dLa / 2) + [math]::Cos($la1 * $deg) * [math]::Cos($la2 * $deg) * [math]::Sin($dLo / 2) * [math]::Sin($dLo / 2)
    6371.0 * 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))
}

if ($Query) {
    try {
        $url = "$BaseUrl/search?q=$([uri]::EscapeDataString($Query))&format=jsonv2&limit=1"
        $r = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 15
        if (-not $r -or @($r).Count -eq 0) { Write-Output 'GEOCODE_NONE=1'; return }
        $hit = @($r)[0]
        $clat = [double]$hit.lat; $clon = [double]$hit.lon
        # Nominatim boundingbox: [south, north, west, east] (strings).
        $bb = $hit.boundingbox
        $south = [double]$bb[0]; $north = [double]$bb[1]; $west = [double]$bb[2]; $east = [double]$bb[3]
        $radius = Haversine $clat $clon $north $east
        Write-Output ("GEOCODE_LATLON={0},{1}" -f $clat, $clon)
        Write-Output ("GEOCODE_BBOX={0},{1},{2},{3}" -f $south, $west, $north, $east)
        Write-Output ("GEOCODE_RADIUS_KM={0:0.0}" -f $radius)
    }
    catch { Write-Output ("GEOCODE_NONE=1`tGEOCODE_ERROR=" + $_.Exception.Message) }
    return
}

if ($PSBoundParameters.ContainsKey('Lat') -and $PSBoundParameters.ContainsKey('Lon')) {
    try {
        $url = "$BaseUrl/reverse?lat=$Lat&lon=$Lon&format=jsonv2&zoom=12&addressdetails=1"
        $r = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 15
        $a = $r.address
        $place = $a.city; if (-not $place) { $place = $a.town }; if (-not $place) { $place = $a.village }
        if (-not $place) { $place = $a.county }; if (-not $place) { $place = $a.state }
        $country = $a.country
        if ($place -and $country) { Write-Output "GEOCODE_PLACE=$place, $country" }
        elseif ($r.display_name) { Write-Output ("GEOCODE_PLACE=" + (($r.display_name -split ',')[0..1] -join ',').Trim()) }
        else { Write-Output 'GEOCODE_NONE=1' }
    }
    catch { Write-Output ("GEOCODE_NONE=1`tGEOCODE_ERROR=" + $_.Exception.Message) }
    return
}

Write-Output 'GEOCODE_NONE=1'
Write-Output 'GEOCODE_ERROR=give -Query <place> (forward) or -Lat/-Lon (reverse)'
