{ config, ... }:
let
  dotfilesDir = config.hostSpec.dotfilesDir;
in
{
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
