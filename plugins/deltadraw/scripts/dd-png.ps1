# dd-png: post a scene to the worker's /png and save the picture, so a drawing can be looked at without MCP. Contract: ../contract/CONTRACTS.md.
# dd-png.ps1 <file|-> -Out out.png [-Width N] [-Page N] [-HostUrl URL]
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $File,
  [string] $Out = "",
  [string] $Width = "1200",
  [string] $Page = "",
  [string] $HostUrl = "https://deltadraw.submillisecond.com"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $File) { [Console]::Error.WriteLine("ERROR=no scene file (pass a path or - for stdin)"); exit 2 }
if (-not $Out) { [Console]::Error.WriteLine("ERROR=-Out is required"); exit 2 }
if ($Width -notmatch '^[0-9]+$') { [Console]::Error.WriteLine("ERROR=width must be a whole number"); exit 2 }
if ($Page -and $Page -notmatch '^[1-9][0-9]*$') { [Console]::Error.WriteLine("ERROR=page must be a whole number from 1"); exit 2 }
if ($File -eq "-") { $src = [Console]::In.ReadToEnd() } else { $src = [System.IO.File]::ReadAllText($File) }
$src = $src -replace "`r`n", "`n"

$uri = "$($HostUrl.TrimEnd('/'))/png?width=$Width"
if ($Page) { $uri = "$uri&page=$Page" }
try {
  $res = Invoke-WebRequest -Uri $uri -Method Post -ContentType "text/plain; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($src)) -UseBasicParsing -TimeoutSec 60
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
[Console]::Out.Write("PNG=$Out`n")
[Console]::Out.Write("BYTES=$($res.Content.Length)`n")
