#!/usr/bin/env bash

# StatusLine script for Claude Code
# Shows: directory, git info, model, cost, context usage, time

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf "\033[2mjq not found\033[0m"
  exit 0
fi

# Extract fields from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
context_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null | cut -d. -f1)
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
claude_pid=$PPID

if ! [[ "$context_pct" =~ ^[0-9]+$ ]]; then
  context_pct="--"
fi

# Short directory (project name only = last component)
short_dir=$(basename "$cwd")

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
if [ "$context_pct" = "--" ]; then
  ctx_color="\033[2m"  # dim
elif [ "$context_pct" -ge 90 ] 2>/dev/null; then
  ctx_color="\033[31m"  # red
elif [ "$context_pct" -ge 70 ] 2>/dev/null; then
  ctx_color="\033[33m"  # yellow
else
  ctx_color="\033[32m"  # green
fi

if [ "$context_pct" = "--" ]; then
  context_label="$context_pct"
else
  context_label="${context_pct}%"
fi

# Build output
printf "\033[2m%s\033[0m" "$short_dir"
if [ -n "$git_branch" ]; then
  printf " \033[2m %s\033[0m" "$git_branch"
fi
printf "  \033[2m%s\033[0m" "$model_name"
printf "  \033[33m%s\033[0m" "$cost_fmt"
printf "  ${ctx_color}%s\033[0m" "$context_label"
printf "  \033[32m+%s\033[0m \033[31m-%s\033[0m" "$lines_added" "$lines_removed"
printf "  \033[2m%s\033[0m" "$duration_fmt"
if [ -n "$claude_pid" ]; then
  printf "  \033[36mPID:%s\033[0m" "$claude_pid"
fi
