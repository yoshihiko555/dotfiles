{ config, lib, ... }:
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

  # 対話利用の brew（switch 経路ではない）は Homebrew 6.0 の tap trust に従うため、
  # ~/.homebrew/trust.json に信頼済み tap が無いと `brew info --cask aerospace` 等が
  # "Refusing to load cask ... from untrusted tap" で落ちる。上の
  # HOMEBREW_NO_REQUIRE_TAP_TRUST は brew bundle の env にしか効かないので、
  # 新規端末では手で `brew trust` を叩き直す必要があった。それを switch に取り込む。
  #
  # trust.json は brew が所有者・パーミッションを検証したうえで 0600 の実ファイルとして
  # 原子的に書き換える（symlink 先が /nix/store だと書き込み拒否）ため、home.file では
  # 配線できない。宣言済み tap を毎 switch で `brew trust --tap` に流し込み、実ファイル側を
  # 宣言へ追従させる方式を採る。
  #
  # - 追加のみ。宣言から消えた tap の untrust はしない（手動 trust を巻き込んで剥がすため）
  # - 既に信頼済みなら brew 側が no-op を返すので毎回実行してよい
  # - home-manager の activation は brew bundle より後に走る。初回 switch の bundle は
  #   trust.json がまだ無い状態で動くので、上の HOMEBREW_NO_REQUIRE_TAP_TRUST は残す
  # - tap 未宣言のホスト（hermes）では中身が空になり実質 no-op
  home-manager.users.${config.hostSpec.username} =
    { lib, ... }:
    {
      home.activation.brewTapTrust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        brew_bin="${config.homebrew.prefix}/bin/brew"
        declared_taps=( ${lib.escapeShellArgs (map (tap: tap.name) config.homebrew.taps)} )

        if [ -x "$brew_bin" ] && [ ''${#declared_taps[@]} -gt 0 ]; then
          for tap in "''${declared_taps[@]}"; do
            # --quiet で「Trusted / Already trusted」の定型出力だけを落とす（失敗時の
            # stderr は残す）。失敗しても switch 全体は止めない。
            run --quiet "$brew_bin" trust --tap "$tap" \
              || echo "brewTapTrust: $tap の trust に失敗しました" >&2
          done
        fi
      '';
    };
}
