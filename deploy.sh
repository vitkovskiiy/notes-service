#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="notes-service"
ENV_FILE="/etc/notes-service.env"



log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== Starting deployment of ${IMAGE} ==="

# ── 1. Login to GHCR ──────────────────────────────────────────────────────────
log "Logging in to GitHub Container Registry..."
echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin

# ── 2. Pull new image ─────────────────────────────────────────────────────────
log "Pulling image: ${IMAGE}"
docker pull "${IMAGE}"

# ── 3. Write environment file ─────────────────────────────────────────────────
log "Writing environment file to ${ENV_FILE}..."
sudo tee "${ENV_FILE}" > /dev/null <<EOF
DATABASE_URL=${DATABASE_URL}
NODE_ENV=production
PORT=3000
EOF
sudo chmod 644 "${ENV_FILE}"

# ── 4. Install / update systemd unit ──────────────────────────────────────────


log "Installing systemd unit..."
# Додаємо шлях /tmp/ перед назвою файлу
sudo sed "s|\${IMAGE}|${IMAGE}|g" /tmp/notes-service.service | sudo tee /etc/systemd/system/notes-service.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable notes-service

# ── 5. Run Prisma migrations ───────────────────────────────────────────────────
log "Running database migrations..."
docker run --rm \
  --env-file "${ENV_FILE}" \
  "${IMAGE}" \
  npx prisma db push

# ── 6. Restart service ────────────────────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable notes-service
sudo systemctl restart notes-service

# ── 7. Wait for service to be healthy ─────────────────────────────────────────
log "Waiting for service to become healthy..."
sleep 10 # Даємо застосунку час реально піднятися

# Стукаємо прямо на 3000 порт локалхоста (куди Docker прокинув 8000)
if curl -sf http://127.0.0.1:3000/health/alive; then
    log "Service is healthy!"
else
    log "ERROR: Service did not become healthy"
    systemctl status notes-service
    exit 1
fi

# ── 8. Remove old images to free disk space ───────────────────────────────────
log "Pruning dangling Docker images..."
docker image prune -f || true

log "=== Deployment of ${TAG} completed successfully ==="
