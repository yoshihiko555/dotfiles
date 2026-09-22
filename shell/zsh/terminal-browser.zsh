# terminal-browser（Chromium を Kitty graphics でペインに描くブラウザ）の起動ショートカット。
# 実用条件は「外側の端末が Ghostty」かつ「herdr クライアントが 1 つ」
# （docs/adr/ADR-20260922-0001）。WezTerm や Moshi 2 台目の状態で開くとフォールバックに
# 落ちて重くなる。
#
#   tb              → localhost:3000 を右に分割して開く
#   tb 5173         → 数字だけなら localhost:<port>
#   tb example.com  → URL / ホスト名はそのまま
#   tb ... down     → 2 引数目で分割方向（right / down / left / up）
tb() {
  local target="${1:-localhost:3000}"
  local dir="${2:-right}"
  [[ "$target" == <-> ]] && target="localhost:$target"
  terminal-browser open "$target" --split "$dir"
}
