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
  };

  outputs = { nixpkgs, darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };

      # 3 ホスト共通で読み込むモジュール群。
      # mozumasu/dotfiles の構造を踏襲しつつ、nix-homebrew / sops-nix / treefmt-nix /
      # overlay 群など依存の多い部分は削ぎ落としている（ADR-20260730-0003）。
      commonModules = [
        ./modules/hostSpec.nix
        ./hosts/common
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
      };
    };
}
