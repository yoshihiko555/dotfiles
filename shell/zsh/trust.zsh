# ============================================
# Codex Trust Management
# ============================================

# Codex trust 設定を操作
trust() {
  local repo_root="$DOTFILES"
  local repo_config="$DOTFILES/codex/config.toml"
  local home_config="$HOME/.codex/config.toml"
  local manager="$repo_root/scripts/codex-trust-manage.sh"
  local auditor="$repo_root/scripts/codex-trust-audit.sh"
  local config="${CODEX_CONFIG_PATH:-}"
  local cmd="${1:-}"
  local input_path level

  if [[ -z "$config" ]]; then
    if [[ -f "$repo_config" ]]; then
      config="$repo_config"
    else
      config="$home_config"
    fi
  fi

  if [[ ! -f "$config" ]]; then
    echo "config が見つかりません: $config"
    return 1
  fi

  if [[ ! -x "$manager" ]]; then
    echo "trust 管理スクリプトが見つかりません: $manager"
    return 1
  fi

  case "$cmd" in
    add)
      input_path="${2:-$PWD}"
      level="${3:-trusted}"
      CODEX_CONFIG_PATH="$config" bash "$manager" add "$input_path" "$level"
      ;;
    rm)
      input_path="${2:-$PWD}"
      CODEX_CONFIG_PATH="$config" bash "$manager" rm "$input_path"
      ;;
    list)
      CODEX_CONFIG_PATH="$config" bash "$manager" list
      ;;
    audit)
      CODEX_CONFIG_PATH="$config" bash "$auditor"
      ;;
    where)
      echo "$config"
      ;;
    *)
      cat <<'HELP'
Usage:
  trust add [path] [trusted|untrusted]
  trust rm [path]
  trust list
  trust audit
  trust where
HELP
      return 1
      ;;
  esac
}
