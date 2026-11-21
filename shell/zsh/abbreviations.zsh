# 略語（zsh-abbr）。打った語が space / Enter で元のコマンドに展開され、履歴にも展開後の形で残る。
# config/sheldon/plugins.toml が zsh-abbr の後に遅延で読み込む。zshrc からは読まない。
# --session で宣言し、~/.config/zsh-abbr/user-abbreviations には書かせない（このファイルを正本にする）。
# aliases.zsh の同名の alias は残す。zsh-abbr を読み込む前の一瞬と、プラグインを外したときの退路になる。
# 2026-11-21 から 2 週間試す（digital-garden の terminal-life-toolkit の D-01）。

(($+functions[abbr])) || return 0

# git
abbr --session --quiet gs='git status'
abbr --session --quiet ga='git add'
abbr --session --quiet gc='git commit'
abbr --session --quiet gp='git push'
abbr --session --quiet gl='git log --oneline -10'
abbr --session --quiet gd='git diff'
abbr --session --quiet gb='git branch'
abbr --session --quiet gco='git checkout'
abbr --session --quiet gsw='git switch'

# docker
abbr --session --quiet dc='docker compose'
abbr --session --quiet dps='docker ps'
abbr --session --quiet dpsa='docker ps -a'
