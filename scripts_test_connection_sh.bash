#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/mullvad-test-report-$(date +%Y%m%d-%H%M%S).txt"

run_check() {
  local name="$1"
  local cmd="$2"
  echo "----------------------------------------"
  echo "[*] Running check: $name"
  if eval "$cmd" >> "$LOG" 2>&1; then
    echo "✅ [PASS] $name"
    return 0
  else
    echo "❌ [FAIL] $name (rc=$?)" | tee -a "$LOG"
    return 1
  fi
}

echo "🦆 Crispy-Dollop WireGuard Health Audit" | tee "$LOG"
echo "Timestamp: $(date -u)" | tee -a "$LOG"

# Execute suite
run_check "peer-handshake" "sudo wg show wg0 | grep -q handshake"
run_check "handshake-freshness" "MAX_HANDSHAKE_AGE_SEC=120 bash scripts/handshake-freshness-test.sh"
run_check "internet-reachability" "curl -sSf https://api.ipify.org > /dev/null"
run_check "dns-leak-prevention" "bash scripts/dns-leak-test.sh"
run_check "route-validation" "ip route show | grep -q 'default'"

echo "----------------------------------------"
echo "✅ Audit completed. Full logs written to $LOG"