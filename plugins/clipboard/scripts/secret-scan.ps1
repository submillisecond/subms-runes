<#
  secret-scan - detect (and optionally redact) credentials in text. Shared by the
  clipboard runes so nothing sensitive is silently surfaced into the conversation
  or written to the history store.

  Two ways to use it:
    - DOT-SOURCE for the function: `. secret-scan.ps1` then `Find-Secrets $text`
      returns @{ types = @(...); count = N; redacted = '<text with [REDACTED:type]>' }.
    - CLI: `secret-scan.ps1 -Path f [-Redact]` or `-Text '...'`. Prints
      CLIP_SECRETS=<comma types>, CLIP_SECRET_COUNT=N, and (with -Redact) the
      redacted text between -----BEGIN REDACTED-----/-----END REDACTED----- markers.

  Detection favours PRECISION (vendor-prefixed tokens, structural formats) over a
  blunt entropy sweep, so ordinary code/prose does not trip it. A final
  keyword+entropy pass catches generic `api_key = "..."` style assignments.
#>
# NB: no param() block on purpose - this script is dot-sourced for Find-Secrets,
# and a param block would rebind (clobber) the caller's $Path/$Text on every
# dot-source. CLI args are parsed from $args instead.

# name -> regex. Order matters only for redaction overlap; types are de-duped.
$script:SecretPatterns = @(
    @{ name = 'private-key'; re = '-----BEGIN (?:RSA |EC |DSA |OPENSSH |PGP |ENCRYPTED )?PRIVATE KEY-----' }
    @{ name = 'aws-access-key'; re = '\b(?:AKIA|ASIA|AGPA|AIDA|AROA|ANPA)[0-9A-Z]{16}\b' }
    @{ name = 'aws-secret-key'; re = '(?i)aws_secret_access_key\s*[=:]\s*["'']?[A-Za-z0-9/+]{40}["'']?' }
    @{ name = 'github-pat'; re = '\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b|\bgithub_pat_[A-Za-z0-9_]{22,}\b' }
    @{ name = 'gitlab-pat'; re = '\bglpat-[A-Za-z0-9_-]{20,}\b' }
    @{ name = 'slack-token'; re = '\bxox[baprs]-[0-9A-Za-z-]{10,}\b' }
    @{ name = 'slack-webhook'; re = 'https://hooks\.slack\.com/services/[A-Za-z0-9/]+' }
    @{ name = 'google-api-key'; re = '\bAIza[0-9A-Za-z_-]{35}\b' }
    @{ name = 'stripe-key'; re = '\b(?:sk|rk|pk)_(?:live|test)_[0-9A-Za-z]{16,}\b' }
    @{ name = 'openai-key'; re = '\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b' }
    @{ name = 'anthropic-key'; re = '\bsk-ant-[A-Za-z0-9_-]{20,}\b' }
    @{ name = 'npm-token'; re = '\bnpm_[A-Za-z0-9]{36}\b' }
    @{ name = 'pypi-token'; re = '\bpypi-AgEIcHlwaS[A-Za-z0-9_-]{10,}\b' }
    @{ name = 'sendgrid-key'; re = '\bSG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}\b' }
    @{ name = 'twilio-key'; re = '\bSK[0-9a-fA-F]{32}\b' }
    @{ name = 'jwt'; re = '\beyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b' }
    @{ name = 'bearer-token'; re = '(?i)\bbearer\s+[A-Za-z0-9._~+/=-]{20,}' }
    @{ name = 'basic-auth-url'; re = '\b[a-z][a-z0-9+.-]*://[^\s/:@]+:[^\s/@]+@' }
    @{ name = 'db-connection'; re = '(?i)\b(?:mongodb(?:\+srv)?|postgres(?:ql)?|mysql|redis|amqps?)://[^\s:@]+:[^\s@]+@' }
    @{ name = 'generic-secret-assignment'; re = '(?i)\b(?:api[_-]?key|secret|token|passwd|password|client[_-]?secret|access[_-]?token)\b\s*[:=]\s*["'']?([A-Za-z0-9_\-./+=]{12,})["'']?' }
)

function Get-ShannonEntropy([string]$s) {
    if (-not $s) { return 0 }
    $freq = @{}
    foreach ($c in $s.ToCharArray()) { $freq[$c] = 1 + ($freq[$c]) }
    $len = $s.Length; $h = 0.0
    foreach ($k in $freq.Keys) { $p = $freq[$k] / $len; $h -= $p * [math]::Log($p, 2) }
    $h
}

function Find-Secrets([string]$text) {
    $types = New-Object System.Collections.Generic.List[string]
    $count = 0
    $redacted = $text
    if (-not $text) { return @{ types = @(); count = 0; redacted = '' } }
    foreach ($p in $script:SecretPatterns) {
        $ms = [regex]::Matches($text, $p.re)
        if ($ms.Count -gt 0) {
            # The generic assignment rule only counts when the captured VALUE looks
            # high-entropy - a real secret, not `password = "changeme"`.
            $hits = @($ms)
            if ($p.name -eq 'generic-secret-assignment') {
                $hits = @($ms | Where-Object { $_.Groups[1].Value -and (Get-ShannonEntropy $_.Groups[1].Value) -ge 3.0 })
                if ($hits.Count -eq 0) { continue }
            }
            if (-not $types.Contains($p.name)) { $types.Add($p.name) }
            $count += $hits.Count
            foreach ($m in ($hits | Sort-Object { $_.Index } -Descending)) {
                $redacted = $redacted.Substring(0, $m.Index) + "[REDACTED:$($p.name)]" + $redacted.Substring($m.Index + $m.Length)
            }
        }
    }
    @{ types = $types.ToArray(); count = $count; redacted = $redacted }
}

# CLI mode: parse $args (empty on dot-source, so this block is a no-op then).
$ScanPath = $null; $ScanText = $null; $ScanHasText = $false; $ScanRedact = $false
for ($i = 0; $i -lt $args.Count; $i++) {
    switch ($args[$i]) {
        '-Path' { $ScanPath = $args[++$i] }
        '-Text' { $ScanText = $args[++$i]; $ScanHasText = $true }
        '-Redact' { $ScanRedact = $true }
    }
}
if ($ScanPath -or $ScanHasText) {
    $body = if ($ScanPath) { if (Test-Path $ScanPath) { Get-Content -Raw -Path $ScanPath } else { Write-Output 'CLIP_SCAN_ERROR=missing -Path'; exit 1 } } else { $ScanText }
    $r = Find-Secrets $body
    Write-Output ('CLIP_SECRETS=' + ($r.types -join ','))
    Write-Output ('CLIP_SECRET_COUNT=' + $r.count)
    if ($ScanRedact) {
        Write-Output '-----BEGIN REDACTED-----'
        [Console]::Out.Write($r.redacted)
        if (-not $r.redacted.EndsWith("`n")) { [Console]::Out.Write("`n") }
        Write-Output '-----END REDACTED-----'
    }
}
