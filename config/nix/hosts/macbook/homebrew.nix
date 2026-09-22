{ ... }:
{
  # ROADMAP Phase 3-2「安全な移行順序」ルール 3（2026-08-06 実施）:
  # cleanup の mkForce "none" を撤去し、darwin/ 共通層の "zap" に復帰。
  # 宣言外 formula は switch のたびに自動削除される。

  homebrew.taps = [
    "coderabbitai/tap" # git-gtr
    "morantron/tmux-fingers" # tmux-fingers
    "nikitabobko/tap" # aerospace
    "yoshihiko555/nudge" # 自作 tap（nudge cask 本体は未導入だが残す判断、2026-08-02）
  ];

  # nixpkgs 未収録 or 追従が遅く brew に残す formula（PHASE-3-2-BREW-INVENTORY.md）
  homebrew.brews = [
    "agent-browser" # nixpkgs 版はバージョン追従が遅い（AI 系は brew 残留方針）
    "cliproxyapi" # nixpkgs 未収録（自前 API プロキシ、launchd 常駐）
    "coderabbitai/tap/git-gtr" # hermes 未使用のため darwin 共通層から降格（2026-08-02）
    # hunk: エージェントが書いた変更セットをまとめて読むための review-first diff TUI。
    # 試用中（2026-09-23〜）。nixpkgs は 0.20.1 で brew（0.22.0）より追従が遅いため
    # AI 系 brew 残留方針に従う。見送る場合はこの行を消せば次の switch で消える。
    "hunk"
    "morantron/tmux-fingers/tmux-fingers"
  ];

  # GUI cask 12 個（2026-08-02 棚卸しで全件継続と判断。personal/work 分離は不採用）
  # 2026-09-09: cmux をアンインストールしたため宣言を撤去（zap で再導入されないように）
  homebrew.casks = [
    "1password-cli"
    "aerospace"
    "claude-code@latest"
    "codex"
    "codexbar"
    "easydict"
    "font-udev-gothic-nf"
    "ghostty"
    "orbstack"
    "proxy-audio-device"
    # terminal-browser: Chromium を Kitty graphics でペインに描くブラウザ。試用中
    # （2026-09-23〜）。herdr 内での描画可否を検証する目的で、宣言が無いと zap で
    # switch のたびに消えるためここに置く。見送る場合はこの行を消し、
    # config/herdr/config.toml の [experimental] セクションも併せて削除する。
    "terminal-browser"
    "wezterm@nightly"
    "zed"
  ];
}
