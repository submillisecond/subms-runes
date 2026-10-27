# dg-debug - run a diagram source through the real engine and print why it does
# not render, or why it reads badly, and what to change. The verified backend;
# dg-debug.sh is the POSIX port.
#
#   dg-debug.ps1 <file|-> [-Json] [-Review out.svg] [-NoOptimise] [-Tries N] [-HostUrl URL]
#
# Posts the source to the hosted worker's /debug route, so it needs the
# network; dg-url is the offline path. Output, exit codes and the report's
# shape are in ../contract/CONTRACTS.md.
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $File,
  [switch] $Json,
  [string] $Review = "",
  [switch] $NoOptimise,
  [int] $Tries = -1,
  [string] $HostUrl = "https://deltagraph.submillisecond.com"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $File) { [Console]::Error.WriteLine("ERROR=no source file (pass a path or - for stdin)"); exit 2 }
if ($File -eq "-") { $src = [Console]::In.ReadToEnd() } else { $src = [System.IO.File]::ReadAllText($File) }
$src = ($src -replace "`r`n", "`n")

function Post([string] $query) {
  $req = [System.Net.HttpWebRequest]::Create("$($HostUrl.TrimEnd('/'))/debug?$query")
  $req.Method = "POST"
  $req.ContentType = "text/plain; charset=utf-8"
  $req.Timeout = 30000
  $body = [System.Text.Encoding]::UTF8.GetBytes($src)
  $req.ContentLength = $body.Length
  try {
    $s = $req.GetRequestStream(); $s.Write($body, 0, $body.Length); $s.Close()
    $res = $req.GetResponse()
  }
  catch {
    $ex = $_.Exception
    while ($ex.InnerException -and -not ($ex -is [System.Net.WebException])) { $ex = $ex.InnerException }
    if (-not ($ex -is [System.Net.WebException]) -or -not $ex.Response) { [Console]::Error.WriteLine("ERROR=network: $($ex.Message)"); exit 2 }
    $res = $ex.Response
  }
  $reader = New-Object System.IO.StreamReader($res.GetResponseStream(), [System.Text.Encoding]::UTF8)
  $text = $reader.ReadToEnd(); $reader.Close()
  @{ Status = [int] $res.StatusCode; Body = $text }
}

$q = @()
if ($NoOptimise) { $q += "optimise=false" }
if ($Tries -ge 0) { $q += "tries=$Tries" }

$r = Post ((@("format=" + ($(if ($Json) { "json" } else { "text" }))) + $q) -join "&")
if ($r.Status -ne 200 -and $r.Status -ne 422) { [Console]::Error.WriteLine("ERROR=worker answered $($r.Status)"); exit 2 }
[Console]::Out.Write($r.Body)
if (-not $r.Body.EndsWith("`n")) { [Console]::Out.Write("`n") }

if ($Review -and $r.Status -eq 200) {
  $svg = Post ((@("format=svg") + $q) -join "&")
  if ($svg.Status -eq 200) {
    [System.IO.File]::WriteAllText($Review, $svg.Body, (New-Object System.Text.UTF8Encoding($false)))
    [Console]::Error.WriteLine("REVIEW=$Review")
  }
}
if ($r.Status -eq 200) { exit 0 } else { exit 1 }
