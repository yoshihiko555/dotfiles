# 初回セットアップ（まっさらな Mac から）

[ルート README](../../../README.md) は新しい MacBook で実行する手順をまとめている。
ここでは Mac mini（hermes）との違い、各工程の背景、手動設定を説明する。

対象は macOS（`aarch64-darwin`）。会社 Windows には [WSL2 の初回構築手順](BOOTSTRAP-WSL2.md)を使う。

日常運用（2 回目以降の `switch`）は [../README.md](../README.md) の「常用コマンド」と
[CHEATSHEET.md](CHEATSHEET.md) を参照。このドキュメントは初回のみ。

---

## 手順

### 1. Xcode Command Line Tools

```sh
xcode-select --install
```

`git` を含む基本ツールが入る。すべての手順の前提になる、最初の一手。

### 2. Homebrew 本体

**Nix は Homebrew 本体をインストールしない。** `nix-homebrew` は不採用の方針
（`flake.nix` のコメント参照。「mozumasu/dotfiles の構造を踏襲しつつ、nix-homebrew /
sops-nix / treefmt-nix / overlay 群など依存の多い部分は削ぎ落としている」とあり、
[ADR-0003](adr/ADR-20260730-0003-purpose-and-order.md) の「依存を減らす」方針に基づく）。
両ホストで cask が宣言されており、初回 `switch` より前に brew 本体が必要。

この段階ではリポジトリをまだ clone していないため、公式インストーラを直接叩く。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon の場合、シェルへ反映
eval "$(/opt/homebrew/bin/brew shellenv)"
```

clone 後であれば、同じ内容の `scripts/install-brew.sh`（このリポジトリに同梱）を
`bash scripts/install-brew.sh` で実行してもよい（インストール済みなら何もしない）。

### 3. GitHub 認証

この公開リポジトリは HTTPS でそのまま clone できる。変更を push する場合は、
初回 `switch` 後に `gh auth login` で認証するか、GitHub に SSH 公開鍵を登録する。

### 4. Nix 本体（flakes 有効）

**[`NixOS/nix-installer`](https://github.com/NixOS/nix-installer)（素の Nix / upstream Nix）を使う。**
Determinate 系のインストーラは使わない（[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)
で hermes を Determinate Nix から素の Nix へ移行した経緯を参照。macOS Tahoe で
シェル版インストーラが `/etc/fstab` 書き込みに失敗する事象は **Determinate 版インストーラ固有**
で、`NixOS/nix-installer` では発生しない）。

公式の flakes 対応インストールコマンドを使う。導入後は新しいターミナルで `nix --version` を確認する。

```sh
curl -sSfL https://channels.nixos.org/nix-latest/nix-installer | sh -s -- install --enable-flakes
```

hermes の構築記録には当時のインストールコマンドが残っていない。
WSL2 の実施記録は [PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md) を参照。

### 5. dotfiles を clone

MacBook の場合。

```sh
git clone https://github.com/yoshihiko555/dotfiles.git ~/ghq/github.com/yoshihiko555/dotfiles
```

Mac mini の場合。

```sh
git clone https://github.com/yoshihiko555/dotfiles.git ~/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles
```

**このパスは `hostSpec.dotfilesDir` にホストごとハードコードされているため厳守する**
（[`modules/hostSpec.nix`](../modules/hostSpec.nix)、`hosts/<host>/default.nix`）。
別パスに置くと `mkOutOfStoreSymlink` の配線がすべて壊れる。

適用先のアカウント・ホーム・clone 先は、下の「host 一覧」から各ホストの定義を確認する。

`ghq` はこの時点でまだ入っていないので、`git clone` で直接上記パスへ置く
（`ghq get` は switch 後、Nix 管理下で使えるようになってから使えばよい）。

### 6. `/etc/zsh*` の退避

nix-darwin がシステムの zsh 設定ファイルを管理するため、既存のものを退避する。

```sh
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
sudo mv /etc/zprofile /etc/zprofile.before-nix-darwin
```

存在しないファイルがあってもエラーで止めず、存在するものだけ退避すればよい。

### 7. safe.directory の登録（repo 所有者と sudo 実行者が異なる場合のみ）

hermes のように、clone したユーザーと `switch` を叩くユーザー（root 経由）が
異なる場合のみ必要。

```sh
sudo git config --global --add safe.directory <repo>
```

macbook のように clone したユーザー本人が sudo する場合は不要。

### 8. 初回 switch

nix-darwin がまだ導入されていないため `darwin-rebuild` コマンドが無い。
`nix run` 経由で直接叩く。

```sh
sudo -H /nix/var/nix/profiles/default/bin/nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
  switch --flake ~/ghq/github.com/yoshihiko555/dotfiles/config/nix#macbook
```

macbook 向けの例。**hermes は `dotfilesDir` 自体が異なる**（手順 5 を参照）ため、
`#macbook` を `#hermes` に読み替えるだけでなく、flake 参照パスの前半も
hermes のホスト定義の `dotfilesDir` に `/config/nix#hermes` を足した絶対パス
に読み替える。

### 9. 2 回目以降

初回 switch 後は `darwin-rebuild` が `/run/current-system/sw/bin` に入るため、以下で足りる。

