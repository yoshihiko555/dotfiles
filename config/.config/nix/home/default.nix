{ lib, hostSpec, ... }:
{
  imports = [ ./dotfiles.nix ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";

  # home-manager の現行の最新値（26.05, isReleaseBranch のもの）。
  # 新規導入のため最新値を採用し、以後は変更しない方針。
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
