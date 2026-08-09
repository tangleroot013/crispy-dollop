#!/usr/bin/env bash
set -euo pipefail

echo "🦆 Crispy-Dollop WireGuard Setup Wrapper"
echo "======================================"

# Ensure we are running on a supported OS (Linux)
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "Error: This setup requires a Linux environment."
    exit 1
fi

# Determine if we are running inside Docker
if [[ ! -f /.dockerenv ]]; then
    echo "[*] Host environment detected. Running dependency installation..."
    # Ensure scripts are executable before calling
    chmod +x scripts/*.sh
    bash scripts/install-wg-deb.sh
else
    echo "[*] Docker environment detected. Skipping apt installs."
    # Make sure scripts are executable
    chmod +x scripts/*.sh
fi

echo "[*] Handing off to core configurator..."
bash scripts/auto-config.sh

echo "[*] Setup wrapper complete."