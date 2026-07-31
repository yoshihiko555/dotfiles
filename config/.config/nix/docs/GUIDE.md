# Nix 設定ファイルの読み方ガイド（学習用）

このリポジトリの Nix 設定が「どのファイルが何をしていて、どう繋がっているか」を
Nix 初学者向けに解説する。Phase 3-1（hermes 構築、2026-07-31）時点の構成が題材。

---

## 1. 登場する3つの仕組みと役割分担

| 仕組み | 担当領域 | たとえるなら |
|---|---|---|
| **Nix 本体 + nixpkgs** | パッケージの取得と「宣言 → 実体化」のエンジン。成果物はすべて `/nix/store` に置かれる | ビルドエンジン + 巨大なアプリカタログ |
| **nix-darwin** | macOS の**システム層**の宣言管理。`/etc` のシェル設定、launchd、Homebrew の宣言（brews/casks）、OS 設定 | マシン全体の設定書 |
| **home-manager** | **ユーザーのホーム配下**の宣言管理。`~/.zshrc` や `~/.config/*` の symlink 配線 | stow の宣言版 |

要するに:

```
nix-darwin      = マシンに1つ（/etc、brew、launchd …）      ← sudo が要る世界
home-manager    = ユーザーごと（~/.zshrc、~/.config/* …）    ← sudo 不要の世界
```

当リポジトリでは home-manager を**単体では動かさず、nix-darwin の1モジュールとして
内蔵**している。だから `darwin-rebuild switch` 一発で両方が適用される。

---

## 2. ファイルマップ（このリポジトリの実物）

```
config/.config/nix/
├── flake.nix              # 入口。材料（inputs）と成果物（outputs）の宣言
├── flake.lock             # 材料のバージョン固定（git の lock ファイルと同じ発想）
├── modules/
│   └── hostSpec.nix       # 「ホストごとに違う値」を受け渡すための自作オプション定義
├── hosts/
│   ├── common/
│   │   ├── default.nix    # 全ホスト共通のシステム設定
│   │   └── homebrew.nix   # 全ホスト共通の brew 宣言（+ zap 設定）
│   └── hermes/
│       ├── default.nix    # hermes 固有: hostSpec の値、固有 brew/cask、固有リンク
│       └── zshrc.local    # hermes 固有の zsh 設定（Nix 言語ではなく普通の zsh ファイル）
└── home/
    ├── default.nix        # home-manager の入口（ユーザー名・stateVersion）
    └── dotfiles.nix       # 3台共通の dotfiles symlink 配線
```

### flake.nix — すべての入口

flake は「このディレクトリを1つのパッケージのように扱う」ための仕組み。
2つのセクションだけ押さえればよい:

- **inputs（材料）**: 外部リポジトリへの依存。当リポジトリは3つだけ
  - `nixpkgs` … パッケージカタログ
  - `darwin`（nix-darwin） … macOS システム管理
  - `home-manager` … ホーム配下の管理
- **outputs（成果物）**: 材料から何を作るかの定義
  - `devShells.…` … Phase 0 から残している実験用シェル（`nix develop`）
  - `darwinConfigurations.hermes` … **hermes というマシン1台分の完全な構成**。
    `darwin-rebuild switch --flake .#hermes` の `#hermes` はこれを指している

`flake.lock` は inputs の「あの日のバージョン」を記録する。これがあるから
別マシン・別日でも同じ結果になる（再現性の担保）。

### modules/hostSpec.nix — ホスト差分の受け渡し口

「ホスト名」「ユーザー名」「dotfiles リポジトリの絶対パス」という
**ホストごとに違う3つの値**を宣言できるオプションを自作している。

なぜ必要か: `hosts/common/` の共通設定は「ユーザー名」等を知らないと書けないが、
ハードコードすると共通にならない。そこで各ホスト（`hosts/hermes/default.nix`）が
`hostSpec = { username = "agent"; … }` と値を入れ、共通側は
`config.hostSpec.username` として参照する。**関数の引数のようなもの**と思えばよい。

### hosts/common/ — 全ホスト共通のシステム層

- `default.nix`: Determinate が Nix 本体を管理するので `nix.enable = false`、
  zsh の PATH 配線（`programs.zsh.enable`）、`$DOTFILES` 環境変数の注入、
  ユーザー定義、`system.stateVersion`
- `homebrew.nix`: 共通 CLI 15 個の brew 宣言と、**`cleanup = "zap"`**
  （宣言に無いパッケージを switch のたびに自動削除 = 腐敗の構造的防止。
  この1行が nix-darwin を最初から使う理由。ADR-0003 参照）

### hosts/hermes/ — hermes だけの事情

- `default.nix`:
  - `hostSpec` の値（hermes の正体はここで決まる）
  - hermes 固有 brew（fd/ripgrep + LLM 基盤の llama.cpp 等）と cask 7 個
  - hermes だけに配る symlink（ミニマル tmux.conf、mise、zshrc.local）
- `zshrc.local`: Hermes Agent 運用 alias（`hms` 等）。**Nix 言語に書き直さず
  普通の zsh ファイルのまま**置き、symlink で配るのが当リポジトリの方針

