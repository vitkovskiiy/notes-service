#!/usr/bin/env bash
# deploy.sh — runs ON the target node via SSH from the self-hosted runner.
# Required env vars: IMAGE, TAG, DATABASE_URL, GHCR_TOKEN, GHCR_USER
set -euo pipefail

APP_NAME="notes-service"
SERVICE_NAME="${APP_NAME}.service"
SYSTEMD_DIR="/etc/systemd/system"
ENV_FILE="/etc/${APP_NAME}.env"

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
sudo cp /tmp/${SERVICE_NAME} "${SYSTEMD_DIR}/${SERVICE_NAME}"
sudo systemctl daemon-reload

# ── 5. Run Prisma migrations ───────────────────────────────────────────────────
log "Running database migrations..."
docker run --rm \
  --env-file "${ENV_FILE}" \
  "${IMAGE}" \
  npx prisma migrate deploy

# ── 6. Restart service ────────────────────────────────────────────────────────
log "Restarting ${SERVICE_NAME}..."
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"

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
