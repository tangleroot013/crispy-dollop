#!/usr/bin/env python3
"""Idempotent snapshot of systemd --user units + .zshrc.local into a git repo."""
import subprocess, shutil, pathlib, datetime, sys

HOME = pathlib.Path.home()
REPO = HOME / "home-data" / "dotfiles-snapshot"
SRC_UNITS = HOME / ".config" / "systemd" / "user"
SRC_ZSHRC = HOME / ".zshrc.local"

def run(cmd, cwd=None, check=True):
    r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode != 0:
        print(f"FAILED: {cmd}\n{r.stderr}", file=sys.stderr)
        sys.exit(1)
    return r.stdout.strip()

REPO.mkdir(parents=True, exist_ok=True)

if not (REPO / ".git").exists():
    run("git init -q", cwd=REPO)
    (REPO / ".gitignore").write_text(
        "/*\n!/.gitignore\n!/systemd-user/\n!/zshrc.local\n"
    )
    print(f"initialized repo at {REPO}")

dest_units = REPO / "systemd-user"
if dest_units.exists():
    shutil.rmtree(dest_units)
shutil.copytree(SRC_UNITS, dest_units)

shutil.copy2(SRC_ZSHRC, REPO / "zshrc.local")

run("git add -A", cwd=REPO)
status = run("git status --porcelain", cwd=REPO)
if not status:
    print("no changes, nothing to commit")
    sys.exit(0)

msg = f"snapshot: {datetime.datetime.now():%Y-%m-%d_%H:%M}"
run(f'git commit -q -m "{msg}"', cwd=REPO)
print(run("git log --oneline -5", cwd=REPO))
