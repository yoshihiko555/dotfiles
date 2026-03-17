# ============================================
# Tmux Functions
# ============================================

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
