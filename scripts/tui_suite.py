#!/usr/bin/env python3
"""
Interactive Terminal User Interface (TUI) for Polyglot DevOps & ZIP Tools.
Personalized for tangleroot013's ChromeOS/Crostini workflow.
Features 'EZ-Zip' pipeline for FUSE file copying, MD5 checksum verification,
Zip Slip security checks, archive extraction, and GitHub repository sync.
"""

import curses
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import List, Tuple, Optional


class DialogHelper:
    """Helper class for curses prompt dialogs and interactive interventions."""

    @staticmethod
    def draw_box(stdscr, title: str, height: int, width: int) -> Tuple[int, int]:
        max_y, max_x = stdscr.getmaxyx()
        start_y = max(0, (max_y - height) // 2)
        start_x = max(0, (max_x - width) // 2)

        win = curses.newwin(height, width, start_y, start_x)
        win.box()
        win.attron(curses.A_BOLD | curses.color_pair(2))
        win.addstr(0, 2, f" {title} ")
        win.attroff(curses.A_BOLD | curses.color_pair(2))
        win.refresh()
        return start_y, start_x

    @staticmethod
    def prompt_text(stdscr, prompt_msg: str, default: str = "") -> str:
        stdscr.clear()
        max_y, max_x = stdscr.getmaxyx()
        win = curses.newwin(7, min(75, max_x - 4), max_y // 2 - 3, max_x // 2 - 37)
        win.box()
        win.addstr(1, 2, prompt_msg[:70], curses.A_BOLD)
        win.addstr(3, 2, f"Input [{default if default else 'None'}]: ")
        win.refresh()

        curses.echo()
        curses.curs_set(1)
        input_bytes = win.getstr(3, 12 + min(len(default), 20), 50)
        curses.noecho()
        curses.curs_set(0)

        result = input_bytes.decode("utf-8").strip()
        return result if result else default

    @staticmethod
    def confirm_action(stdscr, title: str, warning_msg: str) -> bool:
        stdscr.clear()
        max_y, max_x = stdscr.getmaxyx()
        win = curses.newwin(8, min(75, max_x - 4), max_y // 2 - 4, max_x // 2 - 37)
        win.box()
        win.attron(curses.color_pair(3) | curses.A_BOLD)
        win.addstr(0, 2, f" ALERT: {title} ")
        win.attroff(curses.color_pair(3) | curses.A_BOLD)

        win.addstr(2, 2, warning_msg[:70])
        win.addstr(4, 2, "Press [Y] to confirm and proceed, or [N] to cancel.")
        win.refresh()

        while True:
            key = stdscr.getch()
            if key in (ord('y'), ord('Y')):
                return True
            elif key in (ord('n'), ord('N'), 27):  # 27 = ESC
                return False


def calculate_md5(file_path: Path) -> str:
    """Calculate MD5 checksum of a file."""
    hasher = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def run_ez_zip_pipeline(stdscr) -> str:
    """
    Unified EZ-Zip Pipeline:
    1. Resolve ChromeOS FUSE mount issues by copying ZIP to local Linux container (~/).
    2. Calculate & verify MD5 checksum.
    3. Safely unpack with Zip Slip & overwrite protection.
    4. Optional GitHub repo initialization.
    """
    # Auto-detect default ChromeOS path for tangleroot013
    chromeos_default = "/mnt/chromeos/MyFiles/Downloads/ez_tagger.zip"
    chromeos_alt = "/mnt/chromeos/MyFiles/Downloads/ez_zip.zip"
    if os.path.exists(chromeos_alt):
        chromeos_default = chromeos_alt
        
    fallback_default = str(Path.home() / "ez_zip.zip")
    default_source = chromeos_default if os.path.exists(chromeos_default) else fallback_default

    source_input = DialogHelper.prompt_text(
        stdscr,
        "Tangleroot013's Source Zip (ChromeOS mount or local):",
        default=default_source
    )
    if not source_input:
        return "EZ-Zip: Cancelled (No source file provided)."

    source_path = Path(source_input).expanduser().resolve()
    if not source_path.is_file():
        return f"Error: Source file '{source_path}' does not exist."

    # Step 1: Copy from ChromeOS FUSE mount to container home directory (~/) if needed
    local_target = Path.home() / source_path.name
    if source_path != local_target:
        should_copy = DialogHelper.confirm_action(
            stdscr,
            "Crostini FUSE Safety Copy",
            f"Copy '{source_path.name}' to local home (~/) to prevent stale reads?"
        )
        if should_copy:
            try:
                shutil.copy2(source_path, local_target)
                source_path = local_target
            except Exception as err:
                return f"Error copying file to local filesystem: {err}"

    # Step 2: Calculate MD5 Checksum
    actual_md5 = calculate_md5(source_path)
    expected_md5 = DialogHelper.prompt_text(
        stdscr,
        f"Calculated MD5: {actual_md5}. Enter expected MD5 to verify:",
        default="3ee4b27f58ef34f9e674725dba5e2aa2"
    )

    if expected_md5 and actual_md5.lower() != expected_md5.lower():
        proceed_anyway = DialogHelper.confirm_action(
            stdscr,
            "MD5 MISMATCH WARNING",
            f"Expected {expected_md5[:8]}... but got {actual_md5[:8]}... Extract anyway?"
        )
        if not proceed_anyway:
            return f"Aborted: Checksum mismatch for '{source_path.name}' (MD5: {actual_md5})."

    # Step 3: Destination selection & extraction
    dest_default = str(Path.home() / "github_projects" / source_path.stem)
    dest_input = DialogHelper.prompt_text(
        stdscr,
        "Extraction Directory:",
        default=dest_default
    )
    dest_dir = Path(dest_input).expanduser().resolve()
    dest_dir.mkdir(parents=True, exist_ok=True)

    extracted_count = 0
    try:
        with zipfile.ZipFile(source_path, "r") as zipf:
            for member in zipf.infolist():
                target_path = (dest_dir / member.filename).resolve()

                # Zip Slip Protection
                if not target_path.is_relative_to(dest_dir):
                    allow_slip = DialogHelper.confirm_action(
                        stdscr,
                        "Zip Slip Security Guard",
                        f"Skipping potentially unsafe path: '{member.filename}'"
                    )
                    if not allow_slip:
                        continue

                # Overwrite Guard
                if target_path.exists() and not member.is_dir():
                    overwrite = DialogHelper.confirm_action(
                        stdscr,
                        "File Exists",
                        f"Overwrite '{member.filename}'?"
                    )
                    if not overwrite:
                        continue

                zipf.extract(member, path=dest_dir)
                extracted_count += 1
    except Exception as err:
        return f"Extraction failed: {err}"

    # Step 4: GitHub Repo Creation Prompt
    init_gh = DialogHelper.confirm_action(
        stdscr,
        "GitHub Publishing",
        f"Publish extracted files in '{dest_dir.name}' to Tangleroot013's GitHub?"
    )
    if init_gh:
        repo_name = DialogHelper.prompt_text(
            stdscr,
            "Enter GitHub Repository Name (owner/repo):",
            default=f"tangleroot013/{dest_dir.name}"
        )
        try:
            cmd = [
                "gh", "repo", "create", repo_name,
                "--private",
                f"--source={dest_dir}",
                "--remote=origin",
                "--push"
            ]
            res = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return f"EZ-Zip Pipeline Complete! Unpacked {extracted_count} items & created repo '{repo_name}'."
        except subprocess.CalledProcessError as err:
            return f"Unpacked {extracted_count} items, but GitHub repo creation failed: {err.stderr.strip()}"

    return f"EZ-Zip Pipeline Complete! Successfully unpacked {extracted_count} items to:\n{dest_dir}"


def run_interactive_git_sync(stdscr) -> str:
    """Interactively commit & push changes with optional GPG key intervention."""
    commit_msg = DialogHelper.prompt_text(stdscr, "Enter commit message:", default="chore: automated state sync")

    use_gpg = DialogHelper.confirm_action(stdscr, "GPG Signing", "Do you want to specify a custom GPG key ID?")
    gpg_key = ""
    if use_gpg:
        gpg_key = DialogHelper.prompt_text(stdscr, "Enter GPG Key ID:")

    cmd = ["git", "status", "--porcelain"]
    status_out = subprocess.run(cmd, capture_output=True, text=True)

    if not status_out.stdout.strip():
        return "Git Sync: No unstaged or uncommitted changes detected."

    confirm_push = DialogHelper.confirm_action(stdscr, "Confirm Commit & Push", f"Message: '{commit_msg}'")
    if not confirm_push:
        return "Git sync cancelled by user."

    try:
        subprocess.run(["git", "add", "-A"], check=True)
        commit_cmd = ["git", "commit"]
        if gpg_key:
            commit_cmd.append(f"-S{gpg_key}")
        else:
            commit_cmd.append("-S")
        commit_cmd.extend(["-m", commit_msg])

        subprocess.run(commit_cmd, check=True)
        subprocess.run(["git", "push"], check=True)
        return "Git Auto-Sync completed successfully!"
    except subprocess.CalledProcessError as err:
        return f"Git operation failed: {err}"


def run_cache_invalidation(stdscr) -> str:
    """Generates cache keys and offers interactive rule overrides."""
    root = Path(".")
    patterns = [
        "**/build.gradle.kts",
        "**/requirements.txt",
        "**/poetry.lock",
        "**/gradle-wrapper.properties",
    ]

    add_more = DialogHelper.confirm_action(stdscr, "Cache Scope", "Include additional file patterns?")
    if add_more:
        extra_pattern = DialogHelper.prompt_text(stdscr, "Enter glob pattern (e.g., *.json):")
        if extra_pattern:
            patterns.append(extra_pattern)

    hasher = hashlib.sha256()
    matched_files = []
    for pattern in sorted(patterns):
        for path in sorted(root.glob(pattern)):
            if path.is_file():
                matched_files.append(path.name)
                hasher.update(path.name.encode("utf-8"))
                hasher.update(path.read_bytes())

    key = f"v1-cache-{hasher.hexdigest()[:16]}"
    return f"Generated Cache Key: {key}\nFiles hashed: {', '.join(matched_files) if matched_files else 'None'}"


def draw_main_menu(stdscr, selected_idx: int, menu_items: List[str]):
    stdscr.clear()
    max_y, max_x = stdscr.getmaxyx()

    # Title Banner
    title = " TANGLEROOT013's DEVOPS & EZ-ZIP SUITE "
    stdscr.attron(curses.color_pair(1) | curses.A_BOLD)
    stdscr.addstr(1, max(0, (max_x - len(title)) // 2), title)
    stdscr.attroff(curses.color_pair(1) | curses.A_BOLD)

    stdscr.addstr(3, 4, "Select an action (Use Arrow Keys Up/Down, Enter to Select, Q to Quit):")

    # Draw Menu Boxes
    for i, item in enumerate(menu_items):
        y = 5 + i * 2
        if i == selected_idx:
            stdscr.attron(curses.color_pair(2) | curses.A_BOLD)
            stdscr.addstr(y, 6, f"> {item} <")
            stdscr.attroff(curses.color_pair(2) | curses.A_BOLD)
        else:
            stdscr.addstr(y, 8, item)

    stdscr.refresh()


def main_tui(stdscr):
    # Colors setup
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    curses.init_pair(2, curses.COLOR_GREEN, -1)
    curses.init_pair(3, curses.COLOR_YELLOW, -1)
    curses.curs_set(0)

    menu_items = [
        "1. Run EZ-Zip Pipeline (Copy, Verify MD5, Unpack & Sync)",
        "2. Git Auto-Sync & Signed Commit",
        "3. CI/CD Build Cache Key Generator",
        "4. Exit"
    ]
    selected_idx = 0
    status_message = "Ready."

    while True:
        draw_main_menu(stdscr, selected_idx, menu_items)

        # Status Footer
        max_y, max_x = stdscr.getmaxyx()
        stdscr.attron(curses.color_pair(1))
        stdscr.addstr(max_y - 4, 4, f"Status: {status_message}"[:max_x - 8])
        stdscr.attroff(curses.color_pair(1))

        key = stdscr.getch()

        if key == curses.KEY_UP and selected_idx > 0:
            selected_idx -= 1
        elif key == curses.KEY_DOWN and selected_idx < len(menu_items) - 1:
            selected_idx += 1
        elif key in (10, 13):  # Enter key
            if selected_idx == 0:
                status_message = run_ez_zip_pipeline(stdscr)
            elif selected_idx == 1:
                status_message = run_interactive_git_sync(stdscr)
            elif selected_idx == 2:
                status_message = run_cache_invalidation(stdscr)
            elif selected_idx == 3:
                break
        elif key in (ord('q'), ord('Q')):
            break


if __name__ == "__main__":
    try:
        curses.wrapper(main_tui)
    except KeyboardInterrupt:
        print("\nExited TUI.")
