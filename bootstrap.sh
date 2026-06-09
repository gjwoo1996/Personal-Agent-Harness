#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET=""
CLEAN_NESTED=0

usage() {
  cat <<'USAGE'
Usage:
  bootstrap.sh <target> [--clean-nested]

Install harness rules into <target> using this harness checkout.
Does not copy the harness repository into the target project.

Options:
  --clean-nested   Remove <target>/Personal-Agent-Harness after a successful install
USAGE
}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --clean-nested) CLEAN_NESTED=1; shift ;;
    -h|--help|help) usage; exit 0 ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
        shift
      else
        die "unexpected argument: $1"
      fi
      ;;
  esac
done

[ -n "$TARGET" ] || { usage; exit 1; }
TARGET="$(cd "$TARGET" && pwd -P)"

if [ -d "$TARGET/Personal-Agent-Harness/.git" ]; then
  log "WARNING: nested harness clone detected at $TARGET/Personal-Agent-Harness"
  log "WARNING: recommended: use external PAH_HOME and remove the nested folder"
fi

"$ROOT/setup.sh" "$TARGET"

if [ "$CLEAN_NESTED" = "1" ] && [ -d "$TARGET/Personal-Agent-Harness" ]; then
  rm -rf "$TARGET/Personal-Agent-Harness"
  log "Removed nested harness folder: $TARGET/Personal-Agent-Harness"
fi

log "Harness rules installed into: $TARGET"
log "Harness source (keep for updates): $ROOT"
log "Update command: $ROOT/update.sh $TARGET"
log "Status command: $ROOT/bin/pah status $TARGET --harness-root $ROOT"
