{ config, hostSpec, ... }:
let
  # 2 台以上で使う設定の共通配線（ADR-0004 ルール 3）。
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${hostSpec.dotfilesDir}/${path}";
in
{
  home.file = {
    ".zshenv".source = mkLink "shell/zshenv";
    ".zprofile".source = mkLink "shell/zprofile";
    ".zshrc".source = mkLink "shell/zshrc";
    ".zsh".source = mkLink "shell/zsh";
  };

  xdg.configFile = {
    "starship".source = mkLink "config/starship";
    "git".source = mkLink "config/git";
    "mise".source = mkLink "config/mise";
    "nvim".source = mkLink "config/nvim";
    "tmux".source = mkLink "config/tmux";
  };
}
