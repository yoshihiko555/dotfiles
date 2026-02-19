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
# mise は .zshenv で activate 済み
eval "$(zoxide init zsh)"
eval "$(sheldon source)"

# Starship prompt
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

# --------------------------------------------
# 4. Aliases
# --------------------------------------------
source ~/.zsh/aliases.zsh

# --------------------------------------------
# 5. Functions
# --------------------------------------------
# カスタムコマンド一覧を表示
cheat() {
  cat <<'HELP'
── General ─────────────────────────────────
  ll        ls -lah
  la        ls -A
  ..        cd ..  /  ...  cd ../..  /  ....  cd ../../..
  mkdir     mkdir -p (自動で親ディレクトリ作成)
  rm/cp/mv  確認付き (-i)

── Git ─────────────────────────────────────
  g         git
  gs        git status       ga   git add
  gc        git commit       gp   git push
  gl        git log (10件)   gd   git diff
  gb        git branch       gco  git checkout
  gsw       git switch       lg   lazygit

── Docker ──────────────────────────────────
  d         docker           dc   docker compose
  dps       docker ps        dpsa docker ps -a
  conin     docker exec -it

── Dev ─────────────────────────────────────
  v         nvim             c    clear
  h         history          t    tmux
  cc        claude           cx   codex
  gm        gemini
  code      code .

── Digital Garden ──────────────────────────
  trend     今日のトレンドメモを開く
  daily     daily ノート一覧
  weekly    weekly クリッピング一覧

── Tmux ────────────────────────────────────
  t         tmux               ta   attach
  tl        list-sessions      td   detach
  tn        new-session
  tss       fzf でセッション切り替え
  tk        fzf でセッション kill
  tp        ghq プロジェクトでセッション作成
  -s NAME   セッション名を付けて作成  (tn -s work)
  -t NAME   対象セッションを指定      (ta -t work)

── Functions (fzf) ─────────────────────────
  repo      ghq リポジトリに移動
  fe        ファイル検索 → nvim で開く
  fh        コマンド履歴検索
  fb        git ブランチ切り替え
  fkill     プロセスを選んで kill
  dex       docker コンテナに入る
  mdopen    Markdown を選んで Dia で開く

── Functions (util) ────────────────────────
  mkcd DIR  ディレクトリ作成して cd
  port NUM  ポート使用プロセス確認
  trust ... Codex trust を add/rm/list/audit
  cheat     このヘルプを表示
HELP
}

# fzf でMarkdownを選んでブラウザで開く
mdopen() {
  local dir="${1:-.}"
  dir="${dir%/}"
  local file
  file=$(find "$dir" -name "*.md" -type f | sed "s|^${dir}/||" | sort -r \
    | fzf --preview "head -40 ${dir}/{}")
  [[ -n "$file" ]] && open -a "Dia" "$dir/$file"
}

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

# Codex trust 設定を操作
trust() {
  local repo_root="$HOME/ghq/github.com/yoshihiko555/dotfiles"
  local repo_config="$HOME/ghq/github.com/yoshihiko555/dotfiles/codex/.codex/config.toml"
  local home_config="$HOME/.codex/config.toml"
  local manager="$repo_root/scripts/codex-trust-manage.sh"
  local auditor="$repo_root/scripts/codex-trust-audit.sh"
  local config="${CODEX_CONFIG_PATH:-}"
  local cmd="${1:-}"
  local input_path level

  if [[ -z "$config" ]]; then
    if [[ -f "$repo_config" ]]; then
      config="$repo_config"
    else
      config="$home_config"
    fi
  fi

  if [[ ! -f "$config" ]]; then
    echo "config が見つかりません: $config"
    return 1
  fi

  if [[ ! -x "$manager" ]]; then
    echo "trust 管理スクリプトが見つかりません: $manager"
    return 1
  fi

  case "$cmd" in
    add)
      input_path="${2:-$PWD}"
      level="${3:-trusted}"
      CODEX_CONFIG_PATH="$config" bash "$manager" add "$input_path" "$level"
      ;;
    rm)
      input_path="${2:-$PWD}"
      CODEX_CONFIG_PATH="$config" bash "$manager" rm "$input_path"
      ;;
    list)
      CODEX_CONFIG_PATH="$config" bash "$manager" list
      ;;
    audit)
      CODEX_CONFIG_PATH="$config" bash "$auditor"
      ;;
    where)
      echo "$config"
      ;;
    *)
      cat <<'HELP'
Usage:
  trust add [path] [trusted|untrusted]
  trust rm [path]
  trust list
  trust audit
  trust where
HELP
      return 1
      ;;
  esac
}

# fzf + tmux セッション切り替え/作成
tss() {
  if ! command tmux list-sessions &>/dev/null; then
    command tmux new-session
    return
  fi
  local session
  session=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_attached} attached)' \
    | fzf --header='Switch session (Ctrl-C to cancel)' \
    | cut -d: -f1)
  if [[ -n "$session" ]]; then
    if [[ -n "$TMUX" ]]; then
      command tmux switch-client -t "$session"
    else
      command tmux attach-session -t "$session"
    fi
  fi
}

# fzf + tmux セッションを選んで kill
tk() {
  local sessions
  sessions=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows' 2>/dev/null)
  if [[ -z "$sessions" ]]; then
    echo "No tmux sessions."
    return 1
  fi
  local selected
  selected=$(echo "$sessions" | fzf -m --header='Kill session (Tab for multi-select)' | cut -d: -f1)
  if [[ -n "$selected" ]]; then
    echo "$selected" | while read -r s; do
      command tmux kill-session -t "$s" && echo "Killed: $s"
    done
  fi
}

# プロジェクトディレクトリで tmux セッション作成
tp() {
  local selected name
  selected=$(ghq list | fzf --delimiter=/ --with-nth=2.. --preview 'ls -la "$(ghq root)/{}"' --header='Create tmux session for project')
  if [[ -n "$selected" ]]; then
    name=$(basename "$selected")
    local dir="$(ghq root)/$selected"
    if command tmux has-session -t "=$name" 2>/dev/null; then
      if [[ -n "$TMUX" ]]; then
        command tmux switch-client -t "=$name"
      else
        command tmux attach-session -t "=$name"
      fi
    else
      if [[ -n "$TMUX" ]]; then
        command tmux new-session -d -s "$name" -c "$dir" && command tmux switch-client -t "=$name"
      else
        command tmux new-session -s "$name" -c "$dir"
      fi
    fi
  fi
}

# ghq + fzf でリポジトリに移動
repo() {
  local selected
  selected=$(ghq list | fzf --delimiter=/ --with-nth=2.. --preview 'ls -la "$(ghq root)/{}"')
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
# 6. Local Config (machine-specific)
# --------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# bun completions
[ -s "/Users/yoshihiko/.bun/_bun" ] && source "/Users/yoshihiko/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"

alias claude-mem='bun "/Users/yoshihiko/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'
