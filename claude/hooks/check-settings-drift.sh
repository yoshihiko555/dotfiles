#!/usr/bin/env bash

# Claude Code Stop hook: home-manager が最後に生成した内容との差分を即時通知する。
set -euo pipefail

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
current="$claude_dir/settings.json"
reference="$claude_dir/.settings.json.nix-managed"

[[ -f "$current" && -f "$reference" ]] || exit 0

current_normalized="$(mktemp)"
reference_normalized="$(mktemp)"
trap 'rm -f "$current_normalized" "$reference_normalized"' EXIT

if jq -S . "$current" >"$current_normalized" 2>/dev/null \
  && jq -S . "$reference" >"$reference_normalized" 2>/dev/null; then
  different=0
  cmp -s "$current_normalized" "$reference_normalized" || different=1
else
  different=0
  cmp -s "$current" "$reference" || different=1
fi

if [[ "$different" -eq 1 ]]; then
  echo '{"systemMessage":"⚠️ ~/.claude/settings.json の drift を検出しました。task adopt-settings TARGET=claude で repo へ回収できます。"}'
fi
