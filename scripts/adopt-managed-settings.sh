#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
target="${1:-all}"
adopted=0

json_equal() {
  local left="$1"
  local right="$2"
  local left_normalized right_normalized result

  left_normalized="$(mktemp)"
  right_normalized="$(mktemp)"
  if jq -S . "$left" >"$left_normalized" 2>/dev/null \
    && jq -S . "$right" >"$right_normalized" 2>/dev/null; then
    if cmp -s "$left_normalized" "$right_normalized"; then
      result=0
    else
      result=1
    fi
  else
    if cmp -s "$left" "$right"; then
      result=0
    else
      result=1
    fi
  fi
  rm -f "$left_normalized" "$right_normalized"
  return "$result"
}

adopt() {
  local label="$1"
  local current="$2"
  local source="$3"
  # 第4引数: public リポジトリへ載せないトップレベルキー（空白区切り・省略可）。
  # 会社用の autoMode / modelSettings は Claude Code が自動生成するため回収しない。
  local exclude="${4:-}"
  local staged

  if [[ ! -f "$current" ]]; then
    echo "error: $label の実ファイルがありません: $current" >&2
    return 1
  fi
  if ! jq -e . "$current" >/dev/null 2>&1; then
    echo "error: $label は不正な JSON のため回収しません: $current" >&2
    return 1
  fi

  staged="$(mktemp)"
  if [[ -n "$exclude" ]]; then
    local del_args=""
    local key
    for key in $exclude; do
      [[ -n "$del_args" ]] && del_args="${del_args},"
      del_args="${del_args}.${key}"
    done
    jq "del(${del_args})" "$current" >"$staged"
  else
    cp "$current" "$staged"
  fi

  if json_equal "$staged" "$source"; then
    echo "$label: drift なし"
    rm -f "$staged"
    return 0
  fi

  install -m 0644 "$staged" "$source"
  rm -f "$staged"
  adopted=1
  echo "$label: repo へ回収しました -> ${source#"$repo_root"/}"
}

case "$target" in
  all)
    adopt claude "$HOME/.claude/settings.json" "$repo_root/claude/settings.json"
    adopt claude-work \
      "$HOME/.claude-work/settings.json" \
      "$repo_root/claude-work/settings.json" \
      "autoMode modelSettings"
    adopt antigravity-settings \
      "$HOME/.gemini/antigravity-cli/settings.json" \
      "$repo_root/gemini/antigravity-cli/settings.json"
    adopt antigravity-keybindings \
      "$HOME/.gemini/antigravity-cli/keybindings.json" \
      "$repo_root/gemini/antigravity-cli/keybindings.json"
    ;;
  claude)
    adopt claude "$HOME/.claude/settings.json" "$repo_root/claude/settings.json"
    ;;
  claude-work)
    adopt claude-work \
      "$HOME/.claude-work/settings.json" \
      "$repo_root/claude-work/settings.json" \
      "autoMode modelSettings"
    ;;
  antigravity-settings)
    adopt antigravity-settings \
      "$HOME/.gemini/antigravity-cli/settings.json" \
      "$repo_root/gemini/antigravity-cli/settings.json"
    ;;
  antigravity-keybindings)
    adopt antigravity-keybindings \
      "$HOME/.gemini/antigravity-cli/keybindings.json" \
      "$repo_root/gemini/antigravity-cli/keybindings.json"
    ;;
  *)
    echo "usage: task adopt-settings TARGET=all|claude|claude-work|antigravity-settings|antigravity-keybindings" >&2
    exit 2
    ;;
esac

if [[ "$adopted" -eq 1 ]]; then
  echo "内容を確認後、nix-darwin を switch すると参照コピーが更新されます。"
fi
