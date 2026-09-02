#!/usr/bin/env python3
"""Audit music_manifest.json entries against actual audio tracks in storage."""
import json
from pathlib import Path

HOME = Path.home()
MANIFEST_PATH = HOME / "music_manifest.json"
STORAGE_DIR = Path("/mnt/chromeos/MyFiles/Downloads")

def audit_manifest() -> None:
    if not MANIFEST_PATH.exists():
        print(f"❌ Manifest not found at {MANIFEST_PATH}")
        return

    try:
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except Exception as e:
        print(f"❌ Failed to parse manifest JSON: {e}")
        return

    tracks = manifest.get("tracks", []) if isinstance(manifest, dict) else manifest
    print(f"🎵 Auditing {len(tracks)} entries in manifest...")

    missing_count = 0
    for item in tracks:
        rel_path = item.get("file") if isinstance(item, dict) else item
        if not rel_path:
            continue
        expected_file = STORAGE_DIR / rel_path
        if not expected_file.exists():
            print(f"⚠️ Missing File: {rel_path}")
            missing_count += 1

    if missing_count == 0:
        print("✓ All manifest tracks verified in storage!")
    else:
        print(f"❌ Found {missing_count} missing track(s).")

if __name__ == "__main__":
    audit_manifest()
