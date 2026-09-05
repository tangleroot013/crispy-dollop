#!/usr/bin/env bash
set -euo pipefail

REQUIRED_PKGS=(jq curl wireguard-tools dnsutils iproute2 netcat-openbsd tcpdump python3)

echo "[*] Checking and installing missing system packages..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends "${REQUIRED_PKGS[@]}"
echo "✅ All required system packages are installed."