#!/usr/bin/env bash
# workspace - mint / clean a per-run temp workspace (see workspace.ps1), so runes
# never hand-roll the mktemp + rm boilerplate inline. Namespaced by plugin under
# $TMPDIR/runes/<plugin>/; unique per run so two terminals never collide.
#   new   --plugin images [--skill img-organize]   mint a fresh dir, print WORKSPACE=<dir>
#   clean --dir <dir>                               remove it (guarded: under runes temp only)
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
