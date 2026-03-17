# ============================================
# Repository Navigation
# ============================================

# ghq + fzf でリポジトリに移動（.worktrees 配下も対象）
# リスト生成は scripts/repo-list.sh に委譲（WezTerm InputSelector と共有）
repo() {
  local script="$HOME/ghq/github.com/yoshihiko555/dotfiles/scripts/repo-list.sh"
  if [[ ! -x "$script" ]]; then echo "repo-list.sh が見つかりません" && return 1; fi
  if ! command -v fzf &>/dev/null; then echo "fzf が見つかりません" && return 1; fi

  local selected
  selected=$(
    "$script" | awk -F'\t' '{
      if ($1 == "repo") printf "\xf0\x9f\x8c\xb3 %s\t%s\n", $2, $3
      else printf "\xf0\x9f\x8c\xbf %s\t%s\n", $2, $3
    }' | fzf --ansi --with-nth=1 --delimiter='\t' --preview '
      repo_path={2}
      ls -la "$repo_path"
    '
  )

  [[ -z "$selected" ]] && return

  local repo_path
  repo_path=$(echo "$selected" | cut -f2)
  cd "$repo_path"
}
