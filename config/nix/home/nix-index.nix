{ ... }:
{
  # comma（`, <command>`）+ nix-index。未インストールの CLI を
  # インストールせず即実行する（ROADMAP 4-2）。
  #
  # モジュール本体（nix-index-database.homeModules.nix-index）の配線は
  # flake.nix 側（darwin 2 台は commonModules の sharedModules、wsl は
  # homeConfigurations.wsl の modules）。ここではオプションのみ設定する。
  #
  # DB はローカルで nix-index を回すと数十分かかるため、nix-community が
  # 週次でビルド・公開している DB（nix-index-database input）を使う。
  # 定期更新は手動運用ではなく「flake.lock 更新時に input の rev が上がり
  # 新しい DB が入る」仕組み（`nix flake update` / `nix flake lock` で追従）。
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
