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
      # sudo 経由の activation ではユーザーの tap trust 情報が参照できず、
      # サードパーティ tap（coderabbitai/tap 等）の formula ロードが
      # "untrusted tap" エラーで拒否されるため無効化する（mozumasu も同様の対応）。
      # hermes 実機で発生を確認済み（2026-07-31）。
      HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
    };
  };

  # nixpkgs 未収録のものだけを brew で管理する（共存方針: CLI = Nix、
  # brew は cask + nixpkgs 未収録専用）。
  # nixpkgs 収録の CLI 16 個は home/packages.nix へ移行済み（2026-08-01）。
  # git-gtr（coderabbitai/tap）は hermes で未使用と判断し共通層から降格（2026-08-02）。
  # MBP では使用中のため Phase 3-2 で hosts/macbook/homebrew.nix に宣言する
  # （ADR-0004 ルール 3: 共通層に置くのは 2 台以上で使うものだけ）。
  homebrew.taps = [ ];
  homebrew.brews = [ ];
}
