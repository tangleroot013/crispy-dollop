#!/usr/bin/env bash
set -euo pipefail

WG_IFACE="${1:-wg0}"
TARGET_HOST="10.64.0.1" # Mullvad internal gateway or public target

echo "[*] Measuring latency over ${WG_IFACE}..."
if ping -c 3 -I "$WG_IFACE" "$TARGET_HOST" >/dev/null 2>&1; then
    ping -c 3 -I "$WG_IFACE" "$TARGET_HOST" | tail -n 2
else
    echo "[!] Ping test failed. Checking general external latency..."
    ping -c 3 1.1.1.1
fi