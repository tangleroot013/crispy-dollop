#!/usr/bin/env bash
set -euo pipefail

# OPSEC: don't log secrets/tokens. Keep this script focused on network facts.
# Adjust targets if you want stricter allowlists.

EXPECTED_DNS="1.1.1.1"
EXPECTED_PROBE_IP="142.250.72.238"   # example IP (Google); change if you prefer
EXPECTED_PROBE_PORT="53"              # UDP probe port

# Where to store captures
CAPDIR="${CAPDIR:-/tmp/leak_test}"
mkdir -p "$CAPDIR"

WG_IF="${WG_IF:-wg0}"
TEST_IFACE_LIST=()

# Collect candidate interfaces (non-loopback, non-wg)
# We avoid parsing sysfs too deeply; keep it robust.
for ifc in $(ip -o link show | awk -F': ' '{print $2}' | cut -d' ' -f1); do
  [[ "$ifc" == "lo" ]] && continue
  [[ "$ifc" == "$WG_IF" ]] && continue
  TEST_IFACE_LIST+=("$ifc")
done

ts() { date +"%Y-%m-%dT%H:%M:%S%z"; }

echo "[$(ts)] Non-wg interfaces: ${TEST_IFACE_LIST[*]:-(none)}"
echo "[$(ts)] Captures dir: $CAPDIR"

# Start packet captures (non-wg)
NONWG_PIDS=()
NONWG_FILES=()
for ifc in "${TEST_IFACE_LIST[@]}"; do
  f="$CAPDIR/nonwg_${ifc}.pcap"
  NONWG_FILES+=("$f")
  # -U for packet-buffering, -n for no name resolution
  tcpdump -i "$ifc" -nn -U -s 0 -w "$f" &
  NONWG_PIDS+=($!)
done

# Capture wg0 too
WG_PCAP="$CAPDIR/wg0_${WG_IF}.pcap"
tcpdump -i "$WG_IF" -nn -U -s 0 -w "$WG_PCAP" &
WG_PID=$!

# Helper: stop background capture
cleanup() {
  set +e
  for p in "${NONWG_PIDS[@]}"; do kill "$p" 2>/dev/null || true; done
  kill "$WG_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Workload that would leak if kill-switch is broken.
# 1) DNS query (UDP/53) to EXPECTED_DNS
# 2) UDP probe to another known IP:53 (or change port)
# We use dig if present; fallback to netcat if needed.
do_workload() {
  # DNS query attempt
  if command -v dig >/dev/null 2>&1; then
    # Query a non-sensitive name to avoid logging content; only behavior matters.
    dig @"$EXPECTED_DNS" example.com +time=2 +tries=1 >/dev/null 2>&1 || true
  else
    # netcat/openbsd can do UDP probes; note this only probes connectivity.
    printf "test" | nc -u -w 2 "$EXPECTED_DNS" 53 >/dev/null 2>&1 || true
  fi

  # UDP probe (connectless payload)
  printf "probe" | nc -u -w 2 "$EXPECTED_PROBE_IP" "$EXPECTED_PROBE_PORT" >/dev/null 2>&1 || true
}

# -------------------------
# Phase A: wg0 expected DOWN
# -------------------------
echo "[$(ts)] Phase A: assuming wg0 is DOWN; testing for leaks via non-wg."
# If you have a kill-switch script, call it here:
if [[ -x "./scripts/kill-switch.sh" ]]; then
  ./scripts/kill-switch.sh || true
fi

# Give systemd time / allow routes to settle
sleep 3

do_workload
sleep 3

# Stop captures for Phase A by analyzing now (we keep one capture running; fine for simplicity).
# We'll just analyze what happened after we started; the script starts captures once.
# To isolate phases precisely, you can re-run script per phase; keep it simple by parsing later
# with timestamps if you want—below we assume each phase is short and separate by re-running.
echo "[$(ts)] Phase A done."

# -------------------------
# Phase B: wg0 expected UP
# -------------------------
echo "[$(ts)] Phase B: starting wg0; testing allowed egress via wg0 only."
if [[ -f "./scripts/start-vpn.sh" && -x ./scripts/start-vpn.sh ]]; then
  ./scripts/start-vpn.sh || true
elif command -v systemctl >/dev/null 2>&1; then
  systemctl start wg-quick@wg0 2>/dev/null || true
fi

sleep 5
do_workload
sleep 3

echo "[$(ts)] Phase B done."

# -------------------------
# Analysis: check non-wg pcaps
# -------------------------
echo "[$(ts)] Analyzing captures..."

# Simple heuristic:
# - If any packets exist in any non-wg pcap during Phase A, leak.
# We can't perfectly split Phase A/B with one capture, so do strict mode by re-running
# the script separately per phase if you want guaranteed separation.
leak_detected=0
for f in "${NONWG_FILES[@]}"; do
  if [[ ! -s "$f" ]]; then
    echo "  Non-wg capture $f: empty (OK)"
    continue
  fi
  # Count packets
  pkts="$(tcpdump -nn -r "$f" 2>/dev/null | wc -l | tr -d ' ')"
  echo "  Non-wg capture $f: $pkts packets"
  if [[ "$pkts" -gt 0 ]]; then
    leak_detected=1
  fi
done

wg_pkts="$(tcpdump -nn -r "$WG_PCAP" 2>/dev/null | wc -l | tr -d ' ')"
echo "  wg0 capture $WG_PCAP: $wg_pkts packets"

if [[ "$leak_detected" -eq 1 ]]; then
  echo "FAIL: Detected non-wg egress during kill-switch/leak window."
  exit 1
fi

echo "PASS: No non-wg packets observed (wg0 captured traffic: $wg_pkts)."
