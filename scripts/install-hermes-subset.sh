#!/usr/bin/env bash
# Install a small, copied CLI subset for macmini-hermes.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"

install_brew=0
with_nvim=0

usage() {
  cat <<'HELP'
Usage:
  scripts/install-hermes-subset.sh [--brew] [--with-nvim]

Options:
  --brew       Run brew bundle with hermes/Brewfile.
  --with-nvim  Copy config/.config/nvim into ~/.config/nvim.
HELP
}

while (($#)); do
  case "$1" in
    --brew)
      install_brew=1
      ;;
    --with-nvim)
      with_nvim=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.bak.${stamp}"
    mv "$target" "$backup"
    echo "backup: $target -> $backup"
  fi
}

install_file() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "unchanged: $dst"
    return
  fi

  backup_path "$dst"
  cp "$src" "$dst"
  echo "installed: $dst"
}

install_dir() {
  local src="$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"
  if [[ -d "$dst" ]]; then
    backup_path "$dst"
  fi

  mkdir -p "$dst"
  cp -R "$src"/. "$dst"/
  echo "installed: $dst"
}

append_zshrc_block() {
  local zshrc="$HOME/.zshrc"
  local start="# >>> hermes cli subset >>>"
  local end="# <<< hermes cli subset <<<"

  touch "$zshrc"
  if grep -Fq "$start" "$zshrc"; then
    echo "zshrc block already exists: $zshrc"
    return
  fi

  cp "$zshrc" "${zshrc}.bak.${stamp}"
  {
    printf '\n%s\n' "$start"
    printf '[[ -r "$HOME/.zsh/hermes-helpers.zsh" ]] && source "$HOME/.zsh/hermes-helpers.zsh"\n'
    printf '%s\n' "$end"
  } >> "$zshrc"
  echo "updated: $zshrc"
}

if (( install_brew )); then
  if ! command -v brew >/dev/null 2>&1; then
    echo "brew is not installed" >&2
    exit 1
  fi
  brew bundle --file "$repo_root/hermes/Brewfile"
fi

install_file "$repo_root/hermes/home/.zsh/hermes-helpers.zsh" "$HOME/.zsh/hermes-helpers.zsh"
install_file "$repo_root/hermes/home/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
install_file "$repo_root/hermes/home/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
install_file "$repo_root/config/.config/starship/starship.toml" "$HOME/.config/starship/starship.toml"
install_file "$repo_root/config/.config/git/ignore" "$HOME/.config/git/ignore"

if (( with_nvim )); then
  install_dir "$repo_root/config/.config/nvim" "$HOME/.config/nvim"
fi

append_zshrc_block

echo
echo "Done. Restart zsh or run:"
echo "  source ~/.zshrc"
