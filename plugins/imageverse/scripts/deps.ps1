<#
  deps - preflight the external tools the imageverse image pipeline relies on, and
  report any that are MISSING together with the suggested install command + which
  FEATURE degrades without them. Skills run this before image work and surface misses
  to the user (don't fail silently / don't let a feature mysteriously no-op).

  Windows backend: image resize / thumbnails / montage tiling use .NET System.Drawing
  (built in - always available), so the only external need is ffmpeg(+ffprobe) for
  VIDEO contact sheets. (ImageMagick is only needed by the .sh backend.)

  Prints one `DEP <tool> <ok|missing> <purpose>` line per tool, then either
  `DEPS_OK=...` or `DEPS_MISSING=...` + `DEPS_FIX=<command>` + `DEPS_DEGRADED=...`.
#>
param([string]$Plugin = 'imageverse')
# refresh PATH so a tool installed earlier this session (new user/Machine PATH) is seen
try { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') } catch {}
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }

$ff = Have 'ffmpeg'; $fp = Have 'ffprobe'
Write-Output ("DEP`tSystem.Drawing`tok`timage thumbnails, contact sheets, montage tiling (built into Windows)")
Write-Output ("DEP`tffmpeg`t" + $(if ($ff) { 'ok' } else { 'missing' }) + "`tvideo contact-sheet frames / clip thumbnails")
Write-Output ("DEP`tffprobe`t" + $(if ($fp) { 'ok' } else { 'missing' }) + "`tvideo duration for even frame sampling")

$missing = @()
if (-not $ff) { $missing += 'ffmpeg' }
if (-not $fp) { $missing += 'ffprobe' }
if ($missing.Count -gt 0) {
    Write-Output ("DEPS_MISSING=" + ($missing -join ','))
    Write-Output ("DEPS_FIX=winget install -e --id Gyan.FFmpeg   (then open a NEW terminal - installs ffmpeg + ffprobe)")
    Write-Output ("DEPS_DEGRADED=videos can't be content-thumbnailed; clips fall back to time/geo-cluster grouping (no contact sheets)")
}
else {
    Write-Output "DEPS_OK=all image tools present"
}
