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

> **nix-darwin という名前**: macOS の OS 基盤の名前が Darwin。
> nix-darwin は「OS 全体を設定ファイルから組み立てる NixOS の思想を macOS に移植した
> レイヤー」で、macOS 本体は置き換えられないため
> **root 権限で触る領域（/etc・launchd・brew・OS 設定）の宣言管理**に特化している。

home-manager は本来独立したツールで、単体利用なら `home-manager switch` という
**別コマンド**で `~` 配下だけを管理する（sudo 不要。WSL2 = Phase 3-3 はこの単体形になる）。
当リポジトリの macOS ホストでは**単体では動かさず、nix-darwin の1モジュールとして
内蔵**している。`darwin-rebuild switch` の中で「① root がシステム層を適用 →
② 続けて対象ユーザーとして home-manager を適用」という入れ子で走るため、
コマンド1つで両方が適用され、バージョンも flake.lock で揃い、hostSpec も共有できる。

---

## 2. ファイルマップ（このリポジトリの実物）

```
config/.config/nix/
├── flake.nix              # 入口。材料（inputs）と成果物（outputs）の宣言
├── flake.lock             # 材料のバージョン固定（git の lock ファイルと同じ発想）
├── modules/
│   └── hostSpec.nix       # 「ホストごとに違う値」を受け渡すための自作オプション定義
├── darwin/                # darwin ホスト共通のシステム層（WSL2 は通らない）
│   ├── default.nix        # nix.enable=false, zsh, DOTFILES 注入等
│   └── homebrew.nix       # 共通 brew 宣言（+ zap 設定）
├── hosts/                 # ホスト固有（薄く保つ。2台以上で使うものは共通層へ昇格）
│   └── hermes/
│       ├── default.nix    # hostSpec の値と目次（imports）。実体は機能群ごとに分割
│       ├── homebrew.nix   # hermes の cask 宣言
│       ├── dotfiles.nix   # hermes 固有の配線（tmux / mise / zshrc.local）
│       ├── hermes-agent.nix       # Hermes Agent 基盤（LLM の launchd 宣言等）
│       ├── llama-swap-config.yaml # llama-swap 設定（mkOutOfStoreSymlink で配線）
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

なぜ必要か: `darwin/` の共通設定は「ユーザー名」等を知らないと書けないが、
ハードコードすると共通にならない。そこで各ホスト（`hosts/hermes/default.nix`）が
`hostSpec = { username = "agent"; … }` と値を入れ、共通側は
`config.hostSpec.username` として参照する。**関数の引数のようなもの**と思えばよい。

### darwin/ — darwin ホスト共通のシステム層

- `default.nix`: Determinate が Nix 本体を管理するので `nix.enable = false`、
  zsh の PATH 配線（`programs.zsh.enable`）、`$DOTFILES` 環境変数の注入、
  ユーザー定義、`system.stateVersion`
- `homebrew.nix`: 共通 CLI 15 個の brew 宣言と、**`cleanup = "zap"`**
  （宣言に無いパッケージを switch のたびに自動削除 = 腐敗の構造的防止。
  この1行が nix-darwin を最初から使う理由。ADR-0003 参照）

### hosts/hermes/ — hermes だけの事情（機能群ごとにファイル分割）

- `default.nix`: `hostSpec` の値と `imports`（目次）だけ。
  **機能が増えたらファイルを足して imports に1行追加する**のが増築の作法
- `homebrew.nix`: cask 7 個の宣言
- `dotfiles.nix`: hermes だけに配る symlink（ミニマル tmux.conf、mise、zshrc.local）
- `hermes-agent.nix`: LLM 基盤（llama-cpp / llama-swap / miniserve のパッケージと
  launchd 宣言、gateway 向け gh 橋渡し）
- `zshrc.local`: Hermes Agent 運用 alias（`hms` 等）。**Nix 言語に書き直さず
  普通の zsh ファイルのまま**置き、symlink で配るのが当リポジトリの方針

複数ファイルに分かれていても、モジュールシステムが `homebrew.*` や
`home-manager.users.agent` を自動マージするので、置き場所は自由に選べる。

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
 ├── darwin/ (default+homebrew)       ← darwin 共通システム層
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
| 全台共通の CLI を追加 | `home/packages.nix`（nixpkgs 収録のもの） |
| darwin 共通の brew を追加 | `darwin/homebrew.nix`（nixpkgs 未収録のみ） |
| hermes だけに brew/cask を追加 | `hosts/hermes/homebrew.nix` の `brews` / `casks` |
| 全ホストに dotfile のリンクを追加 | `home/dotfiles.nix` |
| hermes だけのリンク・zsh 設定 | `hosts/hermes/dotfiles.nix` / `zshrc.local` |
| hermes のデーモン（launchd） | `hosts/hermes/hermes-agent.nix`（新しい機能群は新ファイル + imports 追加） |
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

## 7. 元に戻す（rollback）と完全撤去

switch のたびに「マシンのあるべき状態一式」が**世代（generation）**として
`/nix/var/nix/profiles/system-N-link` に番号付きで保存され、古い世代は消されない。
「元に戻す」とはポインタを昔の番号に付け替えて activation をやり直すこと。
再ビルド・再ダウンロード不要なので数秒で戻る。

```sh
sudo darwin-rebuild --list-generations            # 世代一覧
sudo darwin-rebuild switch --rollback             # 1つ前の世代へ
sudo darwin-rebuild switch --switch-generation 3  # 番号指定で戻る（-G 3）
```

### rollback で戻る範囲（限界も含めて）

| 対象 | 戻る？ |
|---|---|
| `/etc` の生成ファイル・launchd・OS 設定 | ✅ 完全に戻る |
| `~` の symlink 配線 | ✅ 旧世代の配線に戻る |
| brew | ⚠️ 旧世代の宣言で bundle が再実行される。zap で消えた分は再ダウンロードして入れ直しになるため瞬時ではない。cask のアプリ内データは消えたら戻らない |
| dotfiles リポジトリ自体の編集 | ❌ 戻らない。`mkOutOfStoreSymlink` はリポジトリの生ファイルを指すため、設定の中身を戻すのは **git の仕事**（「編集即反映」の裏返し） |
| 自分のデータ・管理外ファイル | ❌ そもそも Nix の管轄外 |

古い世代は `nix-collect-garbage` 系で掃除すると戻れなくなる（現状 hermes は自動 GC なし）。

### 完全撤去（Nix ごとやめる）

導入と逆順の儀式で完全に撤退できる:

1. nix-darwin のアンインストーラを実行（`/etc` の生成物が除去される）
2. 退避してあった `/etc/*.before-nix-darwin` を元の名前に戻す
3. Determinate Nix をアンインストール（`/nix` ボリュームごと消える）

この撤退路が常に確保されているのが「Nix は試しやすい」と言われる理由。

---

## 参考

- 移行計画と完了状態: [ROADMAP.md](ROADMAP.md)
- 方針の根拠（なぜ nix-darwin か、なぜ mkOutOfStoreSymlink か）: [adr/ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)
- 初回セットアップの儀式: [../README.md](../README.md) の「セットアップ（新しい Mac）」
- 構造の元ネタ: [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles)
