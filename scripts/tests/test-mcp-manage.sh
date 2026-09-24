#!/usr/bin/env bash
# 一時設定だけを使い、同期の保持・拒否・冪等性を確認する。
set -euo pipefail
umask 077
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
if ! command -v "${TAPLO_BIN:-taplo}" >/dev/null; then
  if [[ -z "${TAPLO_BIN:-}" ]] && command -v nix >/dev/null; then
    exec nix shell --inputs-from "$ROOT/config/nix" nixpkgs#taplo --command bash "$0" "$@"
  fi
  echo "taplo が必要です。TAPLO_BIN で実行ファイルを指定してください。" >&2
  exit 1
fi
work=$(mktemp -d "${TMPDIR:-/tmp}/test-mcp.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir "$work/defs" "$work/defs/servers"
cp "$ROOT/shared/mcp/servers/figma.json" "$work/defs/servers/figma.json"
printf '%s\n' '{"claude":{"figma":{}},"codex":{"figma":{}}}' >"$work/defs/clients.json"
printf '%s\n' '{"history":{"keep":1},"mcpServers":{"other":{"command":"keep"}}}' >"$work/claude.json"
printf '%s\n' '# 保持するコメント' 'model = "keep"' '[mcp_servers.other]' 'command = "keep"' >"$work/config.toml"
ln -s "$work/config.toml" "$work/link.toml"
run() {
  bash "$ROOT/scripts/mcp-manage.sh" "$@" --definitions "$work/defs" --claude-config "$work/claude.json" --codex-config "$work/link.toml" --backup-dir "$work/backups"
}
cp "$work/claude.json" "$work/claude.original"
cp "$work/config.toml" "$work/codex.original"
run diff >"$work/output"
cmp "$work/claude.json" "$work/claude.original"
cmp "$work/config.toml" "$work/codex.original"
run sync >"$work/output"
[[ -L "$work/link.toml" ]]
jq -e '.history.keep == 1 and .mcpServers.other.command == "keep" and .mcpServers.figma.url == "https://mcp.figma.com/mcp"' "$work/claude.json" >/dev/null
head -n 4 "$work/config.toml" >"$work/preserved"
cmp "$work/preserved" "$work/codex.original"
cp "$work/claude.json" "$work/claude.synced"
cp "$work/config.toml" "$work/codex.synced"
run sync >"$work/output"
cmp "$work/claude.json" "$work/claude.synced"
cmp "$work/config.toml" "$work/codex.synced"
echo '成功: 読み取り専用・追加・対象外保持・symlink 保持・冪等性'
printf '%s\n' '[mcp_servers.figma]' 'url = "https://old.example/mcp"' 'enabled = false' 'tool_timeout_sec = 99' '[mcp_servers.figma.http_headers]' 'Authorization = "TEST_SECRET"' >"$work/config.toml"
run sync >"$work/output"
"${TAPLO_BIN:-taplo}" get -f "$work/config.toml" -o json | jq -e '.mcp_servers.figma | .url == "https://mcp.figma.com/mcp" and .enabled == true and .tool_timeout_sec == 99 and .http_headers.Authorization == "TEST_SECRET"' >/dev/null
if grep -q TEST_SECRET "$work/output"; then exit 1; fi
echo '成功: 更新・有効化・認証設定保持・秘匿値非表示'
printf '%s\n' '{"mcpServers":{}}' >"$work/claude.json"
cp "$work/claude.json" "$work/before-error"
printf '%s\n' 'invalid = [' >"$work/config.toml"
if run sync >"$work/output" 2>&1; then exit 1; fi
cmp "$work/claude.json" "$work/before-error"
echo '成功: 全出力の検証が終わるまで実設定を保持'
printf '%s\n' '[mcp_servers."figma"]' 'url = "https://old.example/mcp"' >"$work/config.toml"
cp "$work/config.toml" "$work/quoted"
if run sync >"$work/output" 2>&1; then exit 1; fi
cmp "$work/config.toml" "$work/quoted"
cmp "$work/claude.json" "$work/before-error"
echo '成功: 未対応表記は実設定を変更せず拒否'
if run sync unknown >"$work/output" 2>&1; then exit 1; fi
echo '成功: 未登録のサーバー名を拒否'

# ファイル未作成時の追加と1件指定。他の定義は反映しない。
cp "$ROOT/shared/mcp/servers/drawio.json" "$work/defs/servers/drawio.json"
printf '%s\n' '{"claude":{"figma":{},"drawio":{}},"codex":{"figma":{},"drawio":{}}}' >"$work/defs/clients.json"
bash "$ROOT/scripts/mcp-manage.sh" sync drawio --definitions "$work/defs" --claude-config "$work/new.json" --codex-config "$work/new.toml" --backup-dir "$work/new-backups" >"$work/output"
jq -e '.mcpServers | keys == ["drawio"]' "$work/new.json" >/dev/null
"${TAPLO_BIN:-taplo}" get -f "$work/new.toml" -o json | jq -e '.mcp_servers | keys == ["drawio"]' >/dev/null
echo '成功: ファイル未作成時の追加・1件指定・stdio の生成'
