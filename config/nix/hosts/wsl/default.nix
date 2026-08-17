{ ... }:
{
  # WSL2（会社支給 Windows の Ubuntu, x86_64）のホスト定義。
  #
  # darwin 2 台と異なり **standalone home-manager**（flake の homeConfigurations）
  # として構成する。darwin/ 層は通らず home/ 層のみを共有する非対称ホスト
  # （ADR-0004）。hostSpec の値は ./hostSpec.nix、配線は flake.nix 側。
  #
  # 作業計画は docs/PHASE-3-3-WSL2.md。現時点は手順 2（flake へホストを追加）
  # までを済ませた最小構成であり、以下は後続手順で追加する:
  #   packages.nix — home.packages（手順 3。sheldon は共通層に無いため要明示）
  #   dotfiles.nix — mkOutOfStoreSymlink による配線（手順 4）
  #   WSL2 固有     — クリップボード / BROWSER=wsl-open（手順 6）

  # 非 NixOS ディストリ向けの統合。CLI 専用環境では nix.sh の source と
  # terminfo / PATH 統合が実質的な効果になる（XDG_DATA_DIRS / desktop 系は
  # GUI を使わないため影響しない）。
  targets.genericLinux.enable = true;
}
