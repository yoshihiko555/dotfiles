#!/bin/bash
# GUI ログイン時の macOS SSH agent と既存 Keychain だけを使う。
set -euo pipefail
umask 077

log_path="$HOME/Library/Logs/hermes-dashboard-tunnel.log"
mkdir -p "${log_path%/*}"
# 再接続ごとに入れ替え、直近 2 回分だけを残す。
if [[ -f "$log_path" ]]; then
  mv -f "$log_path" "$log_path.previous"
fi
exec >"$log_path" 2>&1
printf '%s 接続を開始\n' "$(/bin/date '+%Y-%m-%d %H:%M:%S')"

if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "$SSH_AUTH_SOCK" ]]; then
  echo 'GUI ログイン環境の SSH agent が利用できません。'
  exit 1
fi
export SSH_ASKPASS_REQUIRE=never

# 1Password の agent 設定には依存せず、macOS の agent を明示する。
if ! /usr/bin/ssh-add -T "$HOME/.ssh/id_ed25519_macmini.pub" >/dev/null 2>&1; then
  /usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1 || true
  if ! /usr/bin/ssh-add -T "$HOME/.ssh/id_ed25519_macmini.pub" >/dev/null 2>&1; then
    echo 'Mac mini 用の鍵を読み込めません。ログイン Keychain の状態を確認してください。'
    exit 1
  fi
fi

# -f は使わず、接続の寿命を launchd に監視させる。
# -q は backend 停止中の転送失敗メッセージの連続出力を抑える。
exec /usr/bin/ssh -N -T -q \
  -o IdentityAgent=SSH_AUTH_SOCK \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=yes \
  -o ExitOnForwardFailure=yes \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ControlMaster=no \
  -o ControlPath=none \
  -L 127.0.0.1:13000:127.0.0.1:9119 \
  macmini-agent
