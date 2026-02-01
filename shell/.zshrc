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
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(sheldon source)"

# Starship prompt
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

# --------------------------------------------
# 4. Aliases - General
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
# 5. Aliases - Git
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
# 6. Aliases - Docker
# --------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias conin='docker container exec -it'

# --------------------------------------------
# 7. Aliases - Development
# --------------------------------------------
# Wails
alias wails='go run github.com/wailsapp/wails/v2/cmd/wails@latest'
alias wails3='go run github.com/wailsapp/wails/v3/cmd/wails3@latest'

# よく使うコマンド短縮
alias c='clear'
alias h='history'
alias v='nvim'
alias code='code .'

# --------------------------------------------
# 8. Functions
# --------------------------------------------
# ディレクトリ作成してcd
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ポート使用プロセス確認
port() {
  if [[ -z "$1" ]]; then
    echo "Usage: port <port_number>"
    echo "Example: port 3000"
    return 1
  fi
  lsof -i :"$1"
}

# ghq + fzf でリポジトリに移動
repo() {
  local selected
  selected=$(ghq list | fzf --preview 'ls -la "$(ghq root)/{}"')
  [[ -n "$selected" ]] && cd "$(ghq root)/$selected"
}

# fzf + コマンド履歴検索
fh() {
  local selected
  selected=$(history -n 1 | fzf --tac --no-sort)
  [[ -n "$selected" ]] && print -z "$selected"
}

# fzf + git ブランチ切り替え
fb() {
  local branch
  branch=$(git branch -a | sed 's/^..//' | sed 's|remotes/origin/||' | sort -u | fzf)
  [[ -n "$branch" ]] && git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

# fzf + プロセスキル
fkill() {
  local pid
  pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# fzf + ファイル検索して nvim で開く
fe() {
  local file
  file=$(find . -type f 2>/dev/null | fzf --preview 'head -100 {}')
  [[ -n "$file" ]] && nvim "$file"
}

# fzf + docker コンテナに入る
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' | fzf | awk '{print $1}')
  [[ -n "$cid" ]] && docker exec -it "$cid" /bin/sh
}

# --------------------------------------------
# 9. Local Config (machine-specific)
# --------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
