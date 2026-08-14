# ============================================
# Worktree Helper
# ============================================

_wt_help() {
  cat <<'HELP'
Usage:
  wt new [topic...]
  wt new [topic...] -- [git gtr new options...]
  wt rm <branch...> [git gtr rm options...]
  wt rm               # fzf で選んで削除
  wt done <branch...> [git gtr rm options...]
  wt <git gtr command...>

Examples:
  wt new nvim lsp
  wt new fix hook tweak -- --from-current -e
  wt rm
  wt rm task/nvim-lsp --yes
  wt list
  wt cd
HELP
}

_wt_dispatch() {
  emulate -L zsh

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
    new|n)
      _wt_new "$@"
      ;;
    rm|remove|done)
      _wt_rm "$@"
      ;;
    help|-h|--help)
      _wt_help
      ;;
    *)
      command git gtr "$cmd" "$@"
      ;;
  esac
}

wt() {
  _wt_dispatch "$@"
}

if (( $+functions[_gtr_completion] )); then
  compdef _gtr_completion wt
fi

_wt_slugify() {
  local input slug
  input="$*"
  slug="$(
    printf '%s' "$input" \
      | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
  )"
  printf '%s\n' "$slug"
}

_wt_normalize_type() {
  case "$1" in
    feat|feature)
      printf 'feat\n'
      ;;
    fix|bugfix|hotfix)
      printf 'fix\n'
      ;;
    chore|docs|refactor|test|ci|perf|build|release|task)
      printf '%s\n' "$1"
      ;;
    *)
      return 1
      ;;
  esac
}

_wt_generate_branch() {
  local type topic slug base branch
  local counter=2

  type="$1"
  shift
  topic="$*"
  slug="$(_wt_slugify "$topic")"

  if [[ -n "$slug" ]]; then
    base="${type}/${slug}"
  else
    base="${type}/worktree-$(date +%Y%m%d-%H%M%S)"
  fi

  branch="$base"
  while command git show-ref --verify --quiet "refs/heads/$branch"; do
    branch="${base}-${counter}"
    ((counter++))
  done

  printf '%s\n' "$branch"
}

_wt_new() {
  emulate -L zsh

  local -a topic_parts gtr_args
  local branch_type="task"
  local expect_value=0

  while (($#)); do
    if ((expect_value)); then
      gtr_args+=("$1")
      expect_value=0
      shift
      continue
    fi

    case "$1" in
      --)
        shift
        gtr_args+=("$@")
        break
        ;;
      --from|--track|--name|--folder)
        gtr_args+=("$1")
        expect_value=1
        shift
        ;;
      --from=*|--track=*|--name=*|--folder=*)
        gtr_args+=("$1")
        shift
        ;;
      --from-current|--no-copy|--no-fetch|--no-hooks|--force|--yes|-e|--editor|-a|--ai)
        gtr_args+=("$1")
        shift
        ;;
      -*)
        gtr_args+=("$1")
        shift
        ;;
      *)
        topic_parts+=("$1")
        shift
        ;;
    esac
  done

  if ((expect_value)); then
    echo "wt new: オプションの値が不足しています"
    return 1
  fi

  if (( ${#topic_parts[@]} > 0 )); then
    local normalized_type
    if normalized_type="$(_wt_normalize_type "${topic_parts[1]}")"; then
      branch_type="$normalized_type"
      topic_parts=("${topic_parts[@]:1}")
    fi
  fi

  local branch
  branch="$(_wt_generate_branch "$branch_type" "${topic_parts[@]}")" || return $?

  echo "branch: $branch"
  command git gtr new "$branch" "${gtr_args[@]}"
}

_wt_pick_branches() {
  emulate -L zsh

  if ! command -v fzf >/dev/null 2>&1; then
    echo "wt rm: fzf が見つかりません"
    return 1
  fi

  local current_worktree
  current_worktree="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1

  local candidates
  candidates="$(
    command git gtr list --porcelain \
      | awk -F '\t' -v current="$current_worktree" '$1 != current { print }'
  )" || return 1

  if [[ -z "$candidates" ]]; then
    echo "wt rm: 削除候補の worktree がありません"
    return 1
  fi

  local selected
  selected="$(
    printf '%s\n' "$candidates" | fzf -m \
      --delimiter=$'\t' \
      --with-nth=2,3,1 \
      --layout=reverse \
      --border \
      --prompt='Remove worktree> ' \
      --header='tab:mark enter:remove' \
      --preview='git -C {1} log --oneline --graph --color=always -15 2>/dev/null; echo "---"; git -C {1} status --short 2>/dev/null'
  )" || return 0

  [[ -z "$selected" ]] && return 0
  printf '%s\n' "$selected" | cut -f2
}

_wt_rm() {
  emulate -L zsh

  local -a branches options picked
  local has_delete_branch=0
  local arg

  while (($#)); do
    case "$1" in
      -*)
        options+=("$1")
        ;;
      *)
        branches+=("$1")
        ;;
    esac
    shift
  done

  if (( ${#branches[@]} == 0 )); then
    picked=("${(@f)$(_wt_pick_branches)}")
    [[ ${#picked[@]} -eq 0 ]] && return 0
    branches=("${picked[@]}")
  fi

  for arg in "${options[@]}"; do
    if [[ "$arg" == "--delete-branch" ]]; then
      has_delete_branch=1
      break
    fi
  done

  if (( ! has_delete_branch )); then
    options+=("--delete-branch")
  fi

  command git gtr rm "${branches[@]}" "${options[@]}"
}
