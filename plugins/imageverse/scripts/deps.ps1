# deps: report missing external tools (ffmpeg and ffprobe here), the install command and what degrades without them.
# Prints DEP <tool> ok|missing <purpose> lines, then DEPS_OK= or DEPS_MISSING= DEPS_FIX= DEPS_DEGRADED=.
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
