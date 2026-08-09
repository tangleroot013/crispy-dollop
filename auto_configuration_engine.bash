#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="/etc/wireguard"
sudo mkdir -p "$CONFIG_DIR"
sudo chmod 700 "$CONFIG_DIR"

# 1. Generate keys if missing
if [[ ! -f "$CONFIG_DIR/privatekey" ]]; then
    echo "[*] Generating fresh WireGuard key pair..."
    wg genkey | sudo tee "$CONFIG_DIR/privatekey" >/dev/null
    sudo chmod 600 "$CONFIG_DIR/privatekey"
    sudo wg pubkey < "$CONFIG_DIR/privatekey" | sudo tee "$CONFIG_DIR/publickey" >/dev/null
    sudo chmod 600 "$CONFIG_DIR/publickey"
fi

# 2. Run server discovery if json missing
if [[ ! -f "config/mullvad-servers.json" ]]; then
    echo "[*] Fetching Mullvad server list..."
    bash scripts/server-discovery.sh
fi

echo "[*] Configuration engine ready."