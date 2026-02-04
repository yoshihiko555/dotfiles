# ============================================
# Zsh Environment (loaded for all shells)
# ============================================

# Homebrew (Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# mise (runtime version manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi
