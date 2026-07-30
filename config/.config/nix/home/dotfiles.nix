{ config, hostSpec, ... }:
let
  # 3 台共通の配線。stow の `shell` / `config` パッケージの home-manager 版に相当する。
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${hostSpec.dotfilesDir}/${path}";
in
{
  home.file = {
    ".zshenv".source = mkLink "shell/.zshenv";
    ".zprofile".source = mkLink "shell/.zprofile";
    ".zshrc".source = mkLink "shell/.zshrc";
    ".zsh".source = mkLink "shell/.zsh";
  };

  xdg.configFile = {
    "starship".source = mkLink "config/.config/starship";
    "git".source = mkLink "config/.config/git";
    "nvim".source = mkLink "config/.config/nvim";
  };
}
