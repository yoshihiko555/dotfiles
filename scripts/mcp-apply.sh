#!/bin/bash
# Claude Code の user scope MCP をリポジトリの正典から適用するスクリプト
# 正典: shared/mcp/user-servers.json
# 適用先: ~/.claude.json の user scope（symlink 不可の mutable state のため流し込み方式）
# 使い方: bash scripts/mcp-apply.sh [--dry-run] [--force]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$REPO_ROOT/shared/mcp/user-servers.json"
DRY_RUN=false
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    *)
      echo "不明なオプション: $arg" >&2
      echo "使い方: bash scripts/mcp-apply.sh [--dry-run] [--force]" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$SOURCE" ]]; then
  echo "正典ファイルなし: $SOURCE" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude コマンドが見つかりません" >&2
  exit 1
fi

$DRY_RUN && echo "[dry-run] 変更は実行しません" && echo ""
$FORCE && echo "[force] 既存定義を再登録します" && echo ""

names=$(jq -r '.mcpServers | keys[]' "$SOURCE")

if [[ -z "$names" ]]; then
  echo "適用対象なし: $SOURCE の mcpServers が空です"
  exit 0
fi

added=0
skipped=0

for name in $names; do
  config=$(jq -c --arg n "$name" '.mcpServers[$n]' "$SOURCE")

  if claude mcp get "$name" >/dev/null 2>&1; then
    if ! $FORCE; then
      echo "skip     $name (登録済み)"
      skipped=$((skipped + 1))
      continue
    fi
    if $DRY_RUN; then
      echo "re-add   $name (既存を削除して再登録)"
      added=$((added + 1))
      continue
    fi
    claude mcp remove --scope user "$name" >/dev/null
  elif $DRY_RUN; then
    echo "add      $name"
    added=$((added + 1))
    continue
  fi

  claude mcp add-json --scope user "$name" "$config" >/dev/null
  echo "add      $name"
  added=$((added + 1))
done

echo ""
echo "適用: $added 件 / skip: $skipped 件"

if ! $DRY_RUN && [[ $added -gt 0 ]]; then
  echo ""
  echo "OAuth が必要な MCP は Claude Code で /mcp を実行して認証してください。"
fi