```sh
sudo darwin-rebuild switch --flake ~/ghq/github.com/yoshihiko555/dotfiles/config/nix#macbook
```

macbook 向けの例。hermes の場合はパスの読み替えが手順 8 と同様に必要（手順 5 を参照）。

`switch` 前にビルドだけ試して安全確認したい場合は次を使う（マシンは無変化）。

```sh
cd ~/ghq/github.com/yoshihiko555/dotfiles
nix build ./config/nix#darwinConfigurations.macbook.system
# ビルド結果を確認したら switch へ進む
```

日常運用のショートカット（`nxb` / `nxs` / `nxrb` 等）は [CHEATSHEET.md](CHEATSHEET.md) を参照。

### 10. switch 完了後

以下は MacBook の確認手順。初回反映後、新しいターミナルでリポジトリのルートに移動する。
`go-task` は `hosts/macbook/packages.nix` で Nix 管理されている CLI で、`task` コマンドの
実体を提供する。

```sh
task --list    # 日常タスク一覧
task status    # 配線・drift の確認
```

mise の trust が switch の副作用で外れることがある
（[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md) 影響節）。
言語ランタイムが読み込まれない場合は `mise trust` を再実行する。

### Homebrew の tap trust

**手動作業は不要。** Homebrew 6.0 から非公式 tap は明示的に信頼するまでロードされず、
`brew info --cask aerospace` のような対話コマンドが以下で落ちる。

```
Error: Refusing to load cask nikitabobko/tap/aerospace from untrusted tap nikitabobko/tap.
```

`switch` の home-manager activation（`darwin/homebrew.nix` の `brewTapTrust`）が
宣言済み tap を `brew trust --tap` へ流し込むため、初回 `switch` の完了時点で
`~/.homebrew/trust.json` が生成されている。`brew trust` を手で叩く必要はない。

信頼状況の確認:

```sh
brew trust           # 信頼済みの tap / formula / cask / command を一覧
cat ~/.homebrew/trust.json
```

補足: `brew bundle`（switch 内の cask/formula 導入）は
`HOMEBREW_NO_REQUIRE_TAP_TRUST=1` で trust を迂回している。activation の順序は
brew bundle → home-manager なので、初回 `switch` の bundle 時点では trust.json が
まだ存在せず、この迂回設定は引き続き必要。

### BetterTouchTool の設定

**新規マシンでは手動作業が要る。** BTT の設定実体は SQLite（ファイル名にバージョン
番号が入る `btt_data_store.version_*`）なので symlink では管理できず、AppleScript
API 経由で `config/btt/triggers.json` を流し込む方式を取っている
（`hosts/macbook/dotfiles.nix` の `bttSync` → `scripts/btt-sync.sh`）。

初回 `switch` の時点では以下が揃っていないため、activation は警告を出してスキップする。
順に済ませてから `task btt-apply` を実行する。

1. **BTT のインストールとライセンス投入**（`MANUAL-APPS.md` の管理外アプリ）
2. **BTT の起動**（未起動なら activation はスキップ）
3. **Automation の許可**。初回に「ターミナルが BetterTouchTool を制御しようとしています」
   のダイアログが出るので許可する
4. **アプリスコープのグループを GUI で作る**。`Finder` / `Browsers` / `Notion` / `Dia`
   といったスコープは、`triggers.json` には**名前の文字列しか入っていない**
   （bundle ID の一覧は BTT 側のグループ定義が持っていて API から取れない）。
   グループが無い状態で apply するとスコープが解決されない

Global スコープのトリガー（キーボードショートカット、3 本指スワイプ）は
グループ無しでそのまま復元できる。`add_new_trigger` は `triggers.json` の
`BTTUUID` をそのまま採用するので、復元後に再度 apply しても重複しない。

初回の apply は「repo と実機の両方に同じ UUID があって中身が違う」場合だけ
拒否する。まっさらな BTT（トリガー 0 件）や、実機にしか無いトリガーがある
状態からは、そのまま追加が走る。

```sh
task btt-apply     # repo → 実機
task btt-export    # 実機 → repo（GUI で変更したものの回収）
```

## host 一覧

`flake.nix` の `darwinConfigurations` より。

| ホスト | system | アカウントとパスの定義 |
|---|---|---|
| macbook | `aarch64-darwin` | [MacBook の hostSpec](../hosts/macbook/default.nix) |
| hermes | `aarch64-darwin` | [Mac mini の hostSpec](../hosts/hermes/default.nix) |

## SSH 越しに hermes を構築する場合の注意

**システム設定 → 共有 → リモートログイン → リモートユーザーにフルディスクアクセスを許可** を
ON にしておく必要がある。OFF だと root でも `/etc/fstab` 等の rename が
`Operation not permitted` になる（[../README.md](../README.md) にも既述）。

---

## 未検証・未確定事項

- **この手順が実機で通っているのは hermes のみ。** macbook をまっさらな状態から
  再構築した記録は存在しない。
- **Nix 本体のインストールコマンド行が未記録。** 手順 4 参照。
- **ロールバック手順は未検証。** [ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)
  の「撤退条件とロールバック」節に「以下のロールバック手順は未検証」と明記されている。
  素の Nix → Determinate Nix の逆方向移行は行っていない。
