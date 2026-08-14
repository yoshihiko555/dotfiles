{
  description = "Nix flake for dotfiles: devShell (experimental) + nix-darwin/home-manager (Phase 3)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs 未収録だが公式 flake を持つ CLI（PHASE-3-2-CLI-INVENTORY.md）。
    # follows は付けない（takt 側の input 名に依存させず、確実にビルドできる方を優先。
    # closure 最適化は動作確認後に検討する）
    takt.url = "github:nrslib/takt";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 秘匿情報を暗号化したままコミットするための復号基盤（Phase 4-5）。
    # 2026-08-14 時点で sops.secrets を宣言しているホストは無い（管理対象ゼロ）。
    # ~/.ssh/config は中身が秘匿情報でないため平文配線（hosts/macbook/dotfiles.nix）
    # に変更した。将来 API トークン等の本物の秘密が出てきたときに即座に
    # sops.secrets へ載せられるよう、仕組み（この input・.sops.yaml・age 鍵）だけ
    # 先に用意して残している。home-manager 用モジュールのみ使う予定
    # （darwinModules は不採用。理由は docs/ROADMAP.md 4-5 節参照）
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      home-manager,
      takt,
      treefmt-nix,
      sops-nix,
      ...
    }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # `nix fmt` / `nix flake check` 用。CI（ubuntu-latest = x86_64-linux）と
      # 開発機（aarch64-darwin）の両方で formatter/checks が引けるようにする。
      # darwinConfigurations / devShells は既存どおり aarch64-darwin 固定のまま
      formatterSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      eachFormatterSystem = nixpkgs.lib.genAttrs formatterSystems;
      treefmtEval = eachFormatterSystem (
        s: treefmt-nix.lib.evalModule (import nixpkgs { system = s; }) ./treefmt.nix
      );

      # mozumasu/dotfiles の構造を踏襲しつつ、nix-homebrew / sops-nix /
      # overlay 群など依存の多い部分は削ぎ落としている（ADR-20260730-0003）。
      # treefmt-nix は Phase 4-3 で復元済み（./treefmt.nix、上記 treefmtEval）。
      # darwin ホスト共通で読み込むモジュール群。
      # 層の設計（ADR-0004）: darwin/ = darwin 共通システム層、home/ = 全台共通ユーザー層、
      # hosts/<host>/ = ホスト固有（薄く保つ）。WSL2 は darwin/ を通らず home/ を共有する。
      commonModules = [
        ./modules/hostSpec.nix
        ./darwin
        home-manager.darwinModules.home-manager
        (
          { config, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # 既存ファイルとの衝突時に上書きせず *.backup へ退避する。
              # sops-nix の secrets.path はこの保護を経由しない別経路
              # （sops-install-secrets が直接シンボリックリンクを張り替える）ため、
              # 将来 sops.secrets を使うホストが出たら該当ファイルの事前退避が別途必要になる
              backupFileExtension = "backup";
              extraSpecialArgs = {
                hostSpec = config.hostSpec;
              };
              # sops-nix: home-manager 用モジュールのみ全ホスト共通で読み込む。
              # 2026-08-14 時点で sops.secrets を宣言しているホストは無い
              # （管理対象ゼロ。経緯は docs/ROADMAP.md 4-5 節）。宣言が無い限り
              # launchd agent 等は一切生成されない（sops.secrets = {} のため）
              sharedModules = [ sops-nix.homeManagerModules.sops ];
              users.${config.hostSpec.username} = import ./home;
            };
          }
        )
      ];
    in
    {
      # 既存の devShell はそのまま維持（Phase 0 由来。`nix develop` の挙動を壊さない）
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          jq
          ripgrep
        ];
      };

      darwinConfigurations = {
        hermes = darwin.lib.darwinSystem {
          inherit system;
          modules = [ ./hosts/hermes ] ++ commonModules;
        };
        macbook = darwin.lib.darwinSystem {
          inherit system;
          # takt は macbook のみで使うため specialArgs で渡す（hermes へは配らない）
          specialArgs = { inherit takt; };
          modules = [ ./hosts/macbook ] ++ commonModules;
        };
      };

      # `nix fmt`。projectRootFile（.git/config）を上方向へ探索するため、
      # リポジトリ内のどこから呼んでもリポジトリ全体が対象になる
      formatter = eachFormatterSystem (s: treefmtEval.${s}.config.build.wrapper);

      # `nix flake check`。self をコピーした先で完結するため、
      # 実質 config/nix 配下のみが対象（flake.nix のコメント参照）
      checks = eachFormatterSystem (s: {
        formatting = treefmtEval.${s}.config.build.check self;
      });
    };
}
