#!/bin/bash
# Claude Code の CLAUDE_CODE_SHELL_PREFIX 用ラッパー
# Bash ツール・hook・MCP サーバーのコマンドを nice 付きで実行し、エージェントが走らせる
# ビルドやテストより対話操作（ターミナル入力など）を優先させる。Claude の TUI 自体は対象外
# Claude Code は実行するコマンド全体を 1 つの文字列として $1 に渡してくる
set -euo pipefail

NICE_LEVEL="${CLAUDE_SHELL_NICE:-10}"

# サンドボックス内では setpriority が拒否されるため、失敗したら通常の優先度のまま実行する
# （nice コマンドは失敗時に警告を出力へ混ぜるので使わない）
/usr/bin/renice "$NICE_LEVEL" -p $$ >/dev/null 2>&1 || true

# Bash ツールのコマンドは Claude が使う bash で採取した snapshot を source する。
# login シェルの PATH では /bin/bash (3.2) に解決されることがあるため明示的に選ぶ
for shell in /run/current-system/sw/bin/bash /opt/homebrew/bin/bash /bin/bash; do
  if [[ -x "$shell" ]]; then
    exec "$shell" -c "$1"
  fi
done

echo "claude-shell-prefix: bash が見つからない" >&2
exit 127
