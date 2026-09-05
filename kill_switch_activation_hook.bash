#!/usr/bin/env bash
set -euo pipefail
WG_IFACE="${1:-wg0}"

echo "[*] Activating firewall kill-switch for ${WG_IFACE}..."
sudo iptables -I OUTPUT ! -o "$WG_IFACE" -m addrtype ! --dst-type LOCAL -j REJECT
sudo ip6tables -I OUTPUT ! -o "$WG_IFACE" -m addrtype ! --dst-type LOCAL -j REJECT