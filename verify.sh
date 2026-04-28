#!/usr/bin/env bash
# verify.sh — runs on the target node after deployment.
# Checks: service availability, nginx config, endpoint correctness.
set -euo pipefail

BASE_URL="http://localhost"
ERRORS=0
WARNINGS=0

pass() { echo "  ✅ PASS: $*"; }
fail() { echo "  ❌ FAIL: $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠️  WARN: $*"; WARNINGS=$((WARNINGS + 1)); }

section() { echo ""; echo "━━━ $* ━━━"; }

# ── Helper: HTTP check ────────────────────────────────────────────────────────
check_http() {
  local desc="$1" url="$2" expected_code="$3" expected_body="${4:-}"
  local actual_code actual_body
  actual_code=$(curl -s -o /tmp/verify_body -w "%{http_code}" \
    --max-time 5 "$url" 2>/dev/null || echo "000")
  actual_body=$(cat /tmp/verify_body 2>/dev/null || echo "")

  if [ "$actual_code" != "$expected_code" ]; then
    fail "${desc}: expected HTTP ${expected_code}, got ${actual_code}"
    return
  fi

  if [ -n "$expected_body" ] && ! echo "$actual_body" | grep -q "$expected_body"; then
    fail "${desc}: body does not contain '${expected_body}' (got: ${actual_body:0:100})"
    return
  fi

  pass "$desc (HTTP ${actual_code})"
}

# ══════════════════════════════════════════════════════════════════════════════
section "1. Systemd Service Status"
# ══════════════════════════════════════════════════════════════════════════════

SERVICE="notes-service.service"

if systemctl is-active --quiet "$SERVICE"; then
  pass "systemd unit '${SERVICE}' is active"
else
  fail "systemd unit '${SERVICE}' is NOT active"
  systemctl status "$SERVICE" --no-pager --lines=20 || true
fi

if systemctl is-enabled --quiet "$SERVICE"; then
  pass "systemd unit '${SERVICE}' is enabled (survives reboot)"
else
  warn "systemd unit '${SERVICE}' is not enabled"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "2. Docker Container"
# ══════════════════════════════════════════════════════════════════════════════

if docker ps --format '{{.Names}}' | grep -q "^notes-service$"; then
  pass "Docker container 'notes-service' is running"
  CONTAINER_IMAGE=$(docker inspect notes-service \
    --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
  pass "Running image: ${CONTAINER_IMAGE}"
else
  fail "Docker container 'notes-service' is NOT running"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "3. Nginx Configuration"
# ══════════════════════════════════════════════════════════════════════════════

if nginx -t 2>/dev/null; then
  pass "nginx configuration syntax is valid"
else
  fail "nginx configuration has errors"
fi

if systemctl is-active --quiet nginx; then
  pass "nginx is active"
else
  fail "nginx is NOT active"
fi

# Check that nginx listens on port 80
if ss -tlnp | grep -q ':80 '; then
  pass "nginx is listening on port 80"
else
  fail "nothing is listening on port 80"
fi

# Check that nginx proxies to local app (not exposing port 3000 publicly)
if ss -tlnp | grep ':3000' | grep -q '127.0.0.1'; then
  pass "app port 3000 is bound only to 127.0.0.1 (not publicly exposed)"
elif ! ss -tlnp | grep -q ':3000'; then
  warn "port 3000 does not appear to be listening (container may not be ready)"
else
  fail "app port 3000 is publicly exposed — it should be 127.0.0.1 only"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "4. Application Health Endpoints"
# ══════════════════════════════════════════════════════════════════════════════

check_http "GET /health/alive" "${BASE_URL}/health/alive" "200" "OK"
check_http "GET /health/ready" "${BASE_URL}/health/ready" "200" "OK"

# ══════════════════════════════════════════════════════════════════════════════
section "5. Notes API Functional Check"
# ══════════════════════════════════════════════════════════════════════════════

# Create a note
TIMESTAMP=$(date +%s)
CREATE_BODY="{\"title\":\"verify-${TIMESTAMP}\",\"content\":\"automated verification\"}"
CREATE_RESP=$(curl -s -o /tmp/create_resp -w "%{http_code}" \
  -X POST "${BASE_URL}/notes" \
  -H "Content-Type: application/json" \
  -d "$CREATE_BODY" \
  --max-time 5 2>/dev/null || echo "000")

if [ "$CREATE_RESP" = "201" ] || [ "$CREATE_RESP" = "200" ]; then
  pass "POST /notes returns ${CREATE_RESP}"
  NOTE_ID=$(cat /tmp/create_resp | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2 || echo "")
else
  fail "POST /notes returned ${CREATE_RESP}"
fi

# List notes
check_http "GET /notes" "${BASE_URL}/notes" "200"

# Get single note (if we have an ID)
if [ -n "${NOTE_ID:-}" ]; then
  check_http "GET /notes/${NOTE_ID}" "${BASE_URL}/notes/${NOTE_ID}" "200" "verify-${TIMESTAMP}"
fi

# 404 for non-existent note
check_http "GET /notes/999999 (expect 404)" "${BASE_URL}/notes/999999" "404"

# ══════════════════════════════════════════════════════════════════════════════
section "6. Nginx Headers & Security"
# ══════════════════════════════════════════════════════════════════════════════

HEADERS=$(curl -sI "${BASE_URL}/health/alive" --max-time 5 2>/dev/null || echo "")

if echo "$HEADERS" | grep -qi "server: nginx"; then
  pass "Server header identifies as nginx"
else
  warn "Server header does not mention nginx"
fi

# ══════════════════════════════════════════════════════════════════════════════
section "Summary"
# ══════════════════════════════════════════════════════════════════════════════

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "🎉 All checks passed! (${WARNINGS} warning(s))"
  exit 0
else
  echo "💥 ${ERRORS} check(s) FAILED, ${WARNINGS} warning(s)"
  exit 1
fi
