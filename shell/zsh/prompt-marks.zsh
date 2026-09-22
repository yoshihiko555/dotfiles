# OSC 133（semantic prompt マーク）を zsh から出す。
#
# herdr のペインが使う端末エンジン（libghostty）は、Ctrl+L の `ESC[2J` を受けたとき
# 「最後の行がプロンプト」と分かる場合だけ画面の中身をスクロールバックへ押し込んでから
# 消す（何も失われない）。プロンプトだと分からなければその場で消し、直前の 1 画面分が
# 失われる。starship は OSC 133 を出さないため後者になっていた（2026-09-23 実測:
# `seq 1 200` → Ctrl+L で 140 まで残り、見えていた分だけ消えた）。
#
# マークの意味: A = プロンプト開始 / B = 入力開始 / C = コマンド出力開始 / D = コマンド終了
# 対応していない端末は無視するので副作用は無い。herdr の「プロンプトに戻ったか」判定や
# jump_to_prompt 系もこのマークを使う。
#
# starship は precmd で PROMPT を毎回組み立て直すので、B は自分の precmd（starship より
# 後に登録される）で PROMPT の末尾に足す。
autoload -Uz add-zsh-hook

_prompt_marks_precmd() {
  local status_code=$?
  printf '\e]133;D;%s\a' "$status_code"
  printf '\e]133;A\a'
  # starship が無い環境では PROMPT が組み立て直されず溜まっていくので、二重追加を防ぐ
  [[ "$PROMPT" != *$'\e]133;B\a'* ]] && PROMPT="${PROMPT}%{"$'\e]133;B\a'"%}"
}
_prompt_marks_preexec() {
  printf '\e]133;C\a'
}
add-zsh-hook precmd _prompt_marks_precmd
add-zsh-hook preexec _prompt_marks_preexec
