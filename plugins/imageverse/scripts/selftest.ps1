# selftest: .ps1/.sh parity, parse, and thumbs -Sheet grid checks. Run after editing any script.
# Prints SELFTEST_PASS or SELFTEST_FAIL=<n>.
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$fail = New-Object System.Collections.Generic.List[string]

# 1) parity
$ps = (Get-ChildItem $dir -Filter *.ps1 | Where-Object { $_.BaseName -ne 'selftest' }).BaseName
$sh = (Get-ChildItem $dir -Filter *.sh | Where-Object { $_.BaseName -ne 'selftest' }).BaseName
foreach ($n in $ps) { if ($sh -notcontains $n) { $fail.Add("PARITY: $n.ps1 has no .sh sibling") } }
foreach ($n in $sh) { if ($ps -notcontains $n) { $fail.Add("PARITY: $n.sh has no .ps1 sibling") } }
Write-Output ("CHECK parity: $($ps.Count) ps1 / $($sh.Count) sh")

# 2) parse every .ps1
foreach ($f in (Get-ChildItem $dir -Filter *.ps1)) {
    $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$errs)
    if ($errs -and $errs.Count) { $fail.Add("PARSE: $($f.Name): $($errs[0].Message)") }
}
Write-Output ("CHECK parse: $((Get-ChildItem $dir -Filter *.ps1).Count) ps1 files")

# 3) montage grid: no blank cells (the [int]-rounding regression)
Add-Type -AssemblyName System.Drawing | Out-Null
$t = Join-Path $env:TEMP ("imgv_selftest_" + [Guid]::NewGuid().ToString('N').Substring(0, 6))
New-Item -ItemType Directory -Force -Path $t | Out-Null
$paths = @()
for ($i = 0; $i -lt 20; $i++) {
    $b = New-Object Drawing.Bitmap(400, 300); $g = [Drawing.Graphics]::FromImage($b)
    $g.Clear([Drawing.Color]::FromArgb(60 + 9 * $i, 90, 200 - 7 * $i)); $g.Dispose()
    $p = Join-Path $t ("img_{0:D2}.png" -f $i); $b.Save($p); $b.Dispose(); $paths += $p
}
$paths | Set-Content "$t\list.txt" -Encoding UTF8
& powershell.exe -ExecutionPolicy Bypass -File (Join-Path $dir 'thumbs.ps1') -List "$t\list.txt" -Sheet 20 -Cols 7 -SheetCell 120 -Dense -OutDir "$t\out" | Out-Null
if (Test-Path "$t\out\sheet001.png") {
    $bmp = [Drawing.Image]::FromStream((New-Object IO.MemoryStream(, [IO.File]::ReadAllBytes("$t\out\sheet001.png"))))
    $cols = 7; $cw = [int]($bmp.Width / $cols); $blank = 0
    for ($k = 0; $k -lt 20; $k++) {
        $r = [int][math]::Floor($k / $cols); $c = $k % $cols
        $px = $bmp.GetPixel([int]($c * $cw + $cw / 2), [int]($r * $cw + $cw / 2))
        if ([math]::Abs($px.R - 20) -lt 4 -and [math]::Abs($px.G - 20) -lt 4 -and [math]::Abs($px.B - 20) -lt 4) { $blank++ }
    }
    $bmp.Dispose()
    if ($blank -gt 0) { $fail.Add("GRID: $blank blank cell(s) of 20 - row math regressed") }
    Write-Output ("CHECK grid: 20 cells, $blank blank")
}
else { $fail.Add("GRID: thumbs produced no sheet") }
Remove-Item -Recurse -Force -LiteralPath $t -ErrorAction SilentlyContinue

if ($fail.Count -eq 0) { Write-Output "SELFTEST_PASS" }
else { foreach ($x in $fail) { Write-Output ("FAIL " + $x) }; Write-Output ("SELFTEST_FAIL=" + $fail.Count) }
