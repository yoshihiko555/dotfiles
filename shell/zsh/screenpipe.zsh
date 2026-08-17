# ============================================
# screenpipe の一時停止 / 再開
# ============================================

# screenpipe は launchd の user agent (KeepAlive=true) として常駐しているため、
# プロセスを kill しても即座に再起動される。一時停止は agent 自体を
# bootout してロードから外す形で行う。
# plist は screenpipe 側 (`screenpipe service install`) が生成するもので、
# dotfiles / nix の管理対象外。
SP_LABEL="com.screenpipe.agent"
SP_PLIST="$HOME/Library/LaunchAgents/$SP_LABEL.plist"

# agent がロード済みかどうか
_sp_loaded() {
  launchctl print "gui/$(id -u)/$SP_LABEL" >/dev/null 2>&1
}

# 一時停止する。
# plist の RunAtLoad により次回ログイン時には再び起動するため、
# 恒久的に止めたい場合は `screenpipe service uninstall` を使う。
spoff() {
  if ! _sp_loaded; then
    echo "screenpipe: すでに停止中"
    return 0
  fi
  launchctl bootout "gui/$(id -u)/$SP_LABEL" || return 1
  # bootout は SIGTERM 送信後、プロセス終了を待たずに戻ることがある。
  # 停止直後に spon を叩くと「すでに稼働中」と誤判定するためアンロードを待つ。
  local i
  for i in $(seq 1 50); do
    _sp_loaded || break
    sleep 0.2
  done
  if _sp_loaded; then
    echo "spoff: 停止要求は送ったがまだ終了していない (sps で確認)" >&2
    return 1
  fi
  echo "screenpipe: 停止した (spon で再開)"
}

# 停止中の agent を再開する
spon() {
  if _sp_loaded; then
    echo "screenpipe: すでに稼働中"
    return 0
  fi
  if [[ ! -f "$SP_PLIST" ]]; then
    echo "spon: $SP_PLIST が見つからない (screenpipe service install が必要)" >&2
    return 1
  fi
  launchctl bootstrap "gui/$(id -u)" "$SP_PLIST" || return 1
  echo "screenpipe: 再開した"
}

# 稼働状態を表示する
sps() {
  if _sp_loaded; then
    local pid
    pid="$(launchctl print "gui/$(id -u)/$SP_LABEL" 2>/dev/null | awk '$1 == "pid" { print $3 }')"
    echo "screenpipe: 稼働中 (pid ${pid:-?})"
  else
    echo "screenpipe: 停止中"
  fi
}
