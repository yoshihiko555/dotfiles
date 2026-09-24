#!/usr/bin/env bash
# 個人用 MCP の一覧・差分・同期。Bash 3.2 / jq / taplo を使用する。
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
original_args=("$@")
definitions="$ROOT/shared/mcp"
claude_config="$HOME/.claude.json"
codex_config="$HOME/.codex/config.toml"
backup_root="$HOME/.local/state/dotfiles/mcp-backups"
taplo_bin="${TAPLO_BIN:-taplo}"
action="${1:-}"
[[ $# -eq 0 ]] || shift
selected=""
work=""
lock=""
staged=""

fail() {
  echo "エラー: $*" >&2
  exit 1
}
cleanup() {
  [[ -z "$staged" ]] || rm -f "$staged"
  [[ -z "$lock" ]] || rmdir "$lock"
  [[ -z "$work" ]] || rm -rf "$work"
}
trap cleanup EXIT
case "$action" in list | diff | sync) ;; *) fail "使い方: $0 {list|diff|sync} [サーバー名] [--definitions DIR] [--claude-config FILE] [--codex-config FILE] [--backup-dir DIR]" ;; esac
while [[ $# -gt 0 ]]; do
  case "$1" in
    --definitions | --claude-config | --codex-config | --backup-dir)
      [[ $# -ge 2 && -n "$2" ]] || fail "$1 の値が必要です"
      case "$1" in
        --definitions) definitions="$2" ;;
        --claude-config) claude_config="$2" ;;
        --codex-config) codex_config="$2" ;;
        --backup-dir) backup_root="$2" ;;
      esac
      shift 2
      ;;
    -*) fail "未対応のオプション: $1" ;;
    *)
      [[ -z "$selected" ]] || fail "サーバー名は1件のみ指定できます"
      selected="$1"
      shift
      ;;
  esac
done
command -v jq >/dev/null || fail "jq が必要です"
if ! command -v "$taplo_bin" >/dev/null; then
  if [[ -z "${TAPLO_BIN:-}" ]] && command -v nix >/dev/null; then
    exec nix shell --inputs-from "$ROOT/config/nix" nixpkgs#taplo --command bash "$0" "${original_args[@]}"
  fi
  fail "taplo が必要です。Nix 設定を適用するか TAPLO_BIN で実行ファイルを指定してください"
fi
work=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-mcp.XXXXXX")

# jq の診断に値が載ることがあるので、設定原文を出さずに停止する。
jq_error() { fail "JSON の構文・定義・参照が不正です（値は非表示）"; }
toml_json() {
  "$taplo_bin" get -f "$1" -o json >"$2" 2>"$work/error" || fail "TOML を解析できません: ${1}（値は非表示）"
}

jq -en --slurpfile clients "$definitions/clients.json" '
  $clients | length == 1 and (.[0] | type == "object" and keys == ["claude", "codex"] and all(.[]; type == "object"))
