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
sudo sed "s|\${IMAGE}|${IMAGE}|g" notes-service.service | sudo tee /etc/systemd/system/notes-service.service > /dev/null

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
for i in $(seq 1 15); do
  if curl -sf http://localhost/health/alive > /dev/null 2>&1; then
    log "Service is healthy after ${i}s"
    break
  fi
  if [ "$i" -eq 15 ]; then
    log "ERROR: Service did not become healthy within 15 seconds"
    sudo systemctl status "${SERVICE_NAME}" --no-pager || true
    exit 1
  fi
  sleep 1
done

# ── 8. Remove old images to free disk space ───────────────────────────────────
log "Pruning dangling Docker images..."
docker image prune -f || true

log "=== Deployment of ${TAG} completed successfully ==="
