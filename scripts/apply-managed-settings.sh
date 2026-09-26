#!/usr/bin/env bash
# mutable 設定（Claude Code / Antigravity CLI の JSON）を repo から実ファイルへ反映する。
#
#   これらのアプリは JSON を rename で置換するため symlink では管理できない。
#   repo を正として実ファイルを生成し、前回反映時の参照コピー（.nix-managed）と
#   差がある間（= アプリが書き換えた drift 中）は上書きを拒否する。
#   repo へ回収後は target == source になるため再開できる。
#
#   switch（home.activation.mutableDotfiles）と task apply-settings の両方から呼ぶ。
#   回収（実ファイル → repo）は scripts/adopt-managed-settings.sh。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
target="${1:-all}"

JQ="${JQ:-jq}"

json_equal() {
  local left="$1"
  local right="$2"
  # 第3引数: 比較前に適用する jq フィルタ（省略時は全体を比較）
  local filter="${3:-.}"
  local left_normalized right_normalized equal

  left_normalized="$(mktemp)"
  right_normalized="$(mktemp)"

  if "$JQ" -S "$filter" "$left" >"$left_normalized" 2>/dev/null \
    && "$JQ" -S "$filter" "$right" >"$right_normalized" 2>/dev/null; then
    if cmp -s "$left_normalized" "$right_normalized"; then
      equal=0
    else
      equal=1
    fi
  elif cmp -s "$left" "$right"; then
    equal=0
  else
    equal=1
  fi

  rm -f "$left_normalized" "$right_normalized"
  return "$equal"
}

manage_mutable_json() {
  local label="$1"
  local source="$2"
  local target="$3"
  local reference="$4"
  # 第5引数: repo では管理せず実ファイル側の値を引き継ぐトップレベルキー。
  # 空白区切りで複数指定できる。Claude Code が自動生成する autoMode や
  # modelSettings のように、public リポジトリへ載せたくない・端末側で
  # 書き換わる内容を drift 比較からも除外する用途で使う。
  local preserve="${5:-}"

  local compare_filter="."
  local preserve_keys_json="[]"
  if [[ -n "$preserve" ]]; then
    local del_args=""
    local key
    for key in $preserve; do
      [[ -n "$del_args" ]] && del_args="${del_args},"
      del_args="${del_args}.${key}"
    done
    compare_filter="del(${del_args})"
    # shellcheck disable=SC2086 # preserve は空白区切りのキー一覧
    preserve_keys_json="$(printf '%s\n' $preserve | "$JQ" -R . | "$JQ" -s -c .)"
  fi

  if ! "$JQ" -e . "$source" >/dev/null 2>&1; then
    echo "warning: $label: repo 側が不正な JSON のため更新を拒否しました: $source" >&2
    return 0
  fi

  mkdir -p "${target%/*}"

  if [[ -e "$target" && ! -f "$target" ]]; then
    echo "warning: $label: 通常ファイルではないため更新を拒否しました: $target" >&2
    return 0
  fi

  if [[ -f "$target" && -f "$reference" ]] \
    && ! json_equal "$target" "$reference" "$compare_filter"; then
    if ! json_equal "$target" "$source" "$compare_filter"; then
      echo "warning: $label の drift を検出。上書きしません。" >&2
      echo "warning: task adopt-settings TARGET=$label で repo へ回収してから再度反映してください。" >&2
      return 0
    fi
  elif [[ -f "$target" && ! -f "$reference" ]] \
    && ! json_equal "$target" "$source" "$compare_filter"; then
    echo "warning: $label: 初回管理時の既存内容が repo と異なるため上書きしません。" >&2
    echo "warning: 内容を確認し、task adopt-settings TARGET=$label で回収してください。" >&2
    return 0
  fi

  # 引き継ぎは target を消す前に済ませる
  local generated="$source"
  if [[ -n "$preserve" && -f "$target" ]]; then
    generated="$(mktemp)"
    # shellcheck disable=SC2016 # $k / $keys は jq の変数
    "$JQ" -s --argjson keys "$preserve_keys_json" \
      '.[0] + (.[1] | with_entries(select(.key as $k | $keys | index($k) != null)))' \
      "$source" "$target" >"$generated"
  fi

  if [[ -L "$target" ]]; then
    rm -f "$target"
  fi

  install -m 0644 "$generated" "$target"
  install -m 0644 "$generated" "$reference"
  if [[ "$generated" != "$source" ]]; then
    rm -f "$generated"
  fi
  echo "$label: 反映しました -> $target"
}

apply_claude() {
  manage_mutable_json \
    claude \
    "$repo_root/claude/settings.json" \
    "$HOME/.claude/settings.json" \
    "$HOME/.claude/.settings.json.nix-managed"
}

apply_claude_work() {
  manage_mutable_json \
    claude-work \
    "$repo_root/claude-work/settings.json" \
    "$HOME/.claude-work/settings.json" \
    "$HOME/.claude-work/.settings.json.nix-managed" \
    "autoMode modelSettings"
}

apply_antigravity_settings() {
  manage_mutable_json \
    antigravity-settings \
    "$repo_root/gemini/antigravity-cli/settings.json" \
    "$HOME/.gemini/antigravity-cli/settings.json" \
    "$HOME/.gemini/antigravity-cli/.settings.json.nix-managed"
}

apply_antigravity_keybindings() {
  manage_mutable_json \
    antigravity-keybindings \
    "$repo_root/gemini/antigravity-cli/keybindings.json" \
    "$HOME/.gemini/antigravity-cli/keybindings.json" \
    "$HOME/.gemini/antigravity-cli/.keybindings.json.nix-managed"
}

case "$target" in
  all)
    apply_claude
    apply_claude_work
    apply_antigravity_settings
    apply_antigravity_keybindings
    ;;
  claude) apply_claude ;;
  claude-work) apply_claude_work ;;
  antigravity-settings) apply_antigravity_settings ;;
  antigravity-keybindings) apply_antigravity_keybindings ;;
  *)
    echo "usage: task apply-settings TARGET=all|claude|claude-work|antigravity-settings|antigravity-keybindings" >&2
    exit 2
    ;;
esac
