#!/bin/bash
# Claude Code のデバッグログをクリーンアップするスクリプト
# 対象: ~/.claude/debug/ (現在のセッション以外)
# 使い方: bash scripts/clean-claude.sh [--dry-run]
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
DEBUG_DIR="$CLAUDE_DIR/debug"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "[dry-run] 削除は実行しません"
  echo ""
fi

if [[ ! -d "$DEBUG_DIR" ]]; then
  echo "ディレクトリなし: $DEBUG_DIR"
  exit 0
fi

# latest シンボリックリンクが指す現在のセッションファイル名を取得
latest=""
if [[ -L "$DEBUG_DIR/latest" ]]; then
  latest=$(basename "$(readlink "$DEBUG_DIR/latest")")
fi

size=$(du -sh "$DEBUG_DIR" 2>/dev/null | cut -f1)
count=$(find "$DEBUG_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
delete_count=$(find "$DEBUG_DIR" -maxdepth 1 -type f -not -name "$latest" | wc -l | tr -d ' ')

echo "=== Claude Code デバッグログ クリーンアップ ==="
echo ""
echo "[debug] $size ($count 件中 $delete_count 件を削除、latest を保持)"

if [[ "$delete_count" -eq 0 ]]; then
  echo "  -> 削除対象なし"
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  find "$DEBUG_DIR" -maxdepth 1 -type f -not -name "$latest" -print | while read -r f; do
    echo "  [skip] $(basename "$f")"
  done
  echo ""
  echo "実行するには: bash scripts/clean-claude.sh"
else
  find "$DEBUG_DIR" -maxdepth 1 -type f -not -name "$latest" -delete
  echo "  -> 削除完了"
  echo ""
  echo "クリーンアップ後:"
  du -sh "$DEBUG_DIR" 2>/dev/null | awk '{print "  debug/: " $1}'
fi
