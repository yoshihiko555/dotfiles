#!/usr/bin/env bash
# 実設定には触れず、prune の候補判定と削除範囲を確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-trust-prune.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir "$work/exists"
ln -s "$work/absent-target" "$work/broken-link"
printf '%s\n' '# 保持するコメント' 'model = "unchanged"' \
  "[projects.\"$work/exists\"]" 'trust_level = "trusted"' 'extra = "keep"' \
  "[projects.\"$work/missing\"]" 'trust_level = "trusted"' \
  "[projects.\"$work/missing\".options]" 'extra = "remove"' \
  "[projects.\"$work/missing-untrusted\"]" 'trust_level = "untrusted"' \
  "[projects.\"$work/broken-link\"]" 'trust_level = "trusted"' \
  '[mcp_servers.example]' 'url = "https://example.test/mcp"' >"$work/config.toml"
ln -s "$work/config.toml" "$work/link.toml"
export CODEX_CONFIG_PATH="$work/link.toml"
export TRUST_BACKUP_DIR="$work/backups"
export DOTFILES="$ROOT"
cp "$work/config.toml" "$work/before"
zsh -f -c 'source "$DOTFILES/shell/zsh/trust.zsh"; trust prune' >"$work/output"
cmp "$work/config.toml" "$work/before"
grep -q '2 件' "$work/output"
zsh -f -c 'source "$DOTFILES/shell/zsh/trust.zsh"; trust prune --apply' >"$work/output"
[[ -L "$work/link.toml" ]]
"${TAPLO_BIN:-taplo}" get -f "$work/config.toml" -o json | jq -e --arg root "$work" '
  .model == "unchanged" and .mcp_servers.example.url == "https://example.test/mcp" and
  (.projects | keys | length == 2) and .projects[$root + "/exists"].extra == "keep" and
  .projects[$root + "/broken-link"].trust_level == "trusted"
' >/dev/null
for backup in "$work"/backups/*.before; do cmp "$backup" "$work/before"; done
cp "$work/config.toml" "$work/after"
bash "$ROOT/scripts/codex-trust-manage.sh" prune --apply >"$work/output"
cmp "$work/config.toml" "$work/after"
echo '成功: 関数からの呼び出し・候補表示・missing のみ削除・設定/リンク保持・バックアップ・冪等性'

printf '%s\n' 'broken = [' >"$work/config.toml"
cp "$work/config.toml" "$work/invalid"
if bash "$ROOT/scripts/codex-trust-manage.sh" prune --apply >"$work/output" 2>&1; then exit 1; fi
cmp "$work/config.toml" "$work/invalid"
echo '成功: 不正な TOML は変更せず停止'
