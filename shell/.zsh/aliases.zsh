# ============================================
# Aliases
# ============================================

# --------------------------------------------
# General
# --------------------------------------------
# ファイル操作
alias ls='ls -G'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'

# 安全策
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --------------------------------------------
# Git
# --------------------------------------------
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias lg='lazygit'

# --------------------------------------------
# Docker
# --------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias conin='docker container exec -it'

# --------------------------------------------
# Development
# --------------------------------------------
# Wails
alias wails='go run github.com/wailsapp/wails/v2/cmd/wails@latest'
alias wails3='go run github.com/wailsapp/wails/v3/cmd/wails3@latest'

# Claude CLI
alias cc='claude'
alias cc-dg='claude --dangerously-skip-permissions'

# Codex CLI
alias cx='codex'

# Gemini CLI
alias gm='gemini'

# tmux（AUTO_CD でディレクトリに移動するのを防ぐ）
alias tmux='command tmux'
alias t='command tmux'
alias ta='command tmux attach-session'
alias tl='command tmux list-sessions'
alias td='command tmux detach-client'
alias tn='command tmux new-session'

# よく使うコマンド短縮
alias c='clear'
alias h='history'
alias v='nvim'
alias code='code .'

# Digital Garden
DG_ROOT=~/ghq/github.com/yoshihiko555/digital-garden
alias trend="open -a Dia \$DG_ROOT/content/daily/\$(date +%Y%m%d)-trend.md"
alias daily="mdopen \$DG_ROOT/content/daily/"
alias weekly="mdopen \$DG_ROOT/content/clippings/weekly/"

# Ai Orchestra
OCHE_ROOT=~/ghq/github.com/yoshihiko555/ai-orchestra
alias oche="python \$OCHE_ROOT/scripts/orchestra-manager.py"
