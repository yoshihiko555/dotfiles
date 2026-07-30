# ============================================
# Zsh Environment (loaded for all shells)
# ============================================

# dotfiles リポジトリの場所（各 zsh 設定から参照する）
export DOTFILES="${DOTFILES:-$HOME/ghq/github.com/yoshihiko555/dotfiles}"

# Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# mise (runtime version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi
