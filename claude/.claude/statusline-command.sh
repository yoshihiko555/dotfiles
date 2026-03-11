#!/usr/bin/env bash
# Claude Code Statusline - Multi-line rich display
# Layout:
#   📁 directory path
#   🐙 repo-name │ 🌿 branch
#   🧠 [progress bar] N% │ 💪 Model
#   💰 5h N% (🔄 reset) │ 7d N% (🔄 reset)
#   ✏️ +added/-removed │ 🔧 PID:xxxxx │ PR #N

set -euo pipefail

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf "\033[2mjq not found\033[0m"
  exit 0
fi

# ── Colors (true color) ──
GREEN="\033[38;2;151;201;195m"
YELLOW="\033[38;2;229;192;123m"
RED="\033[38;2;224;108;117m"
CYAN="\033[38;2;97;175;239m"
GRAY="\033[38;2;74;88;92m"
WHITE="\033[38;2;220;223;228m"
BOLD="\033[1m"
RESET="\033[0m"

color_for_pct() {
  local pct=$1
  if (( pct >= 80 )); then
    printf '%s' "$RED"
  elif (( pct >= 50 )); then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# ── Progress bar (10 segments) ──
progress_bar() {
  local pct=$1
  local filled=$(( pct / 10 ))
  local empty=$(( 10 - filled ))
  local color
  color=$(color_for_pct "$pct")
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="▰"; done
  for ((i=0; i<empty; i++)); do bar+="▱"; done
  printf '%b%s%b' "$color" "$bar" "$RESET"
}

# ── Extract fields from JSON ──
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

claude_pid=$PPID

# Context percentage (integer)
ctx_int=0
if [ -n "$used_pct" ]; then
  printf -v ctx_int "%.0f" "$used_pct" 2>/dev/null || ctx_int="${used_pct%%.*}"
fi
ctx_color=$(color_for_pct "$ctx_int")

# Short directory path (replace $HOME with ~)
short_path="${cwd/#$HOME/\~}"

# Repository name
repo_name=$(basename "$cwd")

# Git branch
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

# PR number (cached, check once per session)
pr_number=""
if [ -n "$cwd" ] && command -v gh >/dev/null 2>&1; then
  pr_number=$(gh pr view --json number --jq '.number' -R "$(git -C "$cwd" remote get-url origin 2>/dev/null)" 2>/dev/null || true)
fi

sep="${GRAY} │ ${RESET}"

# ── Line 1: Directory path ──
line1="📁 ${WHITE}${short_path}${RESET}"

# ── Line 2: Repo │ Branch ──
line2="🐙 ${WHITE}${repo_name}${RESET}"
if [ -n "$git_branch" ]; then
  line2+="${sep}🌿 ${GREEN}${git_branch}${RESET}"
fi

# ── Line 3: Context bar + Model ──
ctx_bar=$(progress_bar "$ctx_int")
line3="🧠 ${ctx_bar} ${ctx_color}${BOLD}${ctx_int}%${RESET}${sep}💪 ${CYAN}${model_name}${RESET}"

# ── Line 4: Usage API (OAuth, cached 360s) ──
CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=360

fetch_usage() {
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  if [ -z "$token" ]; then
    return 1
  fi

  local access_token
  access_token=$(echo "$token" | jq -r '.claudeAiOauth.accessToken // .accessToken // .access_token // empty' 2>/dev/null || true)
  if [ -z "$access_token" ]; then
    return 1
  fi

  local response
  response=$(curl -sf --max-time 5 \
    -H "Authorization: Bearer ${access_token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null) || return 1

  local now
  now=$(date +%s)
  echo "$response" | jq --arg ts "$now" '. + {cached_at: ($ts | tonumber)}' > "$CACHE_FILE" 2>/dev/null
  echo "$response"
}

get_usage() {
  local now
  now=$(date +%s)

  if [ -f "$CACHE_FILE" ]; then
    local cached_at
    cached_at=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null || echo "0")
    local age=$(( now - cached_at ))
    if (( age < CACHE_TTL )); then
      jq -r 'del(.cached_at)' "$CACHE_FILE" 2>/dev/null
      return 0
    fi
  fi

  fetch_usage
}

# Convert ISO 8601 to epoch seconds (macOS compatible)
iso_to_epoch() {
  local iso_time=$1
  local stripped="${iso_time%%.*}"
  TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null || echo ""
}

format_5h_reset() {
  local iso_time=$1
  local epoch
  epoch=$(iso_to_epoch "$iso_time")
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"%-l%p" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

format_7d_reset() {
  local iso_time=$1
  local epoch
  epoch=$(iso_to_epoch "$iso_time")
  [ -z "$epoch" ] && return
  LC_ALL=en_US.UTF-8 TZ="Asia/Tokyo" date -r "$epoch" +"%-m/%-d %-l%p" 2>/dev/null | sed 's/AM/am/;s/PM/pm/'
}

line4=""

usage_json=$(get_usage 2>/dev/null || true)

if [ -n "$usage_json" ]; then
  five_util=$(echo "$usage_json" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  five_reset=$(echo "$usage_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  seven_util=$(echo "$usage_json" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
  seven_reset=$(echo "$usage_json" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

  five_part=""
  if [ -n "$five_util" ]; then
    printf -v five_int "%.0f" "$five_util" 2>/dev/null || five_int="${five_util%%.*}"
    five_color=$(color_for_pct "$five_int")
    five_reset_str=""
    if [ -n "$five_reset" ]; then
      five_reset_str=$(format_5h_reset "$five_reset")
    fi
    five_part="💰 5h ${five_color}${BOLD}${five_int}%${RESET}"
    if [ -n "$five_reset_str" ]; then
      five_part+=" (🔄 ${five_reset_str})"
    fi
  fi

  seven_part=""
  if [ -n "$seven_util" ]; then
    printf -v seven_int "%.0f" "$seven_util" 2>/dev/null || seven_int="${seven_util%%.*}"
    seven_color=$(color_for_pct "$seven_int")
    seven_reset_str=""
    if [ -n "$seven_reset" ]; then
      seven_reset_str=$(format_7d_reset "$seven_reset")
    fi
    seven_part="7d ${seven_color}${BOLD}${seven_int}%${RESET}"
    if [ -n "$seven_reset_str" ]; then
      seven_part+=" (🔄 ${seven_reset_str})"
    fi
  fi

  if [ -n "$five_part" ] && [ -n "$seven_part" ]; then
    line4="${five_part}${sep}${seven_part}"
  elif [ -n "$five_part" ]; then
    line4="$five_part"
  elif [ -n "$seven_part" ]; then
    line4="$seven_part"
  fi
fi

# ── Line 5: Lines changed │ PID │ PR ──
line5="✏️ ${GREEN}+${lines_added}${RESET}${RED}-${lines_removed}${RESET}"
line5+="${sep}🔧 ${CYAN}PID:${claude_pid}${RESET}"
if [ -n "$pr_number" ]; then
  line5+="${sep}${YELLOW}${BOLD}PR${RESET} ${YELLOW}#${pr_number}${RESET}"
fi

# ── Output ──
printf '%b\n' "$line1"
printf '%b\n' "$line2"
printf '%b\n' "$line3"
if [ -n "$line4" ]; then
  printf '%b\n' "$line4"
fi
printf '%b' "$line5"
