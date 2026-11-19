#!/bin/bash
# gh skill で shared/skills/common に入れた外部スキルを最新のリリースへ更新するスクリプト
# 対象: SKILL.md の frontmatter に github-repo を持つスキル（自作スキルは対象外）
# 更新後はコミットせず、変わったファイルを表示して止まる（差分を読んでからコミットする）
# 使い方: bash scripts/skill-update.sh [--dry-run] [スキル名...]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_REL="shared/skills/common"
SKILLS_DIR="$ROOT_DIR/$SKILLS_REL"
DRY_RUN=false
NAMES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    -*)
      echo "不明な引数: $1" >&2
      exit 2
      ;;
    *) NAMES+=("$1") ;;
  esac
  shift
done

# 名前の指定がなければ gh skill で入れたスキルをすべて対象にする。
# 自作スキルを渡すと gh skill が警告を出すので、github-repo を持つものだけに絞る
if [[ ${#NAMES[@]} -eq 0 ]]; then
  for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
    if grep -q '^ *github-repo:' "$skill_md"; then
      NAMES+=("$(basename "$(dirname "$skill_md")")")
    fi
  done
fi

if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "gh skill で入れたスキルはありません: $SKILLS_REL"
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  gh skill update --dir "$SKILLS_DIR" --dry-run "${NAMES[@]}"
  exit 0
fi

# 非対話では確認を挟めないので --all で適用する（対象は NAMES に限られる）
gh skill update --dir "$SKILLS_DIR" --all "${NAMES[@]}"

echo ""
echo "変更されたファイル（コミットはしていません）:"
git -C "$ROOT_DIR" status --short -- "$SKILLS_REL"
