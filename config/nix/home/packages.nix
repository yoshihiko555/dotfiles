{ pkgs, ... }:
{
  # 3 台共通の CLI パッケージ。
  # 方針（ROADMAP「既存ツールとの共存方針」）に従い、nixpkgs 収録の CLI は
  # brew ではなく Nix で管理する（2026-08-01 に homebrew.brews から移行）。
  # brew に残るのは nixpkgs 未収録のもの（git-gtr 等）と cask、および
  # Hermes Agent の LLM 基盤（llama.cpp / llama-swap / miniserve。
  # 絶対パス参照の調査が済むまで brew 残留、hosts/hermes 参照）。
  # 言語ランタイムは mise の担当（mise 本体はここで導入する）。
  home.packages = with pkgs; [
    age
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
    sops
    starship
    tmux
    tree
    yazi
    zoxide
  ];
}
