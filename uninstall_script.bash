#!/usr/bin/env bash
set -euo pipefail

echo "🦆 Uninstalling Crispy-Dollop WireGuard setup..."

# 1. Stop and disable WireGuard service if running
if systemctl is-active --quiet wg-quick@wg0.service 2>/dev/null; then
    echo "Stopping wg-quick@wg0 service..."
    sudo systemctl stop wg-quick@wg0.service
fi

if systemctl is-enabled --quiet wg-quick@wg0.service 2>/dev/null; then
    echo "Disabling wg-quick@wg0 service..."
    sudo systemctl disable wg-quick@wg0.service
fi

# 2. Securely wipe cryptographic materials
if [[ -f /etc/wireguard/privatekey ]]; then
    echo "Securely shredding private key..."
    sudo shred -u /etc/wireguard/privatekey || sudo rm -f /etc/wireguard/privatekey
fi

# 3. Remove configurations and public keys
sudo rm -f /etc/wireguard/publickey 
sudo rm -f /etc/wireguard/wg0.conf 
sudo rm -f /etc/wireguard/privatekey.bak || true

echo "✅ Uninstallation complete. Keys and configurations securely purged."