#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

: "${SERVER_USER:?Set SERVER_USER, for example ubuntu}"
: "${SERVER_HOST:?Set SERVER_HOST to the server IP or hostname}"
: "${SSH_KEY:?Set SSH_KEY to your private key path}"

REMOTE="$SERVER_USER@$SERVER_HOST"
NGINX_CONFIG="$PROJECT_DIR/server/nginx-site.conf"
[[ -f "$SSH_KEY" ]] || { printf 'SSH key not found: %s\n' "$SSH_KEY" >&2; exit 1; }

ssh -i "$SSH_KEY" "$REMOTE" "sudo apt-get update && sudo apt-get install -y nginx"
ssh -i "$SSH_KEY" "$REMOTE" "sudo tee /etc/nginx/sites-available/static-site >/dev/null" < "$NGINX_CONFIG"
ssh -i "$SSH_KEY" "$REMOTE" "sudo ln -sfn /etc/nginx/sites-available/static-site /etc/nginx/sites-enabled/static-site && sudo rm -f /etc/nginx/sites-enabled/default && sudo nginx -t && sudo systemctl enable --now nginx && sudo systemctl reload nginx"

printf 'Nginx configured on %s.\n' "$SERVER_HOST"
