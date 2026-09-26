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
  # 第4引数: 参照コピー（前回反映時の内容）。回収後は実ファイルに合わせ、
  # 「実ファイルの変更は repo へ取り込み済み」と記録する。これがないと回収後に
  # repo を編集した場合、switch / apply-settings が drift と判定して止まる。
  local reference="$4"
  # 第5引数: public リポジトリへ載せないトップレベルキー（空白区切り・省略可）。
  # 会社用の autoMode / modelSettings は Claude Code が自動生成するため回収しない。
  local exclude="${5:-}"
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
    sync_reference "$current" "$reference"
    return 0
  fi

  install -m 0644 "$staged" "$source"
  rm -f "$staged"
  sync_reference "$current" "$reference"
  adopted=1
  echo "$label: repo へ回収しました -> ${source#"$repo_root"/}"
}

# 参照コピーを実ファイルに合わせる（除外キーも含めて丸ごと。比較時は除外される）
sync_reference() {
  local current="$1"
  local reference="$2"

  if [[ -f "$reference" ]] && json_equal "$current" "$reference"; then
    return 0
  fi
  mkdir -p "${reference%/*}"
  install -m 0644 "$current" "$reference"
  echo "  参照コピーを更新しました -> $reference"
}

adopt_claude() {
  adopt claude \
    "$HOME/.claude/settings.json" \
    "$repo_root/claude/settings.json" \
    "$HOME/.claude/.settings.json.nix-managed"
}

adopt_claude_work() {
  adopt claude-work \
    "$HOME/.claude-work/settings.json" \
    "$repo_root/claude-work/settings.json" \
    "$HOME/.claude-work/.settings.json.nix-managed" \
    "autoMode modelSettings"
}

adopt_antigravity_settings() {
  adopt antigravity-settings \
    "$HOME/.gemini/antigravity-cli/settings.json" \
    "$repo_root/gemini/antigravity-cli/settings.json" \
    "$HOME/.gemini/antigravity-cli/.settings.json.nix-managed"
}

adopt_antigravity_keybindings() {
  adopt antigravity-keybindings \
    "$HOME/.gemini/antigravity-cli/keybindings.json" \
    "$repo_root/gemini/antigravity-cli/keybindings.json" \
    "$HOME/.gemini/antigravity-cli/.keybindings.json.nix-managed"
}

case "$target" in
  all)
    adopt_claude
    adopt_claude_work
    adopt_antigravity_settings
    adopt_antigravity_keybindings
    ;;
  claude) adopt_claude ;;
  claude-work) adopt_claude_work ;;
  antigravity-settings) adopt_antigravity_settings ;;
  antigravity-keybindings) adopt_antigravity_keybindings ;;
  *)
    echo "usage: task adopt-settings TARGET=all|claude|claude-work|antigravity-settings|antigravity-keybindings" >&2
    exit 2
    ;;
esac

if [[ "$adopted" -eq 1 ]]; then
  echo "内容を確認してコミットしてください（参照コピーは更新済みのため、repo を編集後に task apply-settings / switch で反映できます）。"
fi
