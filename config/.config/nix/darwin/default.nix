{ config, ... }:
{
  # darwin ホスト（hermes / macbook）共通のシステム層。
  # WSL2（standalone home-manager）はこの層を通らない。
  # 3 台共通のユーザー環境は home/ に置く（層の設計は ADR-0004）。
  imports = [ ./homebrew.nix ];

  # Nix 本体（デーモン・ストア・nix.conf）は nix-darwin が管理する。
  # 2026-08-02 に hermes を Determinate Nix から素の Nix（NixOS/nix-installer）へ
  # 移行し、`nix.enable = false` を解除した。Determinate 運用下ではこの 1 行により
  # `nix.*` 配下の大半が使用不能だった（詳細は docs/USECASES.md の留意事項）。
  #
  # nix-darwin が nix.conf を管理下に置くため、nix-installer が書いていた設定は
  # ここで明示しないと失われる。特に experimental-features を落とすと flake が
  # 評価できなくなり、次回以降 switch できなくなるので必須。
  nix.settings = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    always-allow-substitutes = true;
    max-jobs = "auto";
    extra-nix-path = "nixpkgs=flake:nixpkgs";
    # 移行直後は root のみになっていた。作業ユーザーが substituter の指定や
    # flake の信頼設定を行えるよう追加する（Determinate 運用時は同社が設定していた）。
    # root は nix-darwin が既定で含めるため、ここには書かない（書くと重複する）。
    trusted-users = [ config.hostSpec.username ];
  };

  # /etc/zshenv 経由で nix-darwin の PATH 設定（/run/current-system/sw/bin 等）を
  # 通すために有効化する。zsh 自体の初期化ロジックは shell/.zshenv 側に一本化しており、
  # ここでは compinit 等は触らない。
  programs.zsh.enable = true;

  # shell/.zshenv は `${DOTFILES:-$HOME/ghq/...}` とデフォルト値参照のため、
  # /etc 側で先に export しておけば dotfiles 側の記述を変更せずに済む。
  environment.variables.DOTFILES = config.hostSpec.dotfilesDir;

  system.primaryUser = config.hostSpec.username;
  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  # nix-darwin の現行の最新値（system.maxStateVersion）。
  # 新規導入のため最新値を採用し、以後は変更しない方針。
  system.stateVersion = 7;

  # 既存ホスト名 (mac-mini 等) を変更しないため、networking.hostName は設定しない。
}
