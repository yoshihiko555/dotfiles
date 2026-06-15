# Minimal interactive helpers for macmini-hermes.
# Keep this file standalone: it is copied into ~/.zsh and sourced from ~/.zshrc.

[[ -o interactive ]] || return 0

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

if [[ -t 0 ]]; then
  stty -ixon 2>/dev/null || true
fi

if command -v mise >/dev/null 2>&1 && [[ -z "${MISE_SHELL:-}" ]]; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  [[ -f "$HOME/.config/starship/starship.toml" ]] && export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
  eval "$(starship init zsh)"
fi

export FZF_TMUX_OPTS="--tmux center,80%,60%"
export FZF_CTRL_T_OPTS="--tmux center,80%,60%"
export FZF_ALT_C_OPTS="--tmux center,60%,40%"

alias ls='ls -G'
alias ll='ls -lah'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

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

alias tmux='command tmux'
alias t='command tmux'
alias ta='command tmux attach-session'
alias tl='command tmux list-sessions'
alias td='command tmux detach-client'
alias tn='command tmux new-session'

alias c='clear'
alias v='nvim'
alias hms='hermes'
alias hstatus='hermes status'
alias hlog='hermes logs'
alias hlogs='hermes logs -f'
alias hdash='hermes dashboard'
alias hstop='hermes dashboard --stop'

_hermes_need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "$1 is not installed"
  return 1
}

cheat() {
  cat <<'HELP'
General:
  ll/la      list files
  .. ...     cd up
  mkcd DIR   mkdir -p and cd
  port NUM   show process using a port

Git:
  g/gs/ga/gc/gp/gl/gd/gb/gco/gsw
  lg         lazygit
  wt         git-gtr helper

Finder:
  repo       ghq repo picker
  fe         file picker -> editor
  fh         history picker
  fb         branch picker
  fkill      process picker -> kill

Tmux:
  t/ta/tl/td/tn
  tss        switch/attach tmux session
  tk         kill tmux session
  tp         new/switch project tmux session from ghq

Hermes:
  hms        hermes
  hstatus    hermes status
  hlog       hermes logs
  hlogs      hermes logs -f
  hdash      hermes dashboard
  hstop      hermes dashboard --stop
HELP
}

lazygit() {
  _hermes_need lazygit || return 1
  XDG_CONFIG_HOME="$HOME/.config" command lazygit "$@"
}

mkcd() {
  [[ -n "${1:-}" ]] || { echo "Usage: mkcd <dir>"; return 1; }
  mkdir -p "$1" && cd "$1"
}

port() {
  [[ -n "${1:-}" ]] || { echo "Usage: port <port>"; return 1; }
  lsof -i :"$1"
}

fh() {
  _hermes_need fzf || return 1
  local selected
  selected=$(history -n 1 | fzf --tac --no-sort)
  [[ -n "$selected" ]] && print -z "$selected"
}

fb() {
  _hermes_need fzf || return 1
  local branch
  branch=$(git branch -a | sed 's/^..//' | sed 's|remotes/origin/||' | sort -u | fzf)
  [[ -n "$branch" ]] && git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

fkill() {
  _hermes_need fzf || return 1
  local pid
  pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

fe() {
  _hermes_need fzf || return 1
  local file editor
  if command -v fd >/dev/null 2>&1; then
    file=$(fd -t f -H -E .git -E node_modules -E .venv -E dist -E build | fzf --preview 'sed -n "1,120p" {}')
  else
    file=$(find . -type f 2>/dev/null | fzf --preview 'sed -n "1,120p" {}')
  fi
  [[ -z "$file" ]] && return 0
  editor="${EDITOR:-}"
  [[ -z "$editor" ]] && command -v nvim >/dev/null 2>&1 && editor=nvim
  [[ -z "$editor" ]] && editor=vi
  "$editor" "$file"
}

_hermes_repo_items() {
  local ghq_root line wt_dir wt_name repo_rel
  ghq_root="$(ghq root)" || return 1

  ghq list | while IFS= read -r line; do
    printf 'repo\t%s\t%s/%s\n' "$line" "$ghq_root" "$line"
  done

  find "$ghq_root" -maxdepth 5 -type d -name ".worktrees" 2>/dev/null | while IFS= read -r wt_dir; do
    repo_rel="${wt_dir#"$ghq_root"/}"
    repo_rel="${repo_rel%/.worktrees}"
    for d in "$wt_dir"/*/; do
      [[ -d "$d" ]] || continue
      wt_name="$(basename "$d")"
      printf 'worktree\t%s:%s\t%s\n' "$repo_rel" "$wt_name" "${d%/}"
    done
  done
}

repo() {
  _hermes_need ghq || return 1
  _hermes_need fzf || return 1

  local selected repo_path
  selected=$(
    _hermes_repo_items | awk -F'\t' '{
      if ($1 == "repo") printf "repo     %s\t%s\n", $2, $3
      else printf "worktree %s\t%s\n", $2, $3
    }' | fzf --with-nth=1 --delimiter='\t' --preview 'ls -la {2}'
  )
  [[ -z "$selected" ]] && return 0
  repo_path=$(echo "$selected" | cut -f2)
  cd "$repo_path"
}

tss() {
  _hermes_need tmux || return 1
  _hermes_need fzf || return 1

  if ! command tmux list-sessions >/dev/null 2>&1; then
    command tmux new-session
    return
  fi

  local session
  session=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_attached} attached)' \
    | fzf --header='Switch session' \
    | cut -d: -f1)
  [[ -z "$session" ]] && return 0

  if [[ -n "$TMUX" ]]; then
    command tmux switch-client -t "$session"
  else
    command tmux attach-session -t "$session"
  fi
}

tk() {
  _hermes_need tmux || return 1
  _hermes_need fzf || return 1

  local selected
  selected=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows' 2>/dev/null \
    | fzf -m --header='Kill session' \
    | cut -d: -f1)
  [[ -z "$selected" ]] && return 0

  echo "$selected" | while read -r session; do
    command tmux kill-session -t "$session" && echo "Killed: $session"
  done
}

tp() {
  _hermes_need ghq || return 1
  _hermes_need fzf || return 1
  _hermes_need tmux || return 1

  local selected name dir
  selected=$(ghq list | fzf --delimiter=/ --with-nth=2.. --preview 'ls -la "$(ghq root)/{}"' --header='Project tmux session')
  [[ -z "$selected" ]] && return 0

  name=$(basename "$selected")
  dir="$(ghq root)/$selected"

  if command tmux has-session -t "=$name" 2>/dev/null; then
    [[ -n "$TMUX" ]] && command tmux switch-client -t "=$name" || command tmux attach-session -t "=$name"
  else
    [[ -n "$TMUX" ]] && command tmux new-session -d -s "$name" -c "$dir" && command tmux switch-client -t "=$name" || command tmux new-session -s "$name" -c "$dir"
  fi
}

wt() {
  _hermes_need git || return 1
  if ! git gtr --help >/dev/null 2>&1; then
    echo "git-gtr is not installed"
    return 1
  fi
  command git gtr "$@"
}
