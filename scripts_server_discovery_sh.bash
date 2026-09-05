#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="config"
CACHE_FILE="$CACHE_DIR/mullvad-servers.json"
TTL_HOURS=12

mkdir -p "$CACHE_DIR"

# Check if cache exists and is fresh (< 12 hours old)
if [[ -f "$CACHE_FILE" ]]; then
    file_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE") ))
    if (( file_age < TTL_HOURS * 3600 )); then
        echo "[*] Using cached Mullvad server list (age: $(( file_age / 60 )) minutes)."
        exit 0
    fi
fi

echo "[*] Fetching fresh Mullvad WireGuard relay list from API..."
API_URL="https://api.mullvad.net/wg/v1/relays"

if curl -sSf "$API_URL" -o "$CACHE_FILE.tmp"; then
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    echo "✅ Successfully updated server cache at $CACHE_FILE"
else
    echo "[!] Warning: Failed to fetch live Mullvad relay list. Falling back to previous cache if available."
    rm -f "$CACHE_FILE.tmp"
    if [[ ! -f "$CACHE_FILE" ]]; then
        echo "Error: No cached server list available and API unreachable."
        exit 1
    fi
fi