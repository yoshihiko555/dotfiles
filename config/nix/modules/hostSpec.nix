{ lib, ... }:
{
  # ホストごとに異なる値を宣言するためのオプション定義。
  # mozumasu/dotfiles の hostSpec.nix を簡略化したもの。
  # isWork / enableGUI 等は Phase 3-1 時点では不要なため定義しない。
  # 複数ホストで用途分岐が必要になった時点（Phase 3-2 以降）で追加する。
  options.hostSpec = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = "ホスト名";
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "ログインユーザー名";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      description = ''
        ホームディレクトリの絶対パス。
        macOS は `/Users/<user>`、Linux（WSL2）は `/home/<user>` と規約が異なるため、
        共通層（home/default.nix）でハードコードせずここで宣言する。
        dotfilesDir と同様、デフォルト値を持たせず各ホストで必ず指定する。
      '';
    };

    dotfilesDir = lib.mkOption {
      type = lib.types.str;
      description = ''
        ホスト上の dotfiles リポジトリの絶対パス。
        ghq root（ホームディレクトリ含む）がホストごとに異なるため、
        デフォルト値を持たせず各ホストで必ず指定する。
      '';
    };
  };
}
