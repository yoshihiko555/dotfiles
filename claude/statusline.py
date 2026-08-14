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
DIM = "\033[38;2;140;150;160m"
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


def format_reset(value):
    """Reset time to JST short format (e.g. '3pm', '3/24 3pm').

    Accepts Unix timestamp (int/float) or ISO 8601 string.
    """
    try:
        if isinstance(value, (int, float)):
            dt = datetime.fromtimestamp(value, tz=JST)
        elif isinstance(value, str) and value:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00")).astimezone(JST)
        else:
            return ""
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


cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd", "")

# ── Line 1 (top): Project │ Branch │ PR ──
line1_parts = []

if cwd:
    line1_parts.append(f"📁 {WHITE}{os.path.basename(cwd)}{R}")

branch = git_cmd("symbolic-ref", "--short", "HEAD", cwd=cwd) if cwd else ""
if not branch and cwd:
    branch = git_cmd("rev-parse", "--short", "HEAD", cwd=cwd)
if branch:
    line1_parts.append(f"🌿 {GREEN}{branch}{R}")

line1_parts.append(f"🔧 {CYAN}PID:{os.getppid()}{R}")

pr = gh_pr_number(cwd) if cwd else ""
if pr:
    line1_parts.append(f"{YELLOW}{BOLD}PR{R} {YELLOW}#{pr}{R}")

# ── Line 2 (mid): Model │ ctx │ Lines ──
line2_parts = []

model_raw = data.get("model", {}).get("display_name", "Claude")
model = model_raw.replace("Claude ", "")
line2_parts.append(f"{BOLD}{model}{R}")

ctx = data.get("context_window", {}).get("used_percentage")
if ctx is not None:
    line2_parts.append(fmt("ctx", ctx))

added = data.get("cost", {}).get("total_lines_added", 0)
removed = data.get("cost", {}).get("total_lines_removed", 0)
if added or removed:
    line2_parts.append(f"✏️ {GREEN}+{added}{R} {RED}-{removed}{R}")

# ── Line 3 (bottom): 5h │ 7d ──
line3_parts = []

five_data = data.get("rate_limits", {}).get("five_hour", {})
five = five_data.get("used_percentage")
if five is not None:
    five_reset = format_reset(five_data.get("resets_at", ""))
    line3_parts.append(fmt("5h", five, five_reset))

week_data = data.get("rate_limits", {}).get("seven_day", {})
week = week_data.get("used_percentage")
if week is not None:
    week_reset = format_reset(week_data.get("resets_at", ""))
    line3_parts.append(fmt("7d", week, week_reset))

# ── Output ──
print(SEP.join(line1_parts))
print(SEP.join(line2_parts))
print(SEP.join(line3_parts), end="")
