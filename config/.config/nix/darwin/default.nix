{ config, ... }:
{
  # darwin ホスト（hermes / macbook）共通のシステム層。
  # WSL2（standalone home-manager）はこの層を通らない。
  # 3 台共通のユーザー環境は home/ に置く（層の設計は ADR-0004）。
  imports = [ ./homebrew.nix ];

  # Determinate installer が Nix 本体（デーモン・ストア）を管理するため、
  # nix-darwin 側の Nix 管理は無効化する。hermes には Determinate installer で
  # 後から Nix を導入する前提（ADR-20260730-0003 の着手順序）。
  nix.enable = false;

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
