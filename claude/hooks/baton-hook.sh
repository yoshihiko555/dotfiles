#!/bin/sh
# baton（AI セッション監視）へ Claude Code hook イベントを転送する。
# baton 未インストール / 常駐未起動 / tmux 外ではすべて exit 0（Claude Code をブロックしない）。
PATH="$HOME/.local/bin:$PATH"
command -v baton >/dev/null 2>&1 || exit 0
exec baton hook