### home/ — ユーザーのホーム配下（3台共通）

- `default.nix`: ユーザー名などの枠組み
- `dotfiles.nix`: 本丸。`mkOutOfStoreSymlink` で
  `~/.zshrc → <リポジトリ>/shell/.zshrc` のような symlink を宣言する。
  **stow がやっていたことの home-manager 版**。リポジトリ側を編集すれば即反映される

---

## 3. どう紐づいているか（束ね方）

`flake.nix` の `darwinConfigurations.hermes` が、モジュール（= 設定ファイル）を
1つのリストに束ねる:

```
darwinConfigurations.hermes
 ├── hosts/hermes/default.nix     ← ホスト固有の値・宣言
 ├── modules/hostSpec.nix         ← オプション定義
 ├── hosts/common/ (default+homebrew) ← 共通システム設定
 └── home-manager（darwin モジュールとして内蔵）
      └── users.agent = import ./home
           ├── home/default.nix
           └── home/dotfiles.nix  ← ~ 配下の symlink 宣言
```

ポイントは2つ:

1. **モジュールは自動でマージされる**。たとえば `homebrew.brews` は
   common 側と hermes 側の両方に書いてあるが、Nix のモジュールシステムが
   リストを結合してくれる。「共通は common に、固有はホストに」と
   置き場所を分けるだけでよい
2. **home-manager は nix-darwin の入れ子**。`extraSpecialArgs` で `hostSpec` を
   home 側にも渡しているので、`home/dotfiles.nix` は「このホストの dotfiles は
   どこにあるか」（`hostSpec.dotfilesDir`）を知ることができる

---

## 4. `darwin-rebuild switch` で起きること（時系列）

```
1. 評価     flake.nix から辿って「あるべき状態」を計算（マシンは無変化）
2. ビルド   その状態一式を /nix/store 内に構築（マシンは無変化）
3. システム activation（root）
   - /etc/zshenv 等を生成物への symlink に張り替え
   - launchd サービス登録、OS 設定適用
   - brew bundle 実行 → 宣言との差分を解消（不足を導入、宣言外を zap で削除）
4. home-manager activation（対象ユーザー）
   - ~/.zshrc や ~/.config/* の symlink を宣言通りに配線
   - 既存の実体ファイルは *.backup へ退避
```

1〜2 が失敗してもマシンは無傷、という順序が安全性の core。
また適用結果は**世代（generation）**として記録され、
`darwin-rebuild --rollback` で丸ごと前の状態に戻せる。

---

## 5. 最低限の用語集

| 用語 | 意味 |
|---|---|
| flake | ディレクトリを「入力と出力が明示された1つの単位」にする仕組み。入口は flake.nix |
| /nix/store | ビルド成果物の置き場。ハッシュ付きパスで不変。専用 APFS ボリュームにマウントされる |
| モジュール | `{ config, ... }: { 設定 = 値; }` の形をした設定ファイル。複数を束ねると自動マージされる |
| オプション | モジュールが宣言できる設定項目。`lib.mkOption` で自作もできる（hostSpec がそれ） |
| mkOutOfStoreSymlink | 通常 home-manager は store 内のコピーへリンクするが、これは**リポジトリの生ファイル**へリンクする。編集即反映（stow と同じ使用感）にするための道具 |
| activation | ビルド済みの「あるべき状態」を実マシンに反映する工程 |
| 世代 / rollback | switch のたびに前の状態が保存され、いつでも戻せる仕組み |
| stateVersion | 「この構成を使い始めた時点の互換性基準」。**一度決めたら変えない**。バージョンアップとは無関係 |

---

## 6. よくある操作: どこを編集すればいいか

| やりたいこと | 編集する場所 |
|---|---|
| 全 Mac に CLI を追加 | `hosts/common/homebrew.nix` の `brews` |
| hermes だけに brew/cask を追加 | `hosts/hermes/default.nix` の `brews` / `casks` |
| 全ホストに dotfile のリンクを追加 | `home/dotfiles.nix` |
| hermes だけのリンク・zsh 設定 | `hosts/hermes/default.nix` / `zshrc.local` |
| 新しいホスト（MacBook Pro 等）を追加 | `hosts/<name>/default.nix` を作り、flake.nix の `darwinConfigurations` に1エントリ追加 |

反映フロー（hermes の場合）:

```sh
# 1. このリポジトリを編集して main に push
# 2. hermes 側で
git -C "$DOTFILES" pull
sudo darwin-rebuild switch --flake "$DOTFILES/config/.config/nix#hermes"
```

**注意**: hermes に brew で何かを直接入れたら、必ず宣言にも追加すること。
宣言に無いものは次の switch で zap に削除される（それが仕様）。

---

## 参考

- 移行計画と完了状態: [ROADMAP.md](ROADMAP.md)
- 方針の根拠（なぜ nix-darwin か、なぜ mkOutOfStoreSymlink か）: [adr/ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)
- 初回セットアップの儀式: [../README.md](../README.md) の「セットアップ（新しい Mac）」
- 構造の元ネタ: [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles)
