{ ... }:
{
  # MacBook Pro（メイン開発機）のホスト定義。
  # このファイルは hostSpec と目次（imports）のみ。実体は機能群ごとのファイルに分割:
  #   homebrew.nix — cask 13 個 + brew 残留 formula（棚卸しは PHASE-3-2-BREW-INVENTORY.md）
  #   packages.nix — MBP 固有 CLI（棚卸しは PHASE-3-2-CLI-INVENTORY.md）
  #   dotfiles.nix — MBP 固有の設定配線と、アプリが書き込む設定の drift 保護
  imports = [
    ./homebrew.nix
    ./packages.nix
    ./dotfiles.nix
  ];

  hostSpec = {
    hostName = "macbook";
    username = "yoshihiko";
    dotfilesDir = "/Users/yoshihiko/ghq/github.com/yoshihiko555/dotfiles";
  };
}
