{ config, pkgs, lib, takt, ... }:
{
  # MBP 固有の CLI パッケージ（棚卸し: PHASE-3-2-CLI-INVENTORY.md）。
  # ADR-0004 ルール 3 に従い、まず使うホストの hosts/macbook/ に置く。
  # hermes でも使い始めたら home/packages.nix（共通層）へ昇格する。

  # agy（antigravity-cli）は unfree ライセンスのため個別に許可する。
  # allowUnfree = true の全面許可はせず、対象を明示する。
  nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "antigravity-cli" ];

  home-manager.users.${config.hostSpec.username}.home.packages =
    (with pkgs; [
      # --- brew から移行（2026-08-02 棚卸しで nix新規 と判定）---
      go-task # タスクランナー統一の決定（Makefile は stow と同時期に廃止）
      gopls
      opencode
      pyright
      sheldon
      stow # 経過措置。home-manager 移行完了後に削除する
      switchaudio-osx
      tree-sitter # brew の tree-sitter-cli 相当（CLI 同梱。nvim-treesitter の grammar ビルド用）
      typescript
      typescript-language-server

      # --- 野良インストールから移行（宣言なし 9 件の解消）---
      antigravity-cli # agy。公式 curl インストーラ → nixpkgs へ（要 allowUnfree、上記）
      golangci-lint # mise から移送（境界違反の解消）
      google-clasp # npm -g から移行
      mcp-proxy # uv tool から移行
      sandbox-runtime # npm -g（@anthropic-ai/sandbox-runtime）から移行
    ])
    ++ [
      # nixpkgs 未収録だが公式 flake あり（npm -g から移行）
      takt.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
