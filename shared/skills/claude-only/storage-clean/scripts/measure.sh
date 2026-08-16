#!/usr/bin/env bash
# storage-clean: 読み取り専用の計測スクリプト。
# ディスク空き容量と、スキルが扱う各カテゴリのサイズを一覧表示する。
# 削除は一切行わない。before/after の比較や、gray 候補の当たりを付けるために使う。

set -uo pipefail

section() {
  printf '\n## %s\n' "$1"
}

size_of() {
  # 存在しないパスは静かに "-" を返す（du のエラーで出力が汚れるのを防ぐ）
  local path="$1"
  if [ -e "$path" ]; then
    du -sh "$path" 2>/dev/null | awk '{print $1}'
  else
    echo "-"
  fi
}

row() {
  # ラベルとサイズを整列して1行出力
  printf '%-45s %s\n' "$1" "$2"
}

echo "# storage-clean 計測レポート"
echo "実行日時: $(date '+%Y-%m-%d %H:%M:%S')"

section "ディスク全体"
# APFS コンテナ内の実データは /System/Volumes/Data 側に載る（/ はシステムの封印ボリューム）
df -h /System/Volumes/Data 2>/dev/null | tail -1 | awk '{printf "使用中: %s / 全体: %s / 空き: %s (使用率 %s)\n", $3, $2, $4, $5}'

section "safe カテゴリ（承認なしで prune 対象）"
row "~/.cache/uv (uv cache dir)"      "$(size_of "$HOME/.cache/uv")"
row "~/.npm"                          "$(size_of "$HOME/.npm")"
row "~/Library/pnpm (pnpm store)"     "$(size_of "$HOME/Library/pnpm")"
row "go build cache (GOCACHE, go clean -cache)"  "$(size_of "$(go env GOCACHE 2>/dev/null)")"
row "~/Library/Caches/Homebrew"       "$(size_of "$HOME/Library/Caches/Homebrew")"
row "~/.cache/pre-commit"             "$(size_of "$HOME/.cache/pre-commit")"

section "gray カテゴリ（毎回サイズを見せて承認を取る）"
row "OrbStack 実データ (Group Containers)" "$(size_of "$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack")"
row "~/.cache/huggingface"                  "$(size_of "$HOME/.cache/huggingface")"
row "~/.cargo/registry"                     "$(size_of "$HOME/.cargo/registry")"
row "go module cache (GOMODCACHE, go clean -modcache)" "$(size_of "$(go env GOMODCACHE 2>/dev/null)")"

echo
echo "### ghq 配下: 90日以上コミットのないリポジトリの node_modules / .venv"
if [ -d "$HOME/ghq" ]; then
  found_any=0
  while IFS= read -r dep_dir; do
    repo_root="$(git -C "$dep_dir/.." rev-parse --show-toplevel 2>/dev/null)"
    [ -z "$repo_root" ] && continue
    last_commit_epoch="$(git -C "$repo_root" log -1 --format=%ct 2>/dev/null)"
    [ -z "$last_commit_epoch" ] && continue
    now_epoch="$(date +%s)"
    age_days=$(( (now_epoch - last_commit_epoch) / 86400 ))
    if [ "$age_days" -ge 90 ]; then
      found_any=1
      size="$(size_of "$dep_dir")"
      row "  [${age_days}日前] $dep_dir" "$size"
    fi
  # .worktrees 配下は takt セクションで別途扱うのでここでは除外し、
  # node_modules / .venv はヒットしたら中を再帰しない（入れ子の二重列挙を防ぐ）
  done < <(find "$HOME/ghq" -maxdepth 6 -type d \( -name .worktrees -prune \) -o -type d \( -name node_modules -o -name .venv \) -prune -print 2>/dev/null)
  [ "$found_any" -eq 0 ] && echo "  該当なし"
else
  echo "  ~/ghq が存在しません"
fi

echo
echo "### takt の .worktrees（完了タスクの独立クローンが溜まっていないか）"
if [ -d "$HOME/ghq" ]; then
  found_any=0
  while IFS= read -r wt_dir; do
    found_any=1
    size="$(size_of "$wt_dir")"
    row "  $wt_dir" "$size"
  done < <(find "$HOME/ghq" -maxdepth 5 -type d -name ".worktrees" 2>/dev/null)
  [ "$found_any" -eq 0 ] && echo "  該当なし"
else
  echo "  ~/ghq が存在しません"
fi

section "スコープ外（レポートのみ、削除はこのスキルの対象外）"
row "~/.screenpipe" "$(size_of "$HOME/.screenpipe")"
row "~/.ollama"     "$(size_of "$HOME/.ollama")"

section "Nix 自動GC"
if [ -f "/Library/LaunchDaemons/org.nixos.nix-gc.plist" ]; then
  echo "org.nixos.nix-gc.plist は存在します（宣言的な nix.gc.automatic が有効）"
else
  echo "org.nixos.nix-gc.plist が見つかりません。macbook host に nix.gc.automatic が未適用の可能性があります"
fi
