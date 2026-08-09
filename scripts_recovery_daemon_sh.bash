#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/recovery-daemon.log"

log() {
    echo "$(date +'%F %T') [*] $1" | tee -a "$LOG"
}

WG_IFACE="wg0"
MAX_STALE_SEC=120
CHECK_INTERVAL_SEC=30

log "Starting Crispy-Dollop Recovery Daemon..."

while true; do
    # Check if interface exists
    if ! ip link show "$WG_IFACE" &>/dev/null; then
        log "Warning: Interface $WG_IFACE does not exist. Attempting restart..."
        sudo systemctl restart "wg-quick@$WG_IFACE" || true
        sleep 10
        continue
    fi

    # Check handshake freshness
    latest_handshake=$(sudo wg show "$WG_IFACE" latest-handshakes | awk '{print $2}' | sort -nr | head -n1 || echo "0")
    current_time=$(date +%s)
    
    if [[ -z "$latest_handshake" || "$latest_handshake" -eq 0 ]]; then
        age=$MAX_STALE_SEC + 1
    else
        age=$(( current_time - latest_handshake ))
    fi

    if (( age > MAX_STALE_SEC )); then
        log "ALERT: Handshake is stale ($age seconds old). Triggering recovery action..."
        
        # 1. Restart interface
        sudo systemctl restart "wg-quick@$WG_IFACE" || true
        sleep 15
        
        # 2. Re-run health test
        if bash scripts/test-connection.sh >/dev/null 2>&1; then
            log "Recovery successful: Tunnel restored."
        else
            log "Critical: Tunnel recovery failed. Triggering server rotation..."
            bash scripts/server-discovery.sh || true
        fi
    fi

    sleep "$CHECK_INTERVAL_SEC"
done