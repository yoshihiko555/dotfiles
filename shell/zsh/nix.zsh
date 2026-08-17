# ============================================
# Nix / nix-darwin
# ============================================
# flake は dotfiles 配下、ホスト定義は hermes / macbook（Phase 3-2 で MBP 追加）。
# hermes の dotfiles は ghq root が標準と違うため、リモート用は固定パスで持つ。

NIX_FLAKE="$DOTFILES/config/nix"
NIX_HERMES_DOTFILES="/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles"

# --------------------------------------------
# WSL2 / Linux（standalone home-manager）
# --------------------------------------------
# WSL は nix-darwin ではなく standalone home-manager（flake の
# homeConfigurations.wsl）。darwin-rebuild が存在しないため、この分岐では
# nx* 系を home-manager CLI ベースで定義し、以降の darwin 用定義
# （whoami 判定・darwin-rebuild・Homebrew・hermes リモート hx*）へは進まない。
if [ "$(uname -s)" = "Linux" ]; then
  NIX_HOST="wsl"

  # 適用せずビルドのみ。activationPackage を作るだけで sudo 不要。構文・依存の検証用。
  nxb() {
    nix build "$NIX_FLAKE#homeConfigurations.${NIX_HOST}.activationPackage"
  }

  # 適用。standalone は sudo 不要。-b backup で既存ファイル衝突を *.backup へ自動退避する
  #（初回 bootstrap の .zshrc 衝突対策。darwin 側の backupFileExtension に相当）。
  alias nxs='home-manager switch -b backup --flake "$NIX_FLAKE#wsl"'

  # 世代一覧。darwin の nxg（darwin-rebuild --list-generations）に相当。
  alias nxg='home-manager generations'

  # flake input（nixpkgs 等）のピンを進める。OS 非依存なので darwin 側と同一実装。
  # 実行後は nxb で確認 → nxs。戻したいときは
  #   git -C "$DOTFILES" checkout -- config/nix/flake.lock
  nxu() {
    nix flake update --flake "$NIX_FLAKE" "$@"
  }

  return
fi

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
#
# flake.nix は repo 直下ではなく config/nix 配下にあるため、cwd に依存する形
# （素の `nix flake update`）は repo ルートや任意のディレクトリから叩くと
#   error: path "..." is not part of a flake
# で落ちる。--flake で対象を明示して cwd 非依存にしている。
#
# 引数は「更新する input 名」として nix にそのまま渡す（Nix 2.19 以降の仕様。
# 位置引数は flake のパスではなく input 名である点に注意）:
#   nxu            全 input を更新
#   nxu takt       takt だけ更新
#   nxu nixpkgs darwin  複数指定も可
#
# flake.lock は git 管理下なので、戻したいときは
#   git -C "$DOTFILES" checkout -- config/nix/flake.lock
nxu() {
  nix flake update --flake "$NIX_FLAKE" "$@"
}

# 適用。sudo が要る（hermes では admin ユーザーで実行すること）
alias nxs='sudo darwin-rebuild switch --flake "$NIX_FLAKE#$NIX_HOST"'

alias nxg='sudo darwin-rebuild --list-generations'
alias nxrb='sudo darwin-rebuild switch --rollback'

# --------------------------------------------
# Homebrew（nix-darwin 管理下だがバージョン更新は別系統）
# --------------------------------------------
# darwin/homebrew.nix の onActivation.upgrade は既定の false のままなので、
# nxs（switch）で反映されるのは宣言の「追加・削除」だけで、既に入っている
# formula / cask のバージョンは上がらない。更新はこのコマンドで行う。
#
# nix 側と違い brew は build → diff → 適用に分けられず upgrade がそのまま
# 適用になるため、先に brew outdated で対象を見せて確認を取る。
#
# 注意: 自動更新を持つ cask（claude-code@latest, wezterm@nightly 等）は
# 既定でスキップされる。強制したい場合のみ `brew upgrade --greedy` を手で叩く
# （アプリ側の自動更新と競合しうるので既定には入れない）。
bxu() {
  brew update || return 1

  local outdated
  outdated="$(brew outdated --verbose)"
  if [ -z "$outdated" ]; then
    echo '更新対象はありません'
    return 0
  fi

  echo
  echo '── 更新対象 ──'
  echo "$outdated"
  echo

  local reply
  printf 'upgrade しますか？ [y/N]: '
  read -r reply
  case "$reply" in
    [yY] | [yY][eE][sS]) brew upgrade ;;
    *) echo 'キャンセルしました' ;;
  esac
}

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
