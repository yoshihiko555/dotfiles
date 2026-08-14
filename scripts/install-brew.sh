#!/usr/bin/env bash
# 新規 Mac のブートストラップ時に Homebrew 本体を導入するためのスクリプト。
# パッケージ自体は nix-darwin の homebrew.* 宣言（config/nix/）が管理する。
set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  exit 0
fi

echo "Homebrew が見つからないため、インストールします..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [ -d "/opt/homebrew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -d "/usr/local/Homebrew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
