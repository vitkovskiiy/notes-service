#!/usr/bin/env bash
# runner-setup.sh — prepares a fresh Ubuntu 24.04 VM as a GitHub Actions self-hosted runner.
# Run as a non-root user with sudo privileges.
# NOTE: The final step (connecting runner to repo) must be done MANUALLY
#       to avoid storing the registration token in the repository.
set -euo pipefail

RUNNER_VERSION="2.322.0"
RUNNER_DIR="${HOME}/actions-runner"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ── 1. Install dependencies ───────────────────────────────────────────────────
log "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl \
  jq \
  git \
  docker.io \
  openssh-client \
  libicu-dev

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
log "Added ${USER} to docker group"

# ── 2. Download GitHub Actions Runner ─────────────────────────────────────────
log "Downloading GitHub Actions Runner v${RUNNER_VERSION}..."
mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

ARCH=$(dpkg --print-architecture)
case "${ARCH}" in
  amd64)  RUNNER_ARCH="x64"   ;;
  arm64)  RUNNER_ARCH="arm64" ;;
  *)      echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac

RUNNER_PKG="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}"

curl -fsSL -O "${RUNNER_URL}"
tar xzf "${RUNNER_PKG}"
rm "${RUNNER_PKG}"

log "Runner downloaded and extracted to ${RUNNER_DIR}"

# ── 3. Install runner dependencies ────────────────────────────────────────────
log "Installing runner OS dependencies..."
sudo "${RUNNER_DIR}/bin/installdependencies.sh"

# ── 4. Instructions for manual registration ───────────────────────────────────
cat <<'INSTRUCTIONS'

════════════════════════════════════════════════════════════════════
  MANUAL STEP REQUIRED — DO NOT SKIP
════════════════════════════════════════════════════════════════════

  The runner must be registered manually to avoid storing tokens
  in the repository (GitHub security recommendation).

  Steps:
  1. Go to your repository on GitHub:
       https://github.com/vitkovskiiy/notes-service/settings/actions/runners/new

  2. Copy the token from the "Configure" section.

  3. Run the following commands (replace TOKEN with your token):

       cd ~/actions-runner
       ./config.sh \
         --url https://github.com/vitkovskiiy/notes-service \
         --token <YOUR_TOKEN> \
         --name "deploy-runner" \
         --labels "self-hosted,deploy" \
         --runnergroup "Default" \
         --unattended

  4. Install and start the runner as a systemd service:

       sudo ./svc.sh install
       sudo ./svc.sh start

  5. Verify the runner appears as "Online" in GitHub:
       https://github.com/vitkovskiiy/notes-service/settings/actions/runners

════════════════════════════════════════════════════════════════════
  IMPORTANT SECURITY NOTE
════════════════════════════════════════════════════════════════════

  After completing the lab demos:
  - Stop the runner:   sudo ~/actions-runner/svc.sh stop
  - Remove the runner: sudo ~/actions-runner/svc.sh uninstall
  - Or shut down / delete the VM entirely.

  Self-hosted runners on public repos are a security risk if left
  running unattended.

════════════════════════════════════════════════════════════════════

INSTRUCTIONS

log "=== Runner setup complete. Follow the manual steps above. ==="
