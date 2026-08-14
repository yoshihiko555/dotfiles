# ============================================
# Nix / nix-darwin
# ============================================
# flake は dotfiles 配下、ホスト定義は hermes / macbook（Phase 3-2 で MBP 追加）。
# hermes の dotfiles は ghq root が標準と違うため、リモート用は固定パスで持つ。

NIX_FLAKE="$DOTFILES/config/nix"
NIX_HERMES_DOTFILES="/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles"

# nx* 系の対象ホストをユーザー名で自動判定する。
# hermes はリポジトリ所有者が agent ユーザーという設計（Phase 3-1）のため、
# ホスト名より whoami の方が判定として安定する
if [ "$(whoami)" = "agent" ]; then
  NIX_HOST="hermes"
else
  NIX_HOST="macbook"
fi

# darwin-rebuild build は --out-link を持たず cwd に result を作るため、
# repo を汚さないよう専用ディレクトリで実行する
NIX_BUILD_DIR="/tmp/nix-build-hermes"

# --------------------------------------------
# ローカル（hermes 上で実行する）
# --------------------------------------------
# 適用せずビルドのみ。sudo 不要なので安全に構文・依存を検証できる
nxb() {
  mkdir -p "$NIX_BUILD_DIR" \
    && (cd "$NIX_BUILD_DIR" && darwin-rebuild build --flake "$NIX_FLAKE#$NIX_HOST")
}

# 現行世代とビルド結果の差分（nvd 相当。Nix 標準機能）
nxd() {
  nix store diff-closures /run/current-system "$NIX_BUILD_DIR/result"
}

# build → diff。適用前の確認はこれ一本で足りる
nxbd() {
  nxb && nxd
}

# flake input（nixpkgs / takt 等）のピンを進める。実行後は nxbd で差分確認 → nxs
nxu() {
  (cd "$NIX_FLAKE" && nix flake update)
}

# 適用。sudo が要る（hermes では admin ユーザーで実行すること）
alias nxs='sudo darwin-rebuild switch --flake "$NIX_FLAKE#$NIX_HOST"'

alias nxg='sudo darwin-rebuild --list-generations'
alias nxrb='sudo darwin-rebuild switch --rollback'

# --------------------------------------------
# hermes リモート（MBP から実行する）
# --------------------------------------------
# SSH 先は AGENTS.md の規約に従う:
#   macmini-agent … 通常作業（macmini-hermes は hermes-ui 専用なので使わない）
#   macmini-admin … sudo が要る操作のみ

# hermes 上で build → diff を実行する本体（pull はしない）
_hx_build_diff() {
  ssh macmini-agent "mkdir -p '$NIX_BUILD_DIR' \
    && cd '$NIX_BUILD_DIR' \
    && darwin-rebuild build --flake '$NIX_HERMES_DOTFILES/config/nix#hermes' \
    && nix store diff-closures /run/current-system '$NIX_BUILD_DIR/result'"
}

# hermes の dotfiles を main に追従させる
hxp() {
  ssh macmini-agent "cd '$NIX_HERMES_DOTFILES' && git pull --ff-only"
}

# pull せず、hermes の「今の宣言」と実機の差分を見る
hxd() {
  _hx_build_diff
}

# pull → build → diff。適用はしないので確認用途に安全
hxb() {
  hxp && _hx_build_diff
}

# 適用。admin 経由 + sudo パスワード入力があるため -t で TTY を割り当てる
hxs() {
  ssh -t macmini-admin \
    "sudo darwin-rebuild switch --flake '$NIX_HERMES_DOTFILES/config/nix#hermes'"
}

hxg() {
  ssh -t macmini-admin 'sudo darwin-rebuild --list-generations'
}

hxrb() {
  ssh -t macmini-admin 'sudo darwin-rebuild switch --rollback'
}
