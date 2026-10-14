# terminal-browser（Chromium を Kitty graphics でペインに描くブラウザ）の起動ショートカット。
#
#   tb              → localhost:3000 を右に分割して開く
#   tb 5173         → 数字だけなら localhost:<port>
#   tb example.com  → URL / ホスト名はそのまま
#   tb ... down     → 2 引数目で分割方向（right / down / left / up）

export TERMINAL_BROWSER_NO_TELEMETRY=1

tb() {
  local target="${1:-localhost:3000}"
  local dir="${2:-right}"
  [[ "$target" == <-> ]] && target="localhost:$target"
  terminal-browser open "$target" --split "$dir"
}
