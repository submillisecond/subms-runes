# dd-url: print a deltadraw viewer link (URL=, LENGTH=) for a scene file. Contract: ../contract/CONTRACTS.md.
# dd-url.ps1 <file|-> [-Title T] [-Theme light|dark] [-Replay] [-Edit] [-Compress] [-Base URL]
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $File,
  [string] $Title = "",
  [string] $Theme = "",
  [switch] $Replay,
  [switch] $Edit,
  [switch] $Compress,
  [string] $Base = "https://www.submillisecond.com/deltadraw"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $File) { [Console]::Error.WriteLine("ERROR=no scene file (pass a path or - for stdin)"); exit 2 }
if ($File -eq "-") { $src = [Console]::In.ReadToEnd() } else { $src = [System.IO.File]::ReadAllText($File) }
$src = ($src -replace "`r`n", "`n").TrimEnd("`n", " ", "`t")
$src = [regex]::Replace($src, "^\s*\n", "")

function Enc([string] $s) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($b in [System.Text.Encoding]::UTF8.GetBytes($s)) {
    if (($b -ge 48 -and $b -le 57) -or ($b -ge 65 -and $b -le 90) -or ($b -ge 97 -and $b -le 122) -or $b -eq 45 -or $b -eq 95 -or $b -eq 46 -or $b -eq 126) {
      [void] $sb.Append([char] $b)
    } else {
      [void] $sb.AppendFormat("%{0:X2}", $b)
    }
  }
  $sb.ToString()
}

function Pack([string] $s) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $ms = New-Object System.IO.MemoryStream
  $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionLevel]::Optimal, $true)
  $ds.Write($bytes, 0, $bytes.Length)
  $ds.Dispose()
  [Convert]::ToBase64String($ms.ToArray()).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

if ($Compress) { $url = "$Base#d1=" + (Pack $src) } else { $url = "$Base#dsl=" + (Enc $src) }
if ($Title) { $url += "&title=" + (Enc $Title) }
switch ($Theme.ToLowerInvariant()) {
  "" { }
  "light" { $url += "&theme=light" }
  "white" { $url += "&theme=light" }
  "dark"  { $url += "&theme=dark" }
  "night" { $url += "&theme=dark" }
  default { [Console]::Error.WriteLine("ERROR=theme must be light or dark"); exit 2 }
}
if ($Replay) { $url += "&replay" }
if ($Edit) { $url += "&edit" }

[Console]::Out.Write("URL=$url`n")
[Console]::Out.Write("LENGTH=$($url.Length)`n")
