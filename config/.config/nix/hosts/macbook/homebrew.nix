{ lib, ... }:
{
  # ROADMAP Phase 3-2「安全な移行順序」ルール 1:
  # 初回 switch は zap の自動削除を無効化した状態で全宣言の動作を確認する。
  # 宣言が実機で証明されたら（ルール 3）この mkForce を外して darwin/ 共通層の
  # "zap" に戻す。外し忘れると宣言と実態のズレを検知できないので注意。
  homebrew.onActivation.cleanup = lib.mkForce "none";

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
    "morantron/tmux-fingers/tmux-fingers"
  ];

  # GUI cask 13 個（2026-08-02 棚卸しで全件継続と判断。personal/work 分離は不採用）
  homebrew.casks = [
    "1password-cli"
    "aerospace"
    "claude-code@latest"
    "cmux"
    "codex"
    "codexbar"
    "easydict"
    "font-udev-gothic-nf"
    "ghostty"
    "orbstack"
    "proxy-audio-device"
    "wezterm@nightly"
    "zed"
  ];
}
