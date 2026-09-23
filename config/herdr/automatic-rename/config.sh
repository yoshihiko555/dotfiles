# herdr-automatic-rename の設定。プラグインは固定パス ~/.config/herdr-automatic-rename/config.sh を読む
# （シェルフックが herdr の外で動くため）。配線は dotfiles.nix の mkLink。

# エージェントタブはタスク名ではなくプログラム名（claude）で固定する。
# 1 タブに claude を複数並べると、ペインを移るたびにタブ名が変わって煩わしいため。
AGENT_TITLES=0

# ワークスペースには番号を付けない（番号切替を使っておらず、herdr-agent-console の
# ws 列やウィンドウタイトルと番号が二重になる）。タブの番号は Cmd+1..9 の飛び先として残す。
AUTO_INDEX_WORKSPACES=0
