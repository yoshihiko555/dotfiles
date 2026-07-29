# Nix 移行ロードマップ

dotfiles を段階的に Nix 管理へ寄せていくための計画。
Nix の学習度合いに合わせて、小さく動かしながら進める。

最終像は mozumasu 型（nix-darwin + home-manager で宣言的にマシンごと管理）。
ただし学習コストが高いので、**手前のフェーズで手を止めて常用していける**ことを重視する。

---

## 前提: 管理対象ホスト（2026-07-29 改訂）

| ホスト | system | 用途 | Nix の適用範囲 |
|---|---|---|---|
| MacBook Pro | `aarch64-darwin` | メイン開発機 | CLI + dotfiles（GUI / cask は brew のまま） |
| Mac mini (hermes, M4) | `aarch64-darwin` | Hermes Agent 運用、ターミナルのみ | ほぼ全体 |
| 会社支給 Windows | `x86_64-linux` | WSL2 上で日常開発 | **WSL2 内部のみ**（Windows 本体は対象外） |

初版の ROADMAP は単一 macOS 端末を暗黙の前提にしていたため Phase 0 で停滞した。
3 台構成が判明したことで判断が変わっている。経緯は
[ADR-20260729-0002](adr/ADR-20260729-0002-multi-host-adoption.md) を参照。

---

## Phase 0: 基盤セットアップ（完了 / 2026-04-24）

- `config/.config/nix/` にディレクトリ集約（stow 経由で `~/.config/nix/` にリンク）
- `flake.nix`（最小の devShell 定義）
- `nix.conf` で `experimental-features = nix-command flakes` を有効化
- `shell/.zprofile` で login shell でも Nix を初期化
- ドキュメント（本 ROADMAP / ADR）を `docs/` 配下に整備

**完了条件**: `nix develop ~/.config/nix` でサンドボックス shell が起動する。→ 達成済み

---

## Phase 1: CLI ツール単体を nix profile で試す（**スキップ**）

> **2026-07-29 判断: スキップする。**
> このフェーズの目的は「Nix が手元のツール管理に組み込まれる感覚を掴む」ことだったが、
> 候補ツールはいずれも brew で導入でき、実利がなく学習目的にとどまる。
> Phase 3（home-manager）で同じ学習が実務と同時に得られるため、通過する必要がない。
> 以下は当初の計画として記録のため残す。

brew と重複しない（または併存で問題ない）ツールを 1〜2 個だけ `nix profile install` で常用に回す。
目的は **「Nix が手元のツール管理に組み込まれる感覚」を掴むこと**。パッケージ管理の置き換えではない。

候補:

- `fd`（未導入）
- `bat`（未導入）
- `eza`（未導入）
- `dust` / `procs`（未導入）

**当初の完了条件**: 1 個以上のツールが `nix profile list` に乗り、日常的に使えている。

---

## Phase 2: プロジェクト用 devShell を拡張（任意 / 必要になった時点で）

`flake.nix` の `outputs.devShells` を増やし、プロジェクト別の開発環境を Nix で再現する。

想定:

- 言語別 devShell（Go / Node / Python など必要に応じて）
- 既存の `minimal` devShell は残しつつ、実プロジェクトで `nix develop` を常用

**位置づけ**: Phase 3 の前提ではない。ランタイム管理は当面 mise が担当するため、
mise で賄えないツール（protoc / terraform / LSP 群など）のバージョン差異が
プロジェクト間で問題になった時点で着手する。

**完了条件**: 実プロジェクトの 1 つ以上で mise や brew を介さず `nix develop` で立ち上がる。

---

## Phase 3: home-manager でマルチホスト管理（**現在地 / 次の着手対象**）

3 ホストを 1 つの flake で宣言的に管理する。共通部分とホスト固有部分を分離し、
`scripts/install-hermes-subset.sh` による手動コピーを置き換える。

目標構成:

```
config/.config/nix/
├── flake.nix
├── hosts/          # macbook.nix / hermes.nix / wsl.nix
├── home/           # common.nix / darwin.nix / linux.nix
└── modules/
```

`shared/agents/` の core + diff と同じ構造。

### Phase 3-1: WSL2（最初の着手対象）

会社 PC の WSL2 に Nix + home-manager を導入する。
既存ディストロに追加する形をとる（NixOS-WSL への置き換えは会社ツールを壊すリスクがあるため採らない）。

- Linux はバイナリキャッシュのカバレッジが完全で、macOS 固有の SDK 問題が起きない
- 壊しても `wsl --unregister` で作り直せるため、学習の実験場として最適

**詳細な作業計画・設計**: [PHASE-3-1-WSL2.md](PHASE-3-1-WSL2.md)

**着手前の前提作業**: `shell/.zshrc` の移植阻害要因（`command -v` ガード欠落、
絶対パスのハードコード、BSD 依存）の修正。詳細は上記の作業計画を参照。

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。

### Phase 3-2: hermes

`common.nix` の範囲を確定させ、Mac mini を home-manager 管理へ移す。

**完了条件**: `install-hermes-subset.sh` を使わずに hermes の環境が再現できる。

### Phase 3-3: MacBook Pro

最後。既に動いている環境のため最もリスクが高く、得るものが少ない。
GUI / cask は brew のまま残す。

**完了条件**: メイン機の CLI + dotfiles が home-manager 管理下に入り、
brew は GUI / cask 専用になる。

---

## Phase 4: nix-darwin 移行（長期 / 未判断）

システム設定（Dock / Finder / キーボード等）まで宣言的に管理。
mozumasu 形式（`hosts/` + `darwin/` + `home-manager/` + `modules/`）へ構造を拡張する。

`homebrew.*` モジュールによる `brew bundle` の宣言化もこの段階で判断する。

**完了条件**: `darwin-rebuild switch --flake ~/.config/nix` で全システム設定が再現できる。

---

## 既存ツールとの共存方針

| ツール | 方針 |
|---|---|
| stow | 段階的に home-manager へ寄せる（ファイル単位で移行可能） |
| mise | 残す。境界は「言語ランタイム = mise、それ以外の CLI = Nix」 |
| brew | GUI / cask は残す。Phase 4 で改めて判断 |

---

## 進行ルール

- Phase は原則 **順番に**進める。ただし **前提が変わった場合は ROADMAP ごと見直す**
  （2026-07-29 に 3 台構成が判明し、Phase 1 のスキップを決定した実績あり）
- 各 Phase の中で「採用 / 不採用 / 保留」の判断が出たら **ADR を書く**
- 学習が追いつかない場合は、その Phase に**無期限で滞留してよい**
- ROADMAP は学習状況に応じて随時更新（固定計画ではない）
