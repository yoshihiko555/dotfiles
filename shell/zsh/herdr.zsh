# herdr-automatic-rename のシェルフック。
#
# herdr には「ペインのフォアグラウンドプロセスが変わった」イベントが無い。
# プラグインのイベント購読 (tab.created / pane.agent_detected 等) だけでは
# nvim を起動してもタブ名が追従しないため、preexec/precmd から直接叩く。
# これが手動の prefix+y を置き換えている本体。
#
# プラグインは content-hash 付きのディレクトリへ入るのでパスは決め打ちできない。
# glob + (N) で、未インストール時は何もせず素通りする。
for _f in ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source $_f
  break
done
unset _f
