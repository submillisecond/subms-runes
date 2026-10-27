# dg-url: print a deltagraph viewer link (URL=, LENGTH=) for a diagram source. Contract: ../contract/CONTRACTS.md.
# dg-url.ps1 <file|-> [-Title T] [-Theme light|dark] [-Bg transparent|black|white|auto|<hex>] [-Dir LR|TD] [-ShowDebug] [-Edit] [-Compress] [-Base URL]
[CmdletBinding()]
param(
  [Parameter(Position = 0)] [string] $File,
  [string] $Title = "",
  [string] $Theme = "",
  [string] $Bg = "",
  [string] $Dir = "",
  # `-Debug` is a PowerShell common parameter, hence the longer name.
  [switch] $ShowDebug,
  [switch] $Edit,
  [switch] $Compress,
  [string] $Base = "https://www.submillisecond.com/deltagraph"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not $File) { [Console]::Error.WriteLine("ERROR=no source file (pass a path or - for stdin)"); exit 2 }
if ($File -eq "-") { $src = [Console]::In.ReadToEnd() } else { $src = [System.IO.File]::ReadAllText($File) }
# Normalise line endings and trim the way the viewer does.
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
$bgv = $Bg.Trim().ToLowerInvariant().TrimStart("#")
if ($bgv) {
  if ($bgv -in @("transparent", "black", "white", "auto")) { $url += "&bg=$bgv" }
  elseif ($bgv -match "^[0-9a-f]{6}$") { $url += "&bg=$bgv" }
  elseif ($bgv -match "^[0-9a-f]{3}$") { $url += "&bg=" + (($bgv.ToCharArray() | ForEach-Object { "$_$_" }) -join "") }
  else { [Console]::Error.WriteLine("ERROR=bg must be transparent, black, white, auto or a hex colour"); exit 2 }
}
switch ($Dir.ToUpperInvariant()) {
  "" { }
  "LR" { $url += "&dir=LR" }
  "TD" { $url += "&dir=TD" }
  "TB" { $url += "&dir=TD" }
  default { [Console]::Error.WriteLine("ERROR=dir must be LR or TD"); exit 2 }
}
if ($ShowDebug) { $url += "&debug=true" }
if ($Edit)   { $url += "&edit=true" }

[Console]::Out.Write("URL=$url`n")
[Console]::Out.Write("LENGTH=$($url.Length)`n")
