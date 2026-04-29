#!/usr/bin/env bash
# deploy.setup.sh — configures a fresh Ubuntu 24.04 VM as the target node.
# Run once as root (or sudo) on the target node.
set -euo pipefail

# shellcheck disable=SC2034
NGINX_CONF_URL="https://raw.githubusercontent.com/vitkovskiiy/notes-service/main/nginx.conf"
APP_PORT=3000

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ── 0. Pre-flight ─────────────────────────────────────────────────────────────
log "Checking OS..."
# shellcheck disable=SC1091
if ! grep -qi ubuntu /etc/os-release; then
  echo "ERROR: This script targets Ubuntu 24.04 only." >&2
  exit 1
fi

# ── 1. System update ──────────────────────────────────────────────────────────
log "Updating package lists..."
apt-get update -qq
apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  nginx \
  ufw

# ── 2. Install Docker Engine ──────────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
  log "Installing Docker Engine..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME}") stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get update -qq
  apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
else
  log "Docker already installed: $(docker --version)"
fi

systemctl enable --now docker
log "Docker: $(docker --version)"

# ── 3. Configure nginx ────────────────────────────────────────────────────────
log "Configuring nginx..."

# Download nginx config from repo or use inline config
# shellcheck disable=SC2016
cat > /etc/nginx/sites-available/notes-service <<EOF
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/notes-service.access.log;
    error_log  /var/log/nginx/notes-service.error.log;

    location / {
        proxy_pass         http://127.0.0.1:${APP_PORT};
        proxy_http_version 1.1;
        proxy_set_header   Host              \$host;
        proxy_set_header   X-Real-IP         \$remote_addr;
        proxy_set_header   X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   Upgrade           \$http_upgrade;
        proxy_set_header   Connection        "upgrade";
        proxy_read_timeout 60s;
    }
}
EOF

# Disable default site, enable our config
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/notes-service \
       /etc/nginx/sites-enabled/notes-service

nginx -t
systemctl enable --now nginx
systemctl reload nginx
log "nginx configured and running"

# ── 4. Firewall ────────────────────────────────────────────────────────────────
log "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw --force enable
log "UFW enabled"

# ── 5. Create environment file placeholder ────────────────────────────────────
if [ ! -f /etc/notes-service.env ]; then
  log "Creating placeholder environment file..."
  cat > /etc/notes-service.env <<'ENVEOF'
# This file is overwritten by the CD pipeline on each deployment.
# Populate manually only for initial testing.
DATABASE_URL=postgresql://notes_user:CHANGE_ME@localhost:5432/notes_db
NODE_ENV=production
PORT=3000
ENVEOF
  chmod 600 /etc/notes-service.env
fi

log "Setup complete."
log ""
log "NEXT STEPS:"
log "  1. The CD pipeline will push the systemd unit and deploy the container."
log "  2. Make sure GitHub Secrets are configured:"
log "     TARGET_HOST, TARGET_USER, TARGET_SSH_KEY, DATABASE_URL"
log ""
log "=== Target node setup complete ==="