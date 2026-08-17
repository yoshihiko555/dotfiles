{ ... }:
{
  # hermes（M4 Mac mini, ヘッドレス）のホスト定義。
  # このファイルは hostSpec と目次（imports）のみ。実体は機能群ごとのファイルに分割:
  #   homebrew.nix     — cask 宣言
  #   dotfiles.nix     — hermes 固有の配線（tmux / mise / zshrc.local）
  #   hermes-agent.nix — Hermes Agent 基盤（LLM launchd / gh 対策）
  #   nix-gc.nix       — Nix store の自動 GC（常時稼働機向け）
  #   security.nix     — loginwindow / screensaver / Application Firewall（Phase 4-8）
  imports = [
    ./homebrew.nix
    ./dotfiles.nix
    ./hermes-agent.nix
    ./nix-gc.nix
    ./security.nix
  ];

  hostSpec = {
    hostName = "hermes";
    username = "agent";
    homeDirectory = "/Users/agent";
    dotfilesDir = "/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles";
  };
}
