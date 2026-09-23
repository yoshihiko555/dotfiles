# herdr-automatic-rename の設定。
# ~/.config/herdr-automatic-rename/config.sh へ mkLink で配線する
# （プラグインは $HERDR_PLUGIN_CONFIG_DIR ではなくこの固定パスを読む。シェルフックが
#  herdr の外で動くため、両者が共有できる場所が必要という設計）。
#
# 導入の経緯:
#   タブ名の自動追従が herdr 本体に無いため、config/herdr/bin/herdr-rename-tab-auto を
#   prefix+y で手動実行していた。押す手間を無くすために本プラグインへ置き換えた。
#   herdr にはフォアグラウンドのプロセス変更を知らせるイベントが無く、nvim を起動した
#   瞬間に追従できるのは本プラグインの zsh フック (preexec/precmd) だけ。
#   スクリプト自体は退路として残してある（キー割り当てのみ外した）。

# エージェントタブはタスク名ではなくプログラム名 ("claude") で固定する。
# 既定 (1) はフォーカス中ペインのタスク名を出すが、1 タブに claude を 2〜8 本
# 並べる運用ではペイン間を移動するたびにタブ名が変わって鬱陶しい。
# ペイン数が増えて「どのタブで何をしているか」が分からなくなったら 1 を再検討する。
AGENT_TITLES=0

# ワークスペースには番号を付けない。
# 理由 1: config.toml の switch_workspace が未設定で、番号ジャンプを使っていない。
# 理由 2: herdr-agent-console の ws 列が "1:dotfiles" 形式で番号を自前で出しており、
#         "1:[1] dotfiles" と二重になる。Ghostty のウィンドウタイトル
#         ({hostname}: {workspace}) にも乗る。
# タブ側の番号 (AUTO_INDEX=1 の既定) は残す: switch_tab = "alt+1..9" に
# Ghostty が Cmd+1..9 を転送しており、タブバーに飛び先が出ていなかったため。
AUTO_INDEX_WORKSPACES=0

# 参考: AGENT_TRANSCRIPT（既定 1）は、エージェントが端末タイトルを付けていないときに
# Claude Code のセッション transcript をディスクから読んでタブ名に使う機能。
# AGENT_TITLES=0 ではタイトル経路自体に入らないため、この読み取りは発生しない。
