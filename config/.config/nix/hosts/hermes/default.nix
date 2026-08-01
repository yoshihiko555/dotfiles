{ config, ... }:
let
  dotfilesDir = config.hostSpec.dotfilesDir;
in
{
  hostSpec = {
    hostName = "hermes";
    username = "agent";
    dotfilesDir = "/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles";
  };

  homebrew.taps = [ "mostlygeek/llama-swap" ];

  # Hermes Agent の LLM 基盤。実機のツーリングが /opt/homebrew/bin/ の
  # 絶対パスで起動しており、Nix へ移すと稼働が壊れるため brew に残す。
  # 絶対パス参照の調査とデーモン群の launchd 宣言化とセットで移行を再判断する
  # （2026-08-01 時点）。fd / ripgrep は home/packages.nix（Nix 管理）へ移行済み。
  homebrew.brews = [
    "llama.cpp"
    "llama-swap"
    "miniserve"
    # 暫定残留（2026-08-01）: ai.hermes.gateway（launchd）の PATH は
    # /opt/homebrew/bin 固定で、Nix 版 gh（/etc/profiles/per-user/agent/bin）を
    # 探索できない。デーモン群の launchd 宣言管理化で PATH を面倒みるまで
    # brew 版 gh も残す（Nix 版と重複するが無害）
    "gh"
  ];

  # ヘッドレス運用だが、たまに GUI で使う実態があるため cask も宣言管理する。
  # 「cask を1つも書かない」という当初方針（ADR-0003）は 2026-07-30 のユーザー判断で
  # 撤回した（実態に合わないため）。ドキュメント側（ROADMAP 等）の改訂は別途行う。
  homebrew.casks = [
    "1password"
    "1password-cli"
    "codex"
    "ghostty"
    "google-chrome"
    "orbstack"
    "zed"
  ];

  home-manager.users.agent =
    { config, ... }:
    let
      mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    in
    {
      # hermes 専用ミニマル tmux 設定。hermes/ ディレクトリの削除可否判断
      # （ROADMAP Phase 3-1 最終項目）までは現位置からリンクする。
      xdg.configFile."tmux/tmux.conf".source = mkLink "hermes/home/.config/tmux/tmux.conf";

      # 同上。hermes/ ディレクトリの削除可否判断までは現位置からリンクする。
      xdg.configFile."mise/config.toml".source = mkLink "hermes/home/.config/mise/config.toml";

      # 共有側（shell/.zshenv, shell/.zshrc, shell/.zsh/*.zsh）でカバーされない
      # hermes 固有の対話シェル設定（Hermes Agent 運用 alias 等）。
      home.file.".zshrc.local".source = mkLink "config/.config/nix/hosts/hermes/zshrc.local";
    };
}
