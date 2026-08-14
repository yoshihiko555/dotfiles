# Nix 設定

dotfiles 配下の nix-darwin + home-manager エントリポイント。
`~/.config/nix/` 自体も home-manager でリポジトリへ配線される。

**nix-darwin + home-manager** で 3 台を宣言的に管理する。
このファイルは「**どう管理しているか**」を書く場所とし、移行の進捗・完了状態は
[docs/ROADMAP.md](docs/ROADMAP.md) を正とする。

## 管理対象ホスト

| ホスト | system | flake の出力 | Nix の適用範囲 |
|---|---|---|---|
| MacBook Pro | `aarch64-darwin` | `darwinConfigurations.macbook` | CLI + dotfiles + cask（宣言管理） |
| Mac mini (hermes, M4) | `aarch64-darwin` | `darwinConfigurations.hermes` | ほぼ全体。cask も**宣言管理（7 個）** |
| 会社 Windows (WSL2) | `x86_64-linux` | 未定義（Phase 3-3 で追加予定） | WSL2 内部のみ（Windows 本体は対象外） |

`flake.nix` の `system` は現在 `aarch64-darwin` 固定。WSL2 対応時に
`homeConfigurations`（standalone home-manager）の系統を追加する。

### 目的

1. **環境依存の切り分けを宣言的に表現する**（ヘッドレス機に GUI cask を乗せない等）
2. **新端末で環境を引き継げるようにする**（8 手順 → 1 コマンド）
3. 複数マシンで同一環境を構築する

目的から外したもの: スキル管理の宣言化 / devShell + direnv（mise と重複）/
zsh 起動最適化 / launchd の宣言管理（**hermes のみ例外**でスコープ入り）。
判断の経緯は [ROADMAP](docs/ROADMAP.md) を参照。

## ディレクトリ構成

3 層構成（`darwin/` / `home/` / `hosts/`）は [ADR-0004](docs/adr/ADR-20260801-0004-module-layer-design.md) で確定。

```
config/nix/
├── flake.nix               # エントリポイント。inputs（nixpkgs / darwin / home-manager / takt）と
│                           # darwinConfigurations.{macbook,hermes} を定義
├── flake.lock              # 入力のバージョン固定（更新は nix flake update <input>）
├── nix.conf                # ユーザーレベルの nix 設定（→ ~/.config/nix/nix.conf）
│                           # ブートストラップ時と darwin 層を通らないホスト向け
│
├── darwin/                 # ★ darwin 共通システム層（全 Mac 共通。WSL2 は通らない）
│   ├── default.nix         #   nix 本体設定（nix.settings）・システム既定値
│   └── homebrew.nix        #   brew の共通宣言（cleanup = "zap"）
│
├── home/                   # ★ 全台共通ユーザー層（home-manager）
│   ├── default.nix         #   目次
│   ├── dotfiles.nix        #   共通 dotfiles の配線（zsh / git / tmux / mise / nvim / starship）
│   └── packages.nix        #   nixpkgs 収録 CLI（全台共通）
│
├── hosts/                  # ★ ホスト固有層（薄く保つ）
│   ├── macbook/
│   │   ├── default.nix     #   hostSpec + imports の目次
│   │   ├── dotfiles.nix    #   MBP 固有の配線 + mutable 設定の activation（後述）
│   │   ├── homebrew.nix    #   cask（GUI）
│   │   └── packages.nix    #   MBP 固有 CLI（takt 等）
│   └── hermes/
│       ├── default.nix
│       ├── dotfiles.nix
│       ├── hermes-agent.nix #  LLM 基盤（llama.cpp / llama-swap / miniserve）の launchd 宣言
│       ├── homebrew.nix
│       ├── nix-gc.nix      #   Nix store の自動 GC（週次）
│       ├── llama-swap-config.yaml # hermes-agent.nix が参照する llama-swap 設定
│       └── zshrc.local     #   hermes 固有の zsh 追加設定
│
├── modules/
│   └── hostSpec.nix        # 全ホスト共通のオプション定義（username / dotfilesDir）
│
└── docs/                   # ガイド・チートシート・ROADMAP・ADR
```

