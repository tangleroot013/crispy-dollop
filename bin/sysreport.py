#!/usr/bin/env python3
import subprocess, shutil, os

def run(cmd):
    try:
        return subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception as e:
        return f"error: {e}"

def section(title):
    print(f"\n== {title} ==")

section("OS")
print(run("grep PRETTY_NAME /etc/os-release"))
print(run("uname -a"))

section("systemd --user")
print(run("systemctl --user is-system-running"))
print(run("systemctl --user --failed --no-legend") or "no failed units")

section("WireGuard")
print(run("sudo systemctl is-active wg-quick@wg0") or "inactive")
print(run("sudo wg show wg0 latest-handshakes") or "wg0 not up")

section("Toolchain")
for tool in ("zsh", "python3", "node", "npm", "git"):
    print(f"{tool}: {shutil.which(tool) or 'MISSING'}")

section("Terminal")
print(f"TERM={os.environ.get('TERM')}")
