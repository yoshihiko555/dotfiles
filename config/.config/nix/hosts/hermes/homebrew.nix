{ ... }:
{
  # LLM 基盤は 2026-08-01 に nixpkgs へ移行済み（hermes-agent.nix）。
  # brew に残る hermes 固有 formula は現状なし。
  homebrew.brews = [ ];

  # ヘッドレス運用だが、たまに GUI で使う実態があるため cask も宣言管理する。
  # 「cask を1つも書かない」という当初方針（ADR-0003）は 2026-07-30 のユーザー判断で
  # 撤回した（実態に合わないため）。
  homebrew.casks = [
    "1password"
    "1password-cli"
    "codex"
    "ghostty"
    "google-chrome"
    "orbstack"
    "zed"
  ];
}
