#!/bin/bash

# エージェント共通の通知スクリプト
# 使い方: notify_message.sh <Agent> <FixedMessage> [Payload] [Sound]
# - Payload: JSON( last-assistant-message ) またはそのままの文字列
# - Sound: 標準音名（例: Glass）または絶対パス
AGENT="${1:-Agent}"
FIXED_MESSAGE="${2:-${AGENT} task completed}"
PAYLOAD="${3:-}"
SOUND_ARG="${4:-Glass}"

LAST_MESSAGE=""
if [ -n "$PAYLOAD" ]; then
  if command -v jq >/dev/null 2>&1 && [[ "$PAYLOAD" == "{"* ]]; then
    LAST_MESSAGE=$(echo "$PAYLOAD" | jq -r '.["last-assistant-message"] // empty' 2>/dev/null)
  else
    LAST_MESSAGE="$PAYLOAD"
  fi
fi

# 直近メッセージが取れれば固定文の下に追加
if [ -n "$LAST_MESSAGE" ] && [ "$LAST_MESSAGE" != "null" ]; then
  MESSAGE="${FIXED_MESSAGE}"$'\n'"${LAST_MESSAGE}"
else
  MESSAGE="${FIXED_MESSAGE}"
fi

# osascript は argv 経由で渡してエスケープを回避
osascript - "$MESSAGE" "$AGENT" <<'APPLESCRIPT'
on run argv
  display notification (item 1 of argv) with title (item 2 of argv)
end run
APPLESCRIPT

SOUND_FILE=""
if [ -n "$SOUND_ARG" ]; then
  if [[ "$SOUND_ARG" = /* ]]; then
    SOUND_FILE="$SOUND_ARG"
  else
    SOUND_FILE="/System/Library/Sounds/${SOUND_ARG}.aiff"
  fi
fi

# 標準音 or 任意ファイルを再生（見つからなければ Glass にフォールバック）
if [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ]; then
  afplay "$SOUND_FILE" &
else
  afplay /System/Library/Sounds/Glass.aiff &
fi
