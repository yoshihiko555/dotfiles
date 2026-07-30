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

  # hermes 固有 brews（hermes/Brewfile にありルート Brewfile に無いもの: fd, ripgrep）に加え、
  # Hermes Agent の LLM 基盤（llama.cpp / llama-swap / miniserve）を宣言する。
  # hermes/Brewfile には未記載だが実機に存在し、zap による削除を防ぐため宣言する。
  homebrew.brews = [
    "fd"
    "ripgrep"
    "llama.cpp"
    "llama-swap"
    "miniserve"
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
