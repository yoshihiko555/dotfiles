#!/usr/bin/env bash
# 役割:
# - Codex trust 設定の監査（一覧・不整合検知・件数集計）
# - projects.*.trust_level を読み取り、missing / temp-like を判定
# - trust 関数の `trust audit` から呼び出す想定
# 対象設定ファイル:
# - CODEX_CONFIG_PATH があればそれを使用
# - 未指定時は ~/.codex/config.toml
set -euo pipefail

CONFIG_PATH="${CODEX_CONFIG_PATH:-$HOME/.codex/config.toml}"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "config が見つかりません: $CONFIG_PATH"
  exit 1
fi

tmp_entries="$(mktemp)"
trap 'rm -f "$tmp_entries"' EXIT

# projects."<absolute_path>" と trust_level を抽出
awk '
  /^\[projects\."/ {
    path = $0
    sub(/^\[projects\."/, "", path)
    sub(/"\]$/, "", path)
    current = path
    next
  }
  current != "" && /^trust_level[[:space:]]*=/ {
    level = $0
    sub(/^[^=]*=[[:space:]]*/, "", level)
    gsub(/"/, "", level)
    print current "\t" level
    current = ""
  }
' "$CONFIG_PATH" > "$tmp_entries"

total=0
missing=0
temp_like=0
trusted=0
untrusted=0

echo "=== Codex trust audit ==="
echo "config: $CONFIG_PATH"
echo ""

if [[ ! -s "$tmp_entries" ]]; then
  echo "projects.*.trust_level は未設定です。"
  exit 0
fi

printf "%-10s %-8s %s\n" "status" "level" "path"
printf "%-10s %-8s %s\n" "----------" "--------" "------------------------------"

while IFS=$'\t' read -r path level; do
  total=$((total + 1))

  if [[ "$level" == "trusted" ]]; then
    trusted=$((trusted + 1))
  elif [[ "$level" == "untrusted" ]]; then
    untrusted=$((untrusted + 1))
  fi

  status="ok"
  if [[ ! -e "$path" ]]; then
    status="missing"
    missing=$((missing + 1))
  elif [[ "$path" =~ ^/tmp/ || "$path" =~ ^/private/tmp/ || "$path" =~ ^/var/folders/ || "$path" =~ /Downloads/ ]]; then
    status="temp-like"
    temp_like=$((temp_like + 1))
  fi

  printf "%-10s %-8s %s\n" "$status" "$level" "$path"
done < "$tmp_entries"

echo ""
echo "summary:"
echo "  total     : $total"
echo "  trusted   : $trusted"
echo "  untrusted : $untrusted"
echo "  missing   : $missing"
echo "  temp-like : $temp_like"

echo ""
echo "hint:"
echo "  - missing / temp-like の trusted は untrusted へ戻す運用を推奨"
echo "  - 変更例: [projects.\"/path\"] の trust_level = \"untrusted\""
