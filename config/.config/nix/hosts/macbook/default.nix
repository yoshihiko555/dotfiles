{ ... }:
{
  # MacBook Pro（メイン開発機）のホスト定義。
  # このファイルは hostSpec と目次（imports）のみ。実体は機能群ごとのファイルに分割:
  #   homebrew.nix — cask 13 個 + brew 残留 formula（棚卸しは PHASE-3-2-BREW-INVENTORY.md）
  #   packages.nix — MBP 固有 CLI（棚卸しは PHASE-3-2-CLI-INVENTORY.md）
  # dotfiles の配線は共通層 home/dotfiles.nix のみで開始し、stow からの段階移行
  # （ROADMAP Phase 3-2 の安全な移行順序 2）に合わせて dotfiles.nix を後日追加する。
  imports = [
    ./homebrew.nix
    ./packages.nix
  ];

  hostSpec = {
    hostName = "macbook";
    username = "yoshihiko";
    dotfilesDir = "/Users/yoshihiko/ghq/github.com/yoshihiko555/dotfiles";
  };
}
