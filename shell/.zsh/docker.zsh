# ============================================
# Docker Functions
# ============================================

# fzf + docker コンテナに入る
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' | fzf | awk '{print $1}')
  [[ -n "$cid" ]] && docker exec -it "$cid" /bin/sh
}

# docker compose 用ファイル候補を列挙
_dcf_list_compose_files() {
  local root="$1"

  if command -v fd >/dev/null 2>&1; then
    fd -a -t f -H -d 8 \
      -E .git -E node_modules -E .next -E dist -E build -E target -E .venv \
      -g 'compose.yml' -g 'compose.yaml' \
      -g 'docker-compose.yml' -g 'docker-compose.yaml' \
      -g 'docker-compose.*.yml' -g 'docker-compose.*.yaml' \
      . "$root"
  else
    find "$root" -maxdepth 8 \
      \( -name .git -o -name node_modules -o -name .next -o -name dist -o -name build -o -name target -o -name .venv \) -prune \
      -o -type f \
      \( -name 'compose.yml' -o -name 'compose.yaml' -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' -o -name 'docker-compose.*.yml' -o -name 'docker-compose.*.yaml' \) \
      -print
  fi
}

# fzf で compose ファイルを選択して docker compose 実行
dcf() {
  local ghq_root current_repo root compose_file rel_path display_path selected compose_dir
  local -a roots args

  if ! command -v docker >/dev/null 2>&1; then
    echo "docker が見つかりません"
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf が見つかりません"
    return 1
  fi

  current_repo="$(git rev-parse --show-toplevel 2>/dev/null)"
  [[ -n "$current_repo" && -d "$current_repo" ]] && roots+=("$current_repo")

  if command -v ghq >/dev/null 2>&1; then
    ghq_root="$(ghq root 2>/dev/null)"
    if [[ -n "$ghq_root" && -d "$ghq_root" && "$ghq_root" != "$current_repo" ]]; then
      roots+=("$ghq_root")
    fi
  fi

  if [[ ${#roots[@]} -eq 0 ]]; then
    echo "探索対象が見つかりません (ghq root または git リポジトリ内で実行してください)"
    return 1
  fi

  selected="$(
    for root in "${roots[@]}"; do
      _dcf_list_compose_files "$root" 2>/dev/null | while IFS= read -r compose_file; do
        rel_path="${compose_file#$root/}"
        display_path="$rel_path"

        # ghq 配下は "host/" を落として見やすくする
        if [[ -n "$ghq_root" && "$root" == "$ghq_root" ]]; then
          [[ "$display_path" == */* ]] && display_path="${display_path#*/}"
        fi

        printf '%s\t%s\n' "$display_path" "$compose_file"
      done
    done \
      | awk -F'\t' '!seen[$2]++' \
      | sort \
      | fzf \
        --delimiter=$'\t' \
        --with-nth=1 \
        --header='compose ファイルを選択 (Enter: 実行 / Esc: キャンセル)' \
        --preview 'sed -n "1,140p" {2}' \
        --preview-window=right:60% \
      | cut -f2
  )"

  [[ -z "$selected" ]] && return 0

  args=("$@")
  [[ ${#args[@]} -eq 0 ]] && args=(ps)

  compose_dir="$(dirname "$selected")"
  (
    cd "$compose_dir" || exit 1
    docker compose -f "$selected" "${args[@]}"
  )
}
