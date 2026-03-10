#!/bin/bash
# stow-worktree.sh - worktree の stow 切り替えスクリプト
#
# Usage:
#   stow-worktree.sh apply <worktree名> <package...>  # worktree の stow を適用
#   stow-worktree.sh revert <worktree名> <package...>  # メインリポジトリに戻す

set -euo pipefail

DOTFILES_DIR="$HOME/ghq/github.com/yoshihiko555/dotfiles"
WORKTREES_DIR="$DOTFILES_DIR/.worktrees"

usage() {
  echo "Usage: $(basename "$0") {apply|revert} <worktree> <package...>"
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") apply tmux tmux config shell"
  echo "  $(basename "$0") revert tmux tmux config shell"
  exit 1
}

if [[ $# -lt 3 ]]; then
  usage
fi

ACTION="$1"
WORKTREE="$2"
shift 2
PACKAGES=("$@")

WORKTREE_DIR="$WORKTREES_DIR/$WORKTREE"

if [[ ! -d "$WORKTREE_DIR" ]]; then
  echo "Error: worktree '$WORKTREE' not found at $WORKTREE_DIR"
  exit 1
fi

case "$ACTION" in
  apply)
    echo "==> メインリポジトリの stow を解除..."
    cd "$DOTFILES_DIR"
    stow -D -t "$HOME" "${PACKAGES[@]}"

    echo "==> worktree ($WORKTREE) から stow を適用..."
    cd "$WORKTREE_DIR"
    stow -t "$HOME" "${PACKAGES[@]}"

    echo ""
    echo "Done! worktree '$WORKTREE' の設定が適用されました。"
    echo "元に戻すには: $(basename "$0") revert $WORKTREE ${PACKAGES[*]}"
    ;;
  revert)
    echo "==> worktree ($WORKTREE) の stow を解除..."
    cd "$WORKTREE_DIR"
    stow -D -t "$HOME" "${PACKAGES[@]}"

    echo "==> メインリポジトリの stow を再適用..."
    cd "$DOTFILES_DIR"
    stow -t "$HOME" "${PACKAGES[@]}"

    echo ""
    echo "Done! メインリポジトリの設定に戻りました。"
    ;;
  *)
    usage
    ;;
esac
