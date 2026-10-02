#!/bin/bash
# Codex の image_gen が自動保存する画像のうち、古いものをゴミ箱へ送るスクリプト
# 対象: ~/.codex/generated_images/<thread-id>/*（最終更新から N 日を過ぎたファイル）
# 採用した画像は各プロジェクト側に保存されている前提で、ここは受信箱として扱う
# 使い方: bash scripts/clean-codex-images.sh [--dry-run] [--days N]
set -euo pipefail

IMAGES_DIR="$HOME/.codex/generated_images"
DAYS=30
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --days)
      DAYS="${2:-}"
      shift
      ;;
    *)
      echo "不明な引数: $1" >&2
      exit 2
      ;;
  esac
  shift
done

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "--days には 0 以上の整数を指定してください: $DAYS" >&2
  exit 2
fi

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] 移動は実行しません"
  echo ""
fi

if [[ ! -d "$IMAGES_DIR" ]]; then
  echo "ディレクトリなし: $IMAGES_DIR"
  exit 0
fi

# 削除ではなくゴミ箱送りにして、誤って消しても Finder から戻せるようにする
if [[ ! -x /usr/bin/trash ]]; then
  echo "/usr/bin/trash が見つかりません（macOS 15 以降が必要）" >&2
  exit 1
fi

targets=()
while IFS= read -r -d '' f; do
  targets+=("$f")
done < <(find "$IMAGES_DIR" -mindepth 2 -type f -mtime "+$DAYS" -print0)

size=$(du -sh "$IMAGES_DIR" 2>/dev/null | cut -f1)
count=$(find "$IMAGES_DIR" -mindepth 2 -type f | wc -l | tr -d ' ')

echo "=== Codex 生成画像 クリーンアップ ==="
echo ""
echo "[generated_images] $size ($count 件中 ${#targets[@]} 件が ${DAYS} 日超)"

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "  -> 対象なし"
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  for f in "${targets[@]}"; do
    echo "  [skip] ${f#"$IMAGES_DIR"/}"
  done
  echo ""
  echo "実行するには: bash scripts/clean-codex-images.sh"
  exit 0
fi

/usr/bin/trash "${targets[@]}"
# 中身がなくなったスレッドのディレクトリを片付ける（.DS_Store だけ残ったものも含む）
find "$IMAGES_DIR" -mindepth 2 -maxdepth 2 -name .DS_Store -delete
find "$IMAGES_DIR" -mindepth 1 -type d -empty -delete
echo "  -> ${#targets[@]} 件をゴミ箱へ移動"
echo ""
echo "クリーンアップ後:"
du -sh "$IMAGES_DIR" 2>/dev/null | awk '{print "  generated_images/: " $1}'
