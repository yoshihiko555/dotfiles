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

# plist が指している実行ファイルのパス（node のバージョン付き絶対パスが焼かれている）
_sp_program() {
  /usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$SP_PLIST" 2>/dev/null
}

# plist の実行ファイルが消えていないか。
# screenpipe は mise の node の npm グローバルとして入っており、npm パッケージは
# node のバージョンごとに独立しているため、node の更新や `mise prune` で実体が消える。
_sp_program_ok() {
  local prog
  prog="$(_sp_program)"
  [[ -n "$prog" && -x "$prog" ]]
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
  # 実体が消えたまま bootstrap すると KeepAlive で起動失敗を繰り返すため事前に弾く
  if ! _sp_program_ok; then
    echo "spon: plist の実行ファイルが消えている (spfix で復旧)" >&2
    echo "  $(_sp_program)" >&2
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
  if ! _sp_program_ok; then
    echo "  警告: plist の実行ファイルが消えている (spfix で復旧)" >&2
    echo "  $(_sp_program)" >&2
  fi
}

# node の更新等で消えた実体を入れ直し、plist のパスを貼り直す。
# 引数でバージョンを固定できる (例: spfix 0.4.26)。省略時は npm の最新版が入る。
spfix() {
  local pkg="screenpipe${1:+@$1}"
  if [[ ! -f "$SP_PLIST" ]]; then
    echo "spfix: $SP_PLIST が見つからない (screenpipe service install が必要)" >&2
    return 1
  fi

  local old_prog old_ver
  old_prog="$(_sp_program)"
  [[ -x "$old_prog" ]] && old_ver="$("$old_prog" -V 2>/dev/null)"

  echo "spfix: $pkg を入れ直す"
  npm i -g "$pkg" || return 1

  # mise のレイアウトを直書きせず、現在の node の npm グローバル root から解決する
  local root new_prog
  root="$(npm root -g)" || return 1
  new_prog="$root/screenpipe/node_modules/@screenpipe/cli-darwin-arm64/bin/screenpipe"
  if [[ ! -x "$new_prog" ]]; then
    echo "spfix: $new_prog が実行できない (npm パッケージの構成が変わった?)" >&2
    return 1
  fi

  # `screenpipe service install` は plist を再生成できるが、既定の --record-args が
  # `--disable-vision --disable-audio` (記録なし) のため、--ignored-windows や
  # --retention-days といった既存の記録設定を失う。実行ファイルのパスだけ差し替える。
  cp "$SP_PLIST" "$SP_PLIST.bak" || return 1
  /usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $new_prog" "$SP_PLIST" || return 1

  echo "spfix: ${old_ver:-なし} -> $("$new_prog" -V 2>/dev/null) (旧 plist は $SP_PLIST.bak)"
  spoff >/dev/null || return 1
  spon
}
