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
  };

  outputs = { nixpkgs, darwin, home-manager, takt, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # mozumasu/dotfiles の構造を踏襲しつつ、nix-homebrew / sops-nix / treefmt-nix /
      # overlay 群など依存の多い部分は削ぎ落としている（ADR-20260730-0003）。
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
              # 既存ファイル（stow 由来等）との衝突時に上書きせず *.backup へ退避する
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
    };
}
