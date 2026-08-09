#!/usr/bin/env bash
set -euo pipefail

WG_IFACE="${1:-wg0}"
MAX_AGE="${MAX_HANDSHAKE_AGE_SEC:-120}"

# Get the latest handshake timestamp for any peer on the interface
latest_handshake=$(sudo wg show "$WG_IFACE" latest-handshakes | awk '{print $2}' | sort -nr | head -n1)

if [[ -z "$latest_handshake" || "$latest_handshake" -eq 0 ]]; then
    echo "[FAIL] No handshake recorded on interface $WG_IFACE."
    exit 1
fi

current_time=$(date +%s)
age=$(( current_time - latest_handshake ))

echo "[*] Latest handshake was $age seconds ago (Threshold: ${MAX_AGE}s)."

if (( age > MAX_AGE )); then
    echo "[FAIL] Handshake is stale! Exceeds threshold of ${MAX_AGE} seconds."
    exit 1
fi

echo "[PASS] Handshake is fresh."
exit 0