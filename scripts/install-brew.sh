#!/usr/bin/env bash
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