将来追加予定の `packages/`（自作パッケージ）・`hosts/wsl/` を含む目標形は
[ROADMAP の「目標構成」](docs/ROADMAP.md)を参照。

## 設定の反映方式

**反映タイミングが 3 系統に分かれる**点に注意する。

| 系統 | 対象 | 仕組み | 反映タイミング |
|---|---|---|---|
| **symlink**（原則） | 大半の dotfiles | `mkOutOfStoreSymlink` で store 経由リポジトリの実体を指す | **repo を編集した時点で即反映**。switch が要るのは配線を増減したときだけ |
| **mutable 実ファイル**（例外） | `~/.claude/settings.json`、Antigravity の `settings.json` / `keybindings.json` の 3 件（`hosts/macbook/dotfiles.nix` で定義） | activation が repo からコピーし、`.nix-managed` の参照コピーも保存 | **switch のときだけ**。drift 検出中は上書きを拒否 |
| **パッケージ** | CLI / cask | `flake.lock` でバージョンを固定 | **switch のときだけ** |

mutable 実ファイル方式は、アプリ本体が atomic write（temp → rename）で
symlink を実ファイルに置換してしまう問題への対処。正は repo 側のまま保つ。

- **drift**（アプリが書き込んで repo と乖離した状態）の検知は 3 箇所のみ:
  ① switch の activation ② Claude Code の Stop hook（`claude/hooks/check-settings-drift.sh`）
  ③ `task status`
- 判定は `jq -S` で正規化してから比較するため、キー順の入れ替えは drift 扱いにしない
- 回収は `task adopt-settings TARGET=claude|antigravity-settings|antigravity-keybindings|all`。
  home 側の内容を repo へ取り込み、`git diff` で確認してから commit → switch

> **ロールバック（`nxrb`）が戻すのはパッケージと配線だけ。**
> symlink 先も activation の参照元も `dotfilesDir` の生パスであり store のスナップショットではないため、
> 旧世代を activate しても設定の中身は「現在の repo の内容」になる。
> 設定内容の巻き戻しは git、パッケージの巻き戻しは `nxrb` と使い分ける。

## 運用規約（正式決定事項の一覧）

決定の経緯・理由は各 ADR を参照。ここは「守るルールの一覧」に徹する。

### 構成（[ADR-0004](docs/adr/ADR-20260801-0004-module-layer-design.md)）

- **3 層構成**: `darwin/` = darwin 共通システム層 / `home/` = 全台共通ユーザー層 /
  `hosts/<host>/` = ホスト固有（**薄く保つ**）。WSL2 は darwin 層を通らない
- `hosts/<host>/` は「hostSpec + 目次の default.nix + 機能群ファイル」。
  機能の増築は**新ファイル + imports に 1 行**
- **2 台以上で使い始めたら共通層へ昇格**。新規はまず使うホストの hosts/ に書く

### 方式（[ADR-0003](docs/adr/ADR-20260730-0003-purpose-and-order.md)）

- 原則 **`mkOutOfStoreSymlink`**（編集即反映）。例外は `home.activation` とし、
  **理由コメント必須**
- 設定内容を Nix 言語へ書き直す全面移行（`programs.*`）はしない

### パッケージの置き場

| 種別 | 置き場 |
|---|---|
| nixpkgs 収録の CLI（全台共通） | `home/packages.nix` |
| nixpkgs 収録の CLI（ホスト固有） | `hosts/<host>/packages.nix` |
| nixpkgs 未収録だが公式 flake あり | `flake.nix` の inputs + 対象ホストの packages.nix（例: takt） |
| nixpkgs 未収録の formula | `darwin/homebrew.nix`（共通）/ `hosts/<host>/homebrew.nix`（固有） |
| cask（GUI） | `hosts/<host>/homebrew.nix` |
| 言語ランタイム | mise（Nix では管理しない） |

