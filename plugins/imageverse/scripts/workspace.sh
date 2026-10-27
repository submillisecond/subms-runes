#!/usr/bin/env bash
# workspace: .sh port of workspace.ps1 (mint or remove a per-run dir under $TMPDIR/runes/<plugin>/).
# workspace.sh new --plugin p [--skill s] -> WORKSPACE=<dir> | clean --dir d (refused outside the runes temp).
set -uo pipefail

ACTION="${1:-new}"; shift || true
PLUGIN="misc"; SKILL="run"; DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plugin) PLUGIN="$2"; shift 2;;
    --skill) SKILL="$2"; shift 2;;
    --dir) DIR="$2"; shift 2;;
    *) shift;;
  esac
done
ROOT="${TMPDIR:-/tmp}/runes"

case "$ACTION" in
  new)
    mkdir -p "$ROOT/$PLUGIN"
    ws="$(mktemp -d "$ROOT/$PLUGIN/$SKILL-XXXXXX")"
    echo "WORKSPACE=$ws" ;;
  clean)
    [ -n "$DIR" ] || { echo "WORKSPACE_ERROR=missing --dir"; exit 1; }
    case "$DIR" in
      "$ROOT"/*) : ;;
      *) echo "WORKSPACE_ERROR=refusing to clean outside $ROOT : $DIR"; exit 1;;
    esac
    rm -rf "$DIR"
    echo "WORKSPACE_CLEANED=$DIR" ;;
  *) echo "WORKSPACE_ERROR=unknown action $ACTION"; exit 1;;
esac
