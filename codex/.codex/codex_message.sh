#!/bin/bash

# Codex 完了時に通知を送信するスクリプト（共通スクリプト呼び出し）
# notify から渡される payload を共通通知へ渡す

# dotfiles の設置先は環境差分があるため $HOME ベースで解決
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/ghq/github.com/yoshihiko555/dotfiles}"
SHARED_NOTIFY="${DOTFILES_DIR}/shared/notify_message.sh"

"$SHARED_NOTIFY" "Codex" "Codex task completed" "$1"
