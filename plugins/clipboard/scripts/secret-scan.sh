#!/usr/bin/env bash
# secret-scan - detect (and optionally redact) credentials in text. Mirror of
# secret-scan.ps1 (that is the verified backend). Source it for find_secrets(), or
# run as CLI: secret-scan.sh --path f [--redact]  /  --text '...'.
# Prints CLIP_SECRETS=<comma types>, CLIP_SECRET_COUNT=N, and with --redact the
# redacted text between -----BEGIN/END REDACTED----- markers.
set -u

# name<TAB>grep-flags<TAB>ERE. Precise vendor formats first; a keyword rule last.
_secret_patterns() {
  cat <<'PATS'
private-key	-E	-----BEGIN ([A-Z]+ )?PRIVATE KEY-----
aws-access-key	-E	(AKIA|ASIA|AGPA|AIDA|AROA|ANPA)[0-9A-Z]{16}
github-pat	-E	(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}
gitlab-pat	-E	glpat-[A-Za-z0-9_-]{20,}
slack-token	-E	xox[baprs]-[0-9A-Za-z-]{10,}
slack-webhook	-E	https://hooks\.slack\.com/services/[A-Za-z0-9/]+
google-api-key	-E	AIza[0-9A-Za-z_-]{35}
stripe-key	-E	(sk|rk|pk)_(live|test)_[0-9A-Za-z]{16,}
openai-key	-E	sk-(proj-)?[A-Za-z0-9_-]{20,}
anthropic-key	-E	sk-ant-[A-Za-z0-9_-]{20,}
npm-token	-E	npm_[A-Za-z0-9]{36}
sendgrid-key	-E	SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}
jwt	-E	eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}
bearer-token	-iE	bearer [A-Za-z0-9._~+/=-]{20,}
basic-auth-url	-E	[a-z][a-z0-9+.-]*://[^ /:@]+:[^ /@]+@
db-connection	-iE	(mongodb(\+srv)?|postgres(ql)?|mysql|redis|amqps?)://[^ :@]+:[^ @]+@
generic-secret-assignment	-iE	(api[_-]?key|secret|token|password|client[_-]?secret|access[_-]?token)[[:space:]]*[:=][[:space:]]*"?[A-Za-z0-9_./+=-]{16,}
PATS
}

# find_secrets <textfile>  -> sets FS_TYPES (comma), FS_COUNT, FS_REDACTED
find_secrets() {
  local f="$1" types="" count=0 redfile
  redfile="$(mktemp)"; cp "$f" "$redfile"
  while IFS=$'\t' read -r name flags re; do
    [ -n "$name" ] || continue
    local n; n="$(grep $flags -oh "$re" "$f" 2>/dev/null | grep -c . || true)"
    if [ "${n:-0}" -gt 0 ]; then
      types="${types:+$types,}$name"
      count=$((count + n))
      # redact: replace each match with a tag (sed; '|' delimiter avoids '/' clashes)
      local sed_re; sed_re="$(printf '%s' "$re" | sed 's/[|]/\\|/g')"
      if printf '%s' "$flags" | grep -q i; then
        sed -i -E "s|$sed_re|[REDACTED:$name]|gI" "$redfile" 2>/dev/null || true
      else
        sed -i -E "s|$sed_re|[REDACTED:$name]|g" "$redfile" 2>/dev/null || true
      fi
    fi
  done < <(_secret_patterns)
  FS_TYPES="$types"; FS_COUNT="$count"; FS_REDACTED="$redfile"
}

# CLI
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  PATH_IN=""; TEXT_IN=""; REDACT=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --path) PATH_IN="$2"; shift 2 ;;
      --text) TEXT_IN="$2"; shift 2 ;;
      --redact) REDACT=1; shift ;;
      *) shift ;;
    esac
  done
  tmp="$(mktemp)"
  if [ -n "$PATH_IN" ]; then [ -f "$PATH_IN" ] || { echo "CLIP_SCAN_ERROR=missing --path"; exit 1; }; cp "$PATH_IN" "$tmp"; else printf '%s' "$TEXT_IN" > "$tmp"; fi
  find_secrets "$tmp"
  echo "CLIP_SECRETS=$FS_TYPES"
  echo "CLIP_SECRET_COUNT=$FS_COUNT"
  if [ "$REDACT" = "1" ]; then
    echo "-----BEGIN REDACTED-----"
    cat "$FS_REDACTED"
    echo "-----END REDACTED-----"
  fi
fi
