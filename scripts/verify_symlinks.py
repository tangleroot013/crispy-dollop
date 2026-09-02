#!/usr/bin/env python3
"""Verify and automatically restore Crostini persistent symlinks."""
import os
from pathlib import Path

HOME = Path.home()
TARGET_MAP = {
    HOME / "github_projects": HOME / "home-data" / "github_projects",
    HOME / ".ssh": HOME / "home-data" / ".ssh",
    HOME / "Music": Path("/mnt/chromeos/MyFiles/Downloads"),
}

def audit_symlinks() -> None:
    print("📌 Auditing Crostini Symlink Health...")
    for link, target in TARGET_MAP.items():
        if not target.exists():
            print(f"⚠️ Target missing: {target}")
            continue

        if link.is_symlink():
            current_target = link.readlink()
            if current_target == target:
                print(f"✓ OK: {link.name} -> {target}")
            else:
                print(f"⚡ Fixing misdirected link: {link.name}")
                link.unlink()
                link.symlink_to(target)
        elif link.exists():
            print(f"❌ Error: {link} exists but is a real file/directory, not a symlink.")
        else:
            print(f"🔗 Creating missing symlink: {link.name} -> {target}")
            link.symlink_to(target)

if __name__ == "__main__":
    audit_symlinks()
