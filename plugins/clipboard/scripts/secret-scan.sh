#!/usr/bin/env bash
# secret-scan: .sh port of secret-scan.ps1. Source for find_secrets, or run --path f | --text s [--redact].
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
      # perl, not sed -i: BSD sed takes -E as the backup suffix and has no I flag.
      # A failed rewrite blanks the copy so no secret survives it.
      local ci=""; printf '%s' "$flags" | grep -q i && ci='(?i)'
      if RE="$ci$re" TAG="[REDACTED:$name]" perl -pe 's/$ENV{RE}/$ENV{TAG}/g' "$redfile" > "$redfile.t" 2>/dev/null; then
        mv "$redfile.t" "$redfile"
      else
        rm -f "$redfile.t"; printf '[REDACTED:redaction-failed]\n' > "$redfile"
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
    [ -n "$(tail -c 1 "$FS_REDACTED")" ] && echo
    echo "-----END REDACTED-----"
  fi
fi
