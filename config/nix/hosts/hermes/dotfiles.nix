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
      # 共有側（shell/zshenv, shell/zshrc, shell/zsh/*.zsh）でカバーされない
      # hermes 固有の対話シェル設定（Hermes Agent 運用 alias 等）。
      home.file.".zshrc.local".source = mkLink "config/nix/hosts/hermes/zshrc.local";
    };
}
