# dd-gif: post a scene to the worker's /gif and save the animation (pages as frames, or the drawing being made). Contract: ../contract/CONTRACTS.md.
# dd-gif.ps1 <file|-> -Out out.gif [-Mode pages|replay] [-Width N] [-HostUrl URL]
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $File,
  [string] $Out = "",
  [string] $Mode = "",
  [string] $Width = "720",
  [string] $HostUrl = "https://deltadraw.submillisecond.com"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $File) { [Console]::Error.WriteLine("ERROR=no scene file (pass a path or - for stdin)"); exit 2 }
if (-not $Out) { [Console]::Error.WriteLine("ERROR=-Out is required"); exit 2 }
if ($Width -notmatch '^[0-9]+$') { [Console]::Error.WriteLine("ERROR=width must be a whole number"); exit 2 }
if ($Mode -and $Mode -ne "pages" -and $Mode -ne "replay") { [Console]::Error.WriteLine("ERROR=mode must be pages or replay"); exit 2 }
if ($File -eq "-") { $src = [Console]::In.ReadToEnd() } else { $src = [System.IO.File]::ReadAllText($File) }
$src = $src -replace "`r`n", "`n"

$q = "width=$Width"
if ($Mode) { $q = "$q&mode=$Mode" }
$uri = "$($HostUrl.TrimEnd('/'))/gif?$q"
try {
  $res = Invoke-WebRequest -Uri $uri -Method Post -ContentType "text/plain; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($src)) -UseBasicParsing -TimeoutSec 120
} catch {
  $r = $_.Exception.Response
  if ($r -and [int] $r.StatusCode -eq 422) {
    $reader = New-Object System.IO.StreamReader($r.GetResponseStream())
    [Console]::Error.WriteLine($reader.ReadToEnd())
    exit 1
  }
  if ($r) { [Console]::Error.WriteLine("ERROR=worker answered $([int] $r.StatusCode)") } else { [Console]::Error.WriteLine("ERROR=network: $($_.Exception.Message)") }
  exit 2
}
[System.IO.File]::WriteAllBytes($Out, $res.Content)
[Console]::Out.Write("GIF=$Out`n")
[Console]::Out.Write("BYTES=$($res.Content.Length)`n")
