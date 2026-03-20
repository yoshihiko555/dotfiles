#!/usr/bin/env python3
"""Claude Code statusline - Braille dots with project info"""
import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta

data = json.load(sys.stdin)

BRAILLE = " ⣀⣄⣤⣦⣶⣷⣿"
R = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
CYAN = "\033[38;2;97;175;239m"
YELLOW = "\033[38;2;229;192;123m"
GREEN = "\033[38;2;151;201;195m"
RED = "\033[38;2;224;108;117m"
WHITE = "\033[38;2;220;223;228m"
GRAY = "\033[38;2;74;88;92m"

SEP = f" {GRAY}│{R} "


def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f"\033[38;2;{r};200;80m"
    else:
        g = int(200 - (pct - 50) * 4)
        return f"\033[38;2;255;{max(g, 0)};60m"


def braille_bar(pct, width=8):
    pct = min(max(pct, 0), 100)
    level = pct / 100
    bar = ""
    for i in range(width):
        seg_start = i / width
        seg_end = (i + 1) / width
        if level >= seg_end:
            bar += BRAILLE[7]
        elif level <= seg_start:
            bar += BRAILLE[0]
        else:
            frac = (level - seg_start) / (seg_end - seg_start)
            bar += BRAILLE[min(int(frac * 7), 7)]
    return bar


JST = timezone(timedelta(hours=9))


def format_reset(iso_str):
    """ISO 8601 reset time to JST short format (e.g. '3pm', '3/24 3pm')."""
    try:
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00")).astimezone(JST)
        now = datetime.now(JST)
        h = dt.strftime("%-I%p").lower()
        if dt.date() == now.date():
            return h
        if (dt.date() - now.date()).days <= 6:
            return dt.strftime("%-m/%-d ") + h
        return dt.strftime("%-m/%-d ") + h
    except Exception:
        return ""


def fmt(label, pct, reset_str=""):
    p = round(pct)
    reset_part = f" {DIM}({reset_str}){R}" if reset_str else ""
    return f"{DIM}{label}{R} {gradient(pct)}{braille_bar(pct)}{R} {p}%{reset_part}"


def git_cmd(*args, cwd=None):
    try:
        result = subprocess.run(
            ["git"] + list(args),
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=3,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except Exception:
        return ""


def gh_pr_number(cwd):
    try:
        remote = git_cmd("remote", "get-url", "origin", cwd=cwd)
        if not remote:
            return ""
        result = subprocess.run(
            ["gh", "pr", "view", "--json", "number", "--jq", ".number", "-R", remote],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=5,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except Exception:
        return ""


# ── Line 1: Model │ ctx │ 5h (reset) │ 7d (reset) ──
model_raw = data.get("model", {}).get("display_name", "Claude")
model = model_raw.replace("Claude ", "")
parts = [f"{BOLD}{model}{R}"]

ctx = data.get("context_window", {}).get("used_percentage")
if ctx is not None:
    parts.append(fmt("ctx", ctx))

five_data = data.get("rate_limits", {}).get("five_hour", {})
five = five_data.get("used_percentage")
if five is not None:
    five_reset = format_reset(five_data.get("resets_at", ""))
    parts.append(fmt("5h", five, five_reset))

week_data = data.get("rate_limits", {}).get("seven_day", {})
week = week_data.get("used_percentage")
if week is not None:
    week_reset = format_reset(week_data.get("resets_at", ""))
    parts.append(fmt("7d", week, week_reset))

line1 = SEP.join(parts)

cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd", "")

# ── Line 2: Project │ Branch │ Lines │ PID │ PR ──
line2_parts = []

# Project
if cwd:
    line2_parts.append(f"📁 {WHITE}{os.path.basename(cwd)}{R}")

# Git branch
branch = git_cmd("symbolic-ref", "--short", "HEAD", cwd=cwd) if cwd else ""
if not branch and cwd:
    branch = git_cmd("rev-parse", "--short", "HEAD", cwd=cwd)
if branch:
    line2_parts.append(f"🌿 {GREEN}{branch}{R}")

# Lines changed
added = data.get("cost", {}).get("total_lines_added", 0)
removed = data.get("cost", {}).get("total_lines_removed", 0)
if added or removed:
    line2_parts.append(f"✏️ {GREEN}+{added}{R}{RED}-{removed}{R}")

# PID
line2_parts.append(f"🔧 {CYAN}PID:{os.getppid()}{R}")

# PR
pr = gh_pr_number(cwd) if cwd else ""
if pr:
    line2_parts.append(f"{YELLOW}{BOLD}PR{R} {YELLOW}#{pr}{R}")

line2 = SEP.join(line2_parts)

# ── Output ──
print(line2)
print(line1, end="")
