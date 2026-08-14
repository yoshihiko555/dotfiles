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
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      home-manager,
      takt,
      treefmt-nix,
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
              # 既存ファイルとの衝突時に上書きせず *.backup へ退避する
              backupFileExtension = "backup";
              extraSpecialArgs = {
                hostSpec = config.hostSpec;
              };
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
