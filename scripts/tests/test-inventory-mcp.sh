#!/usr/bin/env bash
# 棚卸しの MCP 集計部分だけを、一時的な定義と設定で検証する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-inventory-mcp.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/shared/mcp" "$work/codex"
cp -R "$ROOT/shared/mcp/servers" "$work/shared/mcp/servers"
cp "$ROOT/shared/mcp/clients.json" "$work/shared/mcp/clients.json"
printf '%s\n' '[mcp_servers.notion]' 'url = "https://example.test/mcp"' >"$work/codex/config.toml"
sed -n '/^# ---- A\. dotfiles: MCP /,/^log .*フェーズC/p' \
  "$ROOT/shared/skills/claude-only/ai-inventory/collect.sh" >"$work/block.sh"
[[ -s "$work/block.sh" ]]

# セッション履歴の走査と git の日時取得は集計の検証に不要なので置き換える。
log() { :; }
git_last_modified() { printf '2026-09-24\n'; }
get_mcp_usage() { printf 'null\n'; }
emit_asset() {
  jq -n --arg name "$2" --arg targets "$6" --arg path "$7" --arg notes "${11}" \
    '{name:$name, targets:($targets|split(",")), path:$path, notes:$notes}'
}
export -f log git_last_modified get_mcp_usage emit_asset
export DOTFILES_ROOT="$work"
export GREP=/usr/bin/grep
bash -u "$work/block.sh" | jq -s . >"$work/assets.json"
jq -e '
  length == 4 and
  all(.[] | select(.name != "notion"); .targets == ["Claude", "Codex"] and (.path | startswith("shared/mcp/servers/"))) and
  any(.[]; .name == "notion" and .targets == ["Codex"] and .path == "codex/config.toml")
' "$work/assets.json" >/dev/null
echo '成功: 共通3件の利用先・参照元・Codex 固有設定の保持'

# クライアントごとの割当と、未割当・参照切れを区別する。
jq 'del(.codex.figma, .claude.drawio, .codex.drawio) | .claude.missing = {}' \
  "$work/shared/mcp/clients.json" >"$work/clients.json"
mv "$work/clients.json" "$work/shared/mcp/clients.json"
bash -u "$work/block.sh" | jq -s . >"$work/assets.json"
jq -e '
  any(.[]; .name == "figma" and .targets == ["Claude"]) and
  any(.[]; .name == "drawio" and (.notes | startswith("未割当"))) and
  any(.[]; .name == "missing" and .targets == ["Claude"] and (.notes | startswith("参照切れ")))
' "$work/assets.json" >/dev/null
echo '成功: 個別割当・未割当・参照切れ'
