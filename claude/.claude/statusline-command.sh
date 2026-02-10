#!/usr/bin/env bash

# StatusLine script for Claude Code
# Shows: directory, git info, model, cost, context usage, time

input=$(cat)

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Short directory (last 3 components, ~ for home)
short_dir="${cwd/#$HOME/\~}"
short_dir=$(echo "$short_dir" | awk -F'/' '{
  n = NF
  if (n <= 3) print $0
  else { printf "…/"; for (i=n-2;i<=n;i++) { printf "%s",$i; if(i<n) printf "/" } }
}')

# Git branch
git_branch=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir &>/dev/null; then
  git_branch=$(git -C "$cwd" branch --show-current 2>/dev/null || echo "detached")
fi

# Cost formatting
cost_fmt=$(printf '$%.2f' "$cost")

# Duration formatting
duration_sec=$((duration_ms / 1000))
mins=$((duration_sec / 60))
secs=$((duration_sec % 60))
duration_fmt="${mins}m${secs}s"

# Context bar color (green/yellow/red)
if [ "$context_pct" -ge 90 ] 2>/dev/null; then
  ctx_color="\033[31m"  # red
elif [ "$context_pct" -ge 70 ] 2>/dev/null; then
  ctx_color="\033[33m"  # yellow
else
  ctx_color="\033[32m"  # green
fi

# Build output
printf "\033[2m%s\033[0m" "$short_dir"
if [ -n "$git_branch" ]; then
  printf " \033[2m %s\033[0m" "$git_branch"
fi
printf "  \033[2m%s\033[0m" "$model_name"
printf "  \033[33m%s\033[0m" "$cost_fmt"
printf "  ${ctx_color}%s%%\033[0m" "$context_pct"
printf "  \033[32m+%s\033[0m \033[31m-%s\033[0m" "$lines_added" "$lines_removed"
printf "  \033[2m%s\033[0m" "$duration_fmt"
