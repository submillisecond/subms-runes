<#
  geocode - reverse-geocode ONE coordinate to a place name (OpenStreetMap
  Nominatim). NETWORK + PRIVACY: this sends the lat/lon to a third-party API
  (nominatim.openstreetmap.org). img-organize calls it ONLY on cluster CENTROIDS
  and ONLY after the user confirms in that run - never on every photo, never
  without opt-in.

    -Lat <deg> -Lon <deg>

  Prints GEOCODE_PLACE=<city/town>, <country> (or GEOCODE_NONE on failure).
  Nominatim usage policy: <=1 req/s, a real User-Agent (set below). For heavy use
  run your own instance and point -BaseUrl at it.
#>
param(
    [Parameter(Mandatory)][double]$Lat,
    [Parameter(Mandatory)][double]$Lon,
    [string]$BaseUrl = 'https://nominatim.openstreetmap.org'
)
$ErrorActionPreference = 'Stop'
try {
    $url = "$BaseUrl/reverse?lat=$Lat&lon=$Lon&format=jsonv2&zoom=12&addressdetails=1"
    $headers = @{ 'User-Agent' = 'subms-runes-imageverse/0.1 (image organiser)' }
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
