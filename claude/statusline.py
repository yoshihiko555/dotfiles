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


PERSONAL_ORG_TYPES = {"claude_pro", "claude_max"}
WORK_ORG_TYPES = {"claude_team", "claude_enterprise"}
BADGE_PERSONAL = "\033[48;2;97;175;239m"
BADGE_WORK = "\033[48;2;229;140;60m"
BADGE_PROXY = "\033[48;2;92;99;112m"
BADGE_UNKNOWN = "\033[48;2;224;108;117m"
BADGE_TEXT = "\033[38;2;40;44;52m"


def account_badge():
    """ログイン中のアカウントを箱の色で、profile 名（ccp が渡す。無ければ dev）を箱の文字で返す。判定できなければ赤。"""
    label = f"{BADGE_TEXT} {os.environ.get('CLAUDE_PROFILE') or 'dev'} {R}"
    config_dir = os.environ.get("CLAUDE_CONFIG_DIR")
    path = os.path.join(config_dir, ".claude.json") if config_dir else os.path.expanduser("~/.claude.json")
    try:
        with open(path) as f:
            org_type = (json.load(f).get("oauthAccount") or {}).get("organizationType", "")
    except Exception:
        org_type = ""
    if org_type in WORK_ORG_TYPES:
        badge = f"{BADGE_WORK}{label}"
    elif org_type in PERSONAL_ORG_TYPES:
        badge = f"{BADGE_PERSONAL}{label}"
    else:
        badge = f"{BADGE_UNKNOWN}{label}"
    # ccx はログイン情報が個人のままプロキシ経由で通信する
    if os.environ.get("ANTHROPIC_BASE_URL"):
        badge += f"{BADGE_PROXY}  {R}"
    return badge


def format_duration(ms):
    minutes = int(ms // 60000)
    if minutes < 60:
        return f"{minutes}m"
    hours, minutes = divmod(minutes, 60)
    if hours < 24:
        return f"{hours}h{minutes:02d}m"
    days, hours = divmod(hours, 24)
    return f"{days}d{hours}h"


workspace = data.get("workspace", {})
cwd = workspace.get("current_dir") or data.get("cwd", "")

# ── Line 1 (top): Account │ Project │ Branch │ Lines │ PR ──
line1_parts = []

line1_head = account_badge()
worktree = workspace.get("git_worktree")
if worktree and cwd:
    repo = (workspace.get("repo") or {}).get("name")
    if not repo:
        common = git_cmd("rev-parse", "--path-format=absolute", "--git-common-dir", cwd=cwd)
        repo = os.path.basename(os.path.dirname(common)) if common else os.path.basename(cwd)
    wt = worktree if len(worktree) <= 24 else worktree[:23] + "…"
    line1_head += f" 📁 {WHITE}{repo}{R} 🌳 {DIM}{wt}{R}"
elif cwd:
    line1_head += f" 📁 {WHITE}{os.path.basename(cwd)}{R}"
line1_parts.append(line1_head)

branch = git_cmd("symbolic-ref", "--short", "HEAD", cwd=cwd) if cwd else ""
if not branch and cwd:
    branch = git_cmd("rev-parse", "--short", "HEAD", cwd=cwd)
if branch:
    line1_parts.append(f"🌿 {GREEN}{branch}{R}")

added = data.get("cost", {}).get("total_lines_added", 0)
removed = data.get("cost", {}).get("total_lines_removed", 0)
if added or removed:
    line1_parts.append(f"✏️ {GREEN}+{added}{R} {RED}-{removed}{R}")

pr = data.get("pr") or {}
if pr.get("number"):
    kind = "MR" if pr.get("kind") == "mr" else "PR"
    pr_str = f"{YELLOW}{BOLD}{kind}{R} {YELLOW}#{pr['number']}{R}"
    state = pr.get("review_state")
    if state == "approved":
        pr_str += f" {GREEN}approved{R}"
    elif state == "changes_requested":
        pr_str += f" {RED}changes{R}"
    elif state == "draft":
        pr_str += f" {DIM}draft{R}"
    line1_parts.append(pr_str)

# ── Line 2 (mid): Model │ ctx │ cache ──
line2_parts = []

model_raw = data.get("model", {}).get("display_name", "Claude")
model = model_raw.replace("Claude ", "")
effort = (data.get("effort") or {}).get("level")
line2_parts.append(f"{BOLD}{model}{R}" + (f" {DIM}{effort}{R}" if effort else ""))

ctx = data.get("context_window", {}).get("used_percentage")
if ctx is not None:
    line2_parts.append(fmt("ctx", ctx))

# cache: セッションの入力のうちキャッシュから読めた割合。miss は作り直しの回数、cold は期限切れ
cache = data.get("prompt_cache") or {}
hit = cache.get("hit_ratio")
if cache.get("caching_observed") and hit is not None:
    hit_pct = round(hit * 100)
    color = GREEN if hit_pct >= 90 else YELLOW if hit_pct >= 70 else RED
    cache_str = f"{DIM}cache{R} {color}{hit_pct}%{R}"
    misses = cache.get("misses") or 0
    if misses:
        cache_str += f" {YELLOW}miss {misses}{R}"
    if not cache.get("warm", True):
        cache_str += f" {RED}cold{R}"
    line2_parts.append(cache_str)

# ── Line 3 (bottom): Elapsed │ 5h │ 7d ──
line3_parts = []

duration_ms = data.get("cost", {}).get("total_duration_ms")
if duration_ms and duration_ms >= 60000:
    line3_parts.append(f"⏱ {DIM}{format_duration(duration_ms)}{R}")

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