' >/dev/null 2>"$work/error" || jq_error
printf '{}\n' >"$work/servers.json"
for file in "$definitions"/servers/*.json; do
  [[ -f "$file" ]] || fail "サーバー定義がありません"
  name="$(basename "$file" .json)"
  [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]] || fail "サーバー名が不正です"
  jq --arg name "$name" --slurpfile server "$file" '
    if ($server|length) != 1 then error("定義は1件のみ") else . + {($name): $server[0]} end
  ' "$work/servers.json" >"$work/next.json" 2>"$work/error" || jq_error
  mv "$work/next.json" "$work/servers.json"
done
jq -en --slurpfile servers "$work/servers.json" --slurpfile clients "$definitions/clients.json" '
  def valid:
    type == "object" and
    (if .type == "http" then
       keys == ["type", "url"] and (.url | type == "string" and test("^https?://"))
     elif .type == "stdio" then
       (keys - ["type", "command", "args", "env"] | length == 0) and
       (.command | type == "string" and length > 0) and
       ((.args // []) | type == "array" and all(.[]; type == "string")) and
       ((.env // {}) | type == "object" and all(.[]; type == "string"))
     else false end);
  all($servers[0][]; valid) and
  all($clients[0][] | to_entries[];
    . as $entry | ($servers[0] | has($entry.key)) and
    (.value | type == "object" and (keys - ["args"] | length == 0)) and
    ($servers[0][$entry.key] + $entry.value | valid))
' >/dev/null 2>"$work/error" || jq_error
if [[ -n "$selected" ]]; then
  jq -e --arg name "$selected" 'any(.[]; has($name))' "$definitions/clients.json" >/dev/null 2>"$work/error" || jq_error
fi

# 同じ同期コマンドの並行実行を拒否する。アプリ自身の変更は書き込み直前にも比較する。
if [[ "$action" == sync ]]; then
  mkdir -p "$backup_root"
  if mkdir "$backup_root/.sync-lock" 2>/dev/null; then
    lock="$backup_root/.sync-lock"
  else
    fail "別の同期が実行中かロックが残っています: $backup_root/.sync-lock"
  fi
fi

for client in claude codex; do
  if [[ "$client" == claude ]]; then config="$claude_config"; else config="$codex_config"; fi
  # リンクそのものではなく実体を更新し、Nix のリンクを維持する。
  if [[ -e "$config" ]]; then
    target=$(realpath "$config")
    [[ -f "$target" ]] || fail "通常ファイルではありません: $config"
    cp -p "$target" "$work/$client.before"
    echo present >"$work/$client.state"
  else
    [[ ! -L "$config" ]] || fail "リンク先がありません: $config"
    target="$(cd "$(dirname "$config")" && pwd)/$(basename "$config")"
    if [[ "$client" == claude ]]; then printf '{}\n'; fi >"$work/$client.before"
    echo missing >"$work/$client.state"
  fi
  printf '%s\n' "$target" >"$work/$client.path"
  if [[ "$client" == claude ]]; then
    jq . "$work/$client.before" >"$work/$client.json" 2>"$work/error" || jq_error
    key=mcpServers
  else
    toml_json "$work/$client.before" "$work/$client.json"
    key=mcp_servers
  fi
  jq -e --arg key "$key" '
    type == "object" and ((.[$key] // {}) | type == "object" and all(.[]; type == "object"))
  ' "$work/$client.json" >/dev/null 2>"$work/error" || jq_error
  jq --arg client "$client" --arg selected "$selected" --slurpfile servers "$work/servers.json" '
    .[$client] | to_entries | map(select($selected == "" or .key == $selected) |
    .value = ($servers[0][.key] + .value | if $client == "codex" then del(.type) else . end)) | from_entries
  ' "$definitions/clients.json" >"$work/$client.desired" 2>"$work/error" || jq_error
  # 管理する接続定義だけを変更。認証・タイムアウト・ツール設定などは残す。
  jq --arg key "$key" --arg client "$client" --slurpfile desired "$work/$client.desired" '
    reduce ($desired[0] | to_entries[]) as $entry (. ;
      .[$key][$entry.key] = ((.[$key][$entry.key] // {}) as $old | $entry.value as $new |
        if (($old|has("command")) and ($new|has("url"))) or (($old|has("url")) and ($new|has("command")))
        then error("接続方式の変更は個別移行が必要") else
          $old + $new |
          if $new|has("command") then .args = ($new.args // []) | .env = (($old.env // {}) + ($new.env // {})) else . end |
          if $client == "codex" then .enabled = true else . end
        end))
  ' "$work/$client.json" >"$work/$client.expected" 2>"$work/error" || jq_error
  jq -n --arg key "$key" --arg client "$client" --slurpfile before "$work/$client.json" --slurpfile after "$work/$client.expected" --slurpfile desired "$work/$client.desired" '
    def norm:
      if has("command") then .args //= [] | .env //= {} | if $client == "claude" then .type //= "stdio" else . end else . end |
      if $client == "codex" and (has("enabled") | not) then .enabled = true else . end;
    [$desired[0] | keys[] as $name |
      ($before[0][$key][$name] // null) as $old | $after[0][$key][$name] as $new |
      {name:$name, status:(if $old == null then "追加候補" elif ($old|norm) == ($new|norm) then "一致" else "更新候補" end)}]
  ' >"$work/$client.rows" 2>"$work/error" || jq_error
  jq -r --arg client "$client" --arg action "$action" '.[] | select($action == "list" or .status != "一致") | [$client,.name,.status] | @tsv' "$work/$client.rows" 2>"$work/error" || jq_error
  jq -r '.[] | select(.status != "一致") | .name' "$work/$client.rows" >"$work/$client.changed" 2>"$work/error" || jq_error
  jq -r --arg client "$client" --arg key "$key" --slurpfile clients "$definitions/clients.json" '
    "対象外 " + $client + ": " + (((.[$key] // {} | keys) - ($clients[0][$client] | keys)) | join(", "))
  ' "$work/$client.json" 2>"$work/error" || jq_error
done

if [[ "$action" != sync ]]; then
  echo "読み取り専用です。プラグイン・対象外の MCP・認証・接続状態は検査しません。"
  exit 0
fi

# 反映前に両クライアントの出力を作成・検証する。
for client in claude codex; do
  [[ -s "$work/$client.changed" ]] || continue
  if [[ "$client" == claude ]]; then
    jq --slurpfile expected "$work/claude.expected" --rawfile changed "$work/claude.changed" '
      reduce ($changed | split("\n")[] | select(length > 0)) as $name (. ; .mcpServers[$name] = $expected[0].mcpServers[$name])
    ' "$work/claude.json" >"$work/claude.after" 2>"$work/error" || jq_error
  else
    cp "$work/codex.before" "$work/codex.after"
    while IFS= read -r name; do
      jq -r --arg name "$name" '
        def toml:
          if type == "object" then "{ " + ([to_entries[] | (.key|tojson) + " = " + (.value|toml)]|join(", ")) + " }"
          elif type == "array" then "[" + (map(toml)|join(", ")) + "]"
          elif . == null then error("null は TOML に変換できません") else tojson end;
        "[mcp_servers." + $name + "]", (.mcp_servers[$name] | to_entries[] | (.key|tojson) + " = " + (.value|toml))
      ' "$work/codex.expected" >"$work/section" 2>"$work/error" || jq_error
      # 通常のテーブル表記だけを編集。複雑な表記は後段の構文・全体比較で拒否する。
      awk -v name="$name" '
        /^[ \t]*\[/ {
          header=$0; sub(/[ \t]*#.*/, "", header); gsub(/[ \t\r]/, "", header)
          drop=(header == "[mcp_servers." name "]" || index(header, "[mcp_servers." name ".") == 1)
        }
        !drop || /^[ \t]*(#|$)/ { print }
      ' "$work/codex.after" >"$work/next.toml"
      printf '\n' >>"$work/next.toml"
      cat "$work/section" >>"$work/next.toml"
      mv "$work/next.toml" "$work/codex.after"
    done <"$work/codex.changed"
    toml_json "$work/codex.after" "$work/codex.actual"
    # 一致判定で既定値だけ省略したサーバーは、元の表記・値を保つ。
    jq --slurpfile expected "$work/codex.expected" --rawfile changed "$work/codex.changed" '
      reduce ($changed | split("\n")[] | select(length > 0)) as $name (. ; .mcp_servers[$name] = $expected[0].mcp_servers[$name])
    ' "$work/codex.json" >"$work/codex.verify" 2>"$work/error" || jq_error
    jq -en --slurpfile actual "$work/codex.actual" --slurpfile expected "$work/codex.verify" '$actual == $expected' >/dev/null 2>"$work/error" || jq_error
  fi
done

backup=""
for client in claude codex; do
  [[ -s "$work/$client.changed" ]] || continue
  target=$(cat "$work/$client.path")
  if [[ $(cat "$work/$client.state") == present ]]; then
    cmp -s "$target" "$work/$client.before" || fail "実設定が並行して変更されました。再実行してください: $client"
  else
    [[ ! -e "$target" && ! -L "$target" ]] || fail "設定が新しく作成されました。再実行してください: $client"
  fi
done
for client in claude codex; do
  [[ -s "$work/$client.changed" ]] || continue
  target=$(cat "$work/$client.path")
  if [[ -z "$backup" ]]; then
    backup=$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX")
  fi
  cp "$work/$client.before" "$backup/$client.before"
  cp "$work/$client.state" "$backup/$client.state"
  cp "$work/$client.path" "$backup/$client.path"
  staged=$(mktemp "$(dirname "$target")/.mcp-sync.XXXXXX")
  if [[ -e "$target" ]]; then cp -p "$target" "$staged"; fi
  cat "$work/$client.after" >"$staged"
  if [[ $(cat "$work/$client.state") == present ]]; then
    cmp -s "$target" "$work/$client.before" || fail "実設定が並行して変更されました: $client"
  else
    [[ ! -e "$target" && ! -L "$target" ]] || fail "設定が新しく作成されました: $client"
  fi
  mv -f "$staged" "$target"
  staged=""
  echo "反映済み: ${client}（バックアップ: ${backup}）"
done
[[ -n "$backup" ]] || echo "差分なし。変更しませんでした。"
