{ ... }:
{
  homebrew.enable = true;

  homebrew.onActivation = {
    autoUpdate = false;
    # 宣言にない formula/cask を自動削除する。ADR-20260730-0003 の主目的
    # 「宣言と実態のズレを構造的に防ぐ」ための設定。
    # 注意: mozumasu/dotfiles は新しめの Homebrew で `brew bundle --cleanup` が
    # 対話的な dry-run 化して機能しなくなった事例を報告し "none" に切り替えている。
    # 当リポジトリは ADR-0003 の方針（zap による腐敗防止）をまず優先して試し、
    # hermes 実機で動作しない場合は再判断する。
    cleanup = "zap";
    extraEnv = {
      HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    };
  };

  homebrew.taps = [ "coderabbitai/tap" ];

  # 3 台共通の CLI（root Brewfile と hermes/Brewfile の交差 15 個）。
  # WSL2（Phase 3-3）は darwin モジュールを通らないため、実質 darwin 2 台の共通集合。
  homebrew.brews = [
    "coderabbitai/tap/git-gtr"
    "d2"
    "fzf"
    "gh"
    "ghq"
    "git"
    "glow"
    "lazygit"
    "mise"
    "neovim"
    "starship"
    "tmux"
    "tree"
    "yazi"
    "zoxide"
  ];
}
