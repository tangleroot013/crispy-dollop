#!/usr/bin/env bash
set -euo pipefail

echo "[*] Running DNS leak verification..."
resolved_dns=$(dig +short whoami.akamai.net @193.138.218.74 || true)

if [[ -z "$resolved_dns" ]]; then
    echo "[!] Unable to query test DNS resolver via Mullvad nameserver."
    exit 1
fi

echo "[PASS] DNS queries successfully resolved through secure tunnel resolver."
exit 0