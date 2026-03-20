# ============================================
# Zsh Configuration
# ============================================

# --------------------------------------------
# 1. Zsh Options
# --------------------------------------------
setopt AUTO_CD              # ディレクトリ名だけでcd
setopt AUTO_PUSHD           # cd時に自動でpushd
setopt PUSHD_IGNORE_DUPS    # pushdで重複を無視
setopt CORRECT              # コマンドのスペルミス訂正
setopt NO_BEEP              # ビープ音を無効化

# --------------------------------------------
# 2. History Settings
# --------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS     # 重複コマンドを無視
setopt HIST_IGNORE_SPACE    # スペース始まりは記録しない
setopt SHARE_HISTORY        # 複数ターミナルで履歴共有
setopt APPEND_HISTORY       # 履歴を追記

# --------------------------------------------
# 3. Tool Initialization
# --------------------------------------------
# XON/XOFF フロー制御を無効化（Ctrl+Q を tmux Prefix として使うため）
stty -ixon

# mise は .zshenv で activate 済み
# sheldon (compinit を含む) を先にロード
# tmux 自動起動（WezTerm 起動時に default セッションへ）
# if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
#   exec tmux new-session -A -s default
# fi
eval "$(sheldon source)"
eval "$(zoxide init zsh)"
eval "$(git gtr init zsh)"

# Starship prompt
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

# fzf tmux フローティング連携（display-popup で表示）
export FZF_TMUX_OPTS="--tmux center,80%,60%"
export FZF_CTRL_T_OPTS="--tmux center,80%,60%"
export FZF_ALT_C_OPTS="--tmux center,60%,40%"

# --------------------------------------------
# 4. Aliases & Functions
# --------------------------------------------
source ~/.zsh/aliases.zsh
source ~/.zsh/functions.zsh
source ~/.zsh/tmux.zsh
source ~/.zsh/docker.zsh
source ~/.zsh/repo.zsh
source ~/.zsh/trust.zsh
source ~/.zsh/cc-interrupt.zsh

# --------------------------------------------
# 5. Local Config (machine-specific)
# --------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# bun completions
[ -s "/Users/yoshihiko/.bun/_bun" ] && source "/Users/yoshihiko/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"

alias claude-mem='bun "/Users/yoshihiko/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

