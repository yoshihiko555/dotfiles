#!/bin/bash

# Claude Codeのフック種別に応じて通知を分岐するスクリプト

EVENT="${1:-stop}"
# フックの JSON を stdin から受け取る
PAYLOAD="$(cat)"

# dotfiles の設置先は環境差分があるため $HOME ベースで解決
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
SHARED_NOTIFY="${DOTFILES_DIR}/shared/notify_message.sh"

# 失敗フラグを /tmp に保存（セッション単位）
STATE_DIR="/tmp"
SESSION_KEY=""
if command -v jq >/dev/null 2>&1; then
  SESSION_KEY="$(echo "$PAYLOAD" | jq -r '.transcript_path // .session_id // empty' 2>/dev/null)"
fi
if [ -z "$SESSION_KEY" ]; then
  SESSION_KEY="global"
fi
STATE_KEY="$(printf '%s' "$SESSION_KEY" | cksum | awk '{print $1}')"
STATE_FILE="${STATE_DIR}/claude_hook_state_${STATE_KEY}"

case "$EVENT" in
  # 失敗時はフラグを立てる
  failure|post_tool_use_failure)
    echo "1" >"$STATE_FILE"
    ;;
  # 権限待ちは即時通知（permission_prompt のみ対象）
  notification)
    NOTIFICATION_TYPE=""
    NOTIFICATION_MESSAGE=""
    if command -v jq >/dev/null 2>&1; then
      NOTIFICATION_TYPE="$(echo "$PAYLOAD" | jq -r '.notification_type // empty' 2>/dev/null)"
      NOTIFICATION_MESSAGE="$(echo "$PAYLOAD" | jq -r '.message // empty' 2>/dev/null)"
    fi
    if [ "$NOTIFICATION_TYPE" = "permission_prompt" ]; then
      if [ -n "$NOTIFICATION_MESSAGE" ] && [ "$NOTIFICATION_MESSAGE" != "null" ]; then
        "$SHARED_NOTIFY" "Claude" "Claude permission required" "$NOTIFICATION_MESSAGE" "Ping"
      else
        "$SHARED_NOTIFY" "Claude" "Claude permission required" "" "Ping"
      fi
    fi
    ;;
  # Stop 時に成功/失敗を確定して通知
  stop)
    if [ -f "$STATE_FILE" ]; then
      rm -f "$STATE_FILE"
      "$SHARED_NOTIFY" "Claude" "Claude task failed" "" "Basso"
      exit 0
    fi

    # 成功時のみ直近メッセージを付ける
    LAST_MESSAGE=""
    if command -v jq >/dev/null 2>&1; then
      LAST_MESSAGE="$(echo "$PAYLOAD" | jq -r '.["last-assistant-message"] // .last_assistant_message // empty' 2>/dev/null)"
      if [ -z "$LAST_MESSAGE" ] || [ "$LAST_MESSAGE" = "null" ]; then
        TRANSCRIPT_PATH="$(echo "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null)"
        if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
          LAST_MESSAGE="$(
            jq -r '
              def to_text:
                if type=="string" then .
                elif type=="array" then (map(.text // .content // .value // .message // empty) | join(""))
                elif type=="object" then (.text // .content // .value // .message // empty)
                else empty end;
              select(.role? == "assistant" or .type? == "assistant")
              | (.content // .message?.content // .message // .text // .output_text // empty)
              | to_text
            ' "$TRANSCRIPT_PATH" 2>/dev/null | tail -n 1
          )"
        fi
      fi
    fi

    if [ -n "$LAST_MESSAGE" ] && [ "$LAST_MESSAGE" != "null" ]; then
      "$SHARED_NOTIFY" "Claude" "Claude task completed" "$LAST_MESSAGE" "Glass"
    else
      "$SHARED_NOTIFY" "Claude" "Claude task completed" "" "Glass"
    fi
    ;;
esac