### 運用

- **brew で直接入れたら必ず宣言にも追加**する（宣言外は次の switch で zap が削除）
- **1 switch = 1 変更クラス**。検証はカテゴリを混ぜず、rollback 可能な単位で
- 反映フロー: 編集 → push → 対象ホストで pull。設定ファイルの中身だけなら pull で完了、
  パッケージ・配線の変更は + switch
- 方針の再議論は「**前提が変わったとき」だけ**。採用/不採用の判断が出たら ADR を書く
- hermes への SSH は `macmini-agent`、管理作業のみ `macmini-admin`（ルート AGENTS.md 参照）

## セットアップ（新しい Mac）

**まっさらな Mac からの初回構築は [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) を参照。**
Xcode Command Line Tools・Homebrew 本体・GitHub 認証・Nix 本体のインストールから
初回 `switch` までを手順化している（hermes で実施・検証済み。nix-darwin 導入は
2026-07-31、素の Nix 系統への移行検証は 2026-08-02。経緯は
[ADR-0005](docs/adr/ADR-20260802-0005-upstream-nix-migration.md) 参照）。

2 回目以降の日常運用は以下。

```sh
sudo darwin-rebuild switch --flake <repo>/config/nix#<host>
```

> **SSH 越しに行う場合**: 「システム設定 → 共有 → リモートログイン →
> リモートユーザーにフルディスクアクセスを許可」を ON にしておく必要がある
> （OFF だと root でも `/etc/fstab` 等の rename が `Operation not permitted` になる）。

## 常用コマンド

```sh
# 最小の devShell に入る
nix develop ~/.config/nix

# flake の入力を更新
nix flake update --flake ~/.config/nix

# インストール済みツール一覧
nix profile list

# hermes の設定を再適用（hermes 上で実行。$DOTFILES は /etc/zshenv 経由で全ユーザーに設定済み。
# sudo の前にシェルが展開するのでそのまま通る）
sudo darwin-rebuild switch --flake "$DOTFILES/config/nix#hermes"
```

日常運用の alias（`nxb` / `nxbd` / `nxs` / `nxrb` 等）と実用コマンド集は
[docs/CHEATSHEET.md](docs/CHEATSHEET.md) にまとめてある。

## トラブルシュート

- `nix` コマンドが見つからない: login shell で `shell/zprofile` の Nix 初期化が走っているか確認
- flake 関連エラー: `~/.config/nix/nix.conf`（home-manager でリンクされるユーザーレベル設定。
  ブートストラップ時や WSL2 など darwin 層を通らないホストで参照される）に
  `experimental-features = nix-command flakes` が入っているか確認。
  nix-darwin 管理下の Mac（hermes 等）ではシステム側の `/etc/nix/nix.conf` は
  `darwin/default.nix` の `nix.settings` が管理するため、両者は別物として扱う

## ドキュメント一覧

- [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) — **まっさらな Mac からの初回構築手順（正典）**
- [docs/GUIDE.md](docs/GUIDE.md) — **設定ファイルの読み方ガイド（学習用）**。どのファイルが何をしていて、nix-darwin / home-manager とどう繋がるか
- [docs/CHEATSHEET.md](docs/CHEATSHEET.md) — **日常運用チートシート**。反映・rollback・パッケージ追加・更新・掃除の実用コマンド集
- [docs/USECASES.md](docs/USECASES.md) — **ユースケースカタログ**。次に何をやるかの判断材料（価値・コスト・向き不向き）
- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画と**現在地**（進捗はこちらが正）
- [docs/PHASE-3-3-WSL2.md](docs/PHASE-3-3-WSL2.md) — WSL2 の作業計画・設計（実稼働待ち）
- [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) — ADR 一覧
