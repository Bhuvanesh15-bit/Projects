#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

: "${SERVER_USER:?Set SERVER_USER, for example ubuntu}"
: "${SERVER_HOST:?Set SERVER_HOST to the server IP or hostname}"
: "${SSH_KEY:?Set SSH_KEY to your private key path}"

REMOTE_WEB_ROOT="${REMOTE_WEB_ROOT:-/var/www/static-site}"
DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN="--dry-run"
elif [[ "${1:-}" != "" ]]; then
  printf 'Usage: %s [--dry-run]\n' "$0" >&2
  exit 2
fi

command -v rsync >/dev/null || { printf 'rsync is required\n' >&2; exit 1; }
command -v ssh >/dev/null || { printf 'ssh is required\n' >&2; exit 1; }
[[ -f "$SSH_KEY" ]] || { printf 'SSH key not found: %s\n' "$SSH_KEY" >&2; exit 1; }

REMOTE="$SERVER_USER@$SERVER_HOST"
if [[ -z "$DRY_RUN" ]]; then
  ssh -i "$SSH_KEY" "$REMOTE" "sudo install -d -o www-data -g www-data '$REMOTE_WEB_ROOT'"
fi

rsync --archive --compress --delete --checksum $DRY_RUN \
  -e "ssh -i $SSH_KEY" \
  "$PROJECT_DIR/site/" "$REMOTE:$REMOTE_WEB_ROOT/"

printf 'Deployment complete: http://%s/\n' "$SERVER_HOST"
