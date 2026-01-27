#!/bin/bash

# Claude Code完了時に通知を送信するスクリプト

# 引数からメッセージを取得（なければデフォルト）
MESSAGE="${1:-Claude task completed}"

# osascriptで通知表示
osascript -e "display notification \"$MESSAGE\" with title \"Claude\""

# 通知音を再生
afplay /System/Library/Sounds/Glass.aiff &
