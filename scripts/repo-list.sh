#!/usr/bin/env bash
# repo-list.sh — ghq リポジトリ + .worktrees 配下の一覧を出力
# 出力形式（TSV）: TYPE\tLABEL\tPATH
#   TYPE  : repo | worktree
#   LABEL : 表示用ラベル（例: yoshihiko555/dotfiles）
#   PATH  : 絶対パス
#
# WezTerm InputSelector と shell repo() の両方から利用する共有スクリプト

set -euo pipefail

if ! command -v ghq &>/dev/null; then
  echo "ghq が見つかりません" >&2
  exit 1
fi

ghq_root="$(ghq root)"

# ghq リポジトリ
ghq list | while IFS= read -r line; do
  printf 'repo\t%s\t%s/%s\n' "$line" "$ghq_root" "$line"
done

# .worktrees 配下
find "$ghq_root" -maxdepth 5 -type d -name ".worktrees" 2>/dev/null | while IFS= read -r wt_dir; do
  repo_rel="${wt_dir#"$ghq_root"/}"
  repo_rel="${repo_rel%/.worktrees}"
  for d in "$wt_dir"/*/; do
    [ -d "$d" ] || continue
    wt_name="$(basename "$d")"
    printf 'worktree\t%s:%s\t%s\n' "$repo_rel" "$wt_name" "${d%/}"
  done
done
