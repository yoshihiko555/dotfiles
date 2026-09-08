{ pkgs, hostSpec, ... }:
let
  # takt / Ink の同期描画中に全画面消去だけが端末へ先行する問題の暫定修正。
  # 実機で調査した MacBook に限定する。検証・撤回手順は patches/README.md。
  tmuxPackage =
    if hostSpec.hostName == "macbook" then
      pkgs.tmux.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/tmux-sync-clear.patch ];
      })
    else
      pkgs.tmux;
in
{
  # 3 台共通の CLI パッケージ。
  # 方針（ROADMAP「既存ツールとの共存方針」）に従い、nixpkgs 収録の CLI は
  # brew ではなく Nix で管理する（2026-08-01 に homebrew.brews から移行）。
  # brew に残るのは nixpkgs 未収録のもの（git-gtr 等）と cask、および
  # Hermes Agent の LLM 基盤（llama.cpp / llama-swap / miniserve。
  # 絶対パス参照の調査が済むまで brew 残留、hosts/hermes 参照）。
  # 言語ランタイムは mise の担当（mise 本体はここで導入する）。
  home.packages = with pkgs; [
    d2
    fd
    fzf
    gh
    ghq
    git
    glow
    lazygit
    mise
    neovim
    ripgrep
    starship
    tmuxPackage
    tree
    tree-sitter # nvim-treesitter（main branch）の grammar ビルドに必須。brew の tree-sitter-cli 相当
    yazi
    zoxide
  ];
}
