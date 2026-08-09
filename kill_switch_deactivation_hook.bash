#!/usr/bin/env bash
set -euo pipefail
WG_IFACE="${1:-wg0}"

echo "[*] Deactivating firewall kill-switch for ${WG_IFACE}..."
sudo iptables -D OUTPUT ! -o "$WG_IFACE" -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true
sudo ip6tables -D OUTPUT ! -o "$WG_IFACE" -m addrtype ! --dst-type LOCAL -j REJECT 2>/dev/null || true