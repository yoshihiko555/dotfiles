# Nix 移行ロードマップ

dotfiles を段階的に Nix 管理へ寄せていくための計画。
Nix の学習度合いに合わせて、小さく動かしながら進める。

最終像は mozumasu 型（nix-darwin + home-manager で宣言的にマシンごと管理）。
ただし学習コストが高いので、**手前のフェーズで手を止めて常用していける**ことを重視する。

---

## Phase 0: 基盤セットアップ（現在地）

- `config/.config/nix/` にディレクトリ集約（stow 経由で `~/.config/nix/` にリンク）
- `flake.nix`（最小の devShell 定義）
- `nix.conf` で `experimental-features = nix-command flakes` を有効化
- `shell/.zprofile` で login shell でも Nix を初期化
- ドキュメント（本 ROADMAP / ADR）を `docs/` 配下に整備

**完了条件**: `nix develop ~/.config/nix` でサンドボックス shell が起動する。

---

## Phase 1: CLI ツール単体を nix profile で試す

brew と重複しない（または併存で問題ない）ツールを 1〜2 個だけ `nix profile install` で常用に回す。
目的は **「Nix が手元のツール管理に組み込まれる感覚」を掴むこと**。パッケージ管理の置き換えではない。

候補:

- `fd`（未導入）
- `bat`（未導入）
- `eza`（未導入）
- `dust` / `procs`（未導入）

**完了条件**: 1 個以上のツールが `nix profile list` に乗り、日常的に使えている。

---

## Phase 2: プロジェクト用 devShell を拡張

`flake.nix` の `outputs.devShells` を増やし、プロジェクト別の開発環境を Nix で再現する。
この段階で flake が「自分の開発ワークフローに組み込まれた」状態になる。

想定:

- 言語別 devShell（Go / Node / Python など必要に応じて）
- 既存の `minimal` devShell は残しつつ、実プロジェクトで `nix develop` を常用

**完了条件**: 実プロジェクトの 1 つ以上で mise や brew を介さず `nix develop` で立ち上がる。

---

## Phase 3: home-manager 導入検討

ここから宣言的管理へ踏み込む。`programs.zsh` / `programs.starship` / `programs.git` など、
現状 stow + 手動で管理している dotfiles を home-manager 側に寄せる検討を開始。

スコープ判断の軸:

- 宣言化のメリット（再現性・マルチマシン対応）が、学習コストと管理の二重化を上回るか
- 既存 stow 配線を壊さない移行経路があるか（段階的に programs ごとに寄せる）

**完了条件**: home-manager の導入可否を ADR で判断する。採用する場合は 1 プログラム分の移行を完了。

---

## Phase 4: nix-darwin 移行（長期）

システム設定（Dock / Finder / キーボード等）まで宣言的に管理。
mozumasu 形式（`hosts/` + `darwin/` + `home-manager/` + `modules/`）へ構造を拡張する。

**完了条件**: `darwin-rebuild switch --flake ~/.config/nix` で全システム設定が再現できる。

---

## 進行ルール

- Phase は **順番に**進める（Phase 1 をスキップして Phase 3 には行かない）
- 各 Phase の中で「採用 / 不採用 / 保留」の判断が出たら **ADR を書く**
- 学習が追いつかない場合は、その Phase に**無期限で滞留してよい**
- ROADMAP は学習状況に応じて随時更新（固定計画ではない）
