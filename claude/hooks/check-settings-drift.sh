#!/usr/bin/env bash

# Claude Code Stop hook: home-manager が最後に生成した内容との差分を即時通知する。
set -euo pipefail

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
current="$claude_dir/settings.json"
reference="$claude_dir/.settings.json.nix-managed"

# 会社アカウント（~/.claude-work）の autoMode / modelSettings は repo で管理しないため
# 比較から除く。除外キーは dotfiles.nix の manage_mutable_json の preserve 引数と揃える。
case "$claude_dir" in
  */.claude-work)
    label="claude-work"
    filter='del(.autoMode,.modelSettings)'
    ;;
  *)
    label="claude"
    filter='.'
    ;;
esac

[[ -f "$current" && -f "$reference" ]] || exit 0

current_normalized="$(mktemp)"
reference_normalized="$(mktemp)"
trap 'rm -f "$current_normalized" "$reference_normalized"' EXIT

if jq -S "$filter" "$current" >"$current_normalized" 2>/dev/null \
  && jq -S "$filter" "$reference" >"$reference_normalized" 2>/dev/null; then
  different=0
  cmp -s "$current_normalized" "$reference_normalized" || different=1
else
  different=0
  cmp -s "$current" "$reference" || different=1
fi

if [[ "$different" -eq 1 ]]; then
  printf '{"systemMessage":"⚠️ %s/settings.json の drift を検出しました。task adopt-settings TARGET=%s で repo へ回収できます。"}\n' \
    "${claude_dir/#"$HOME"/\~}" "$label"
fi
