{ lib, hostSpec, ... }:
{
  imports = [
    ./dotfiles.nix
    ./packages.nix
  ];

  home.username = hostSpec.username;
  # macOS は /Users、Linux（WSL2）は /home とホーム直下の規約が異なるため、
  # パスをここで組み立てずホスト側の宣言（hostSpec.homeDirectory）に委ねる。
  home.homeDirectory = lib.mkForce hostSpec.homeDirectory;

  # home-manager の現行の最新値（26.05, isReleaseBranch のもの）。
  # 新規導入のため最新値を採用し、以後は変更しない方針。
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
