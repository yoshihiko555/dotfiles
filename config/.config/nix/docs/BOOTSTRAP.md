# 初回セットアップ（まっさらな Mac から）

**これが「まっさらな Mac から環境を復元する手順」の正典。** 他のドキュメント（ルート
[README.md](../../../README.md)、[../README.md](../README.md)）はここへ誘導する形にしている。

対象は macOS（`aarch64-darwin`）のみ。WSL2 は対象外（[PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md) 参照）。

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
cask は macbook 13 件・hermes 7 件が宣言されており、初回 `switch` より前に brew 本体が必要。

この段階ではリポジトリをまだ clone していないため、公式インストーラを直接叩く。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apple Silicon の場合、シェルへ反映
eval "$(/opt/homebrew/bin/brew shellenv)"
```

clone 後であれば、同じ内容の `scripts/install-brew.sh`（このリポジトリに同梱）を
`bash scripts/install-brew.sh` で実行してもよい（インストール済みなら何もしない）。

### 3. GitHub 認証

このリポジトリを clone するために GitHub 認証が要る。この段階では `gh` コマンドはまだ
無いので、以下のどちらかを使う。

- SSH: `ssh-keygen` で鍵を作成し、GitHub の Settings → SSH and GPG keys に公開鍵を登録する
- HTTPS: Personal Access Token（PAT）を発行し、`git clone` 時にユーザー名 + PAT で認証する

`switch` 完了後、`gh` は Nix 管理下で使えるようになるため、以降は `gh auth login` に
切り替えてよい。

### 4. Nix 本体（flakes 有効）

**[`NixOS/nix-installer`](https://github.com/NixOS/nix-installer)（素の Nix / upstream Nix）を使う。**
Determinate 系のインストーラは使わない（[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)
で hermes を Determinate Nix から素の Nix へ移行した経緯を参照。macOS Tahoe で
シェル版インストーラが `/etc/fstab` 書き込みに失敗する事象は **Determinate 版インストーラ固有**
で、`NixOS/nix-installer` では発生しない）。

> **要確認**: 実行したインストールコマンド行の記録が残っていない。推測で断定せず、
> [GitHub のリリースページ](https://github.com/NixOS/nix-installer/releases)の手順に従い、
> `--enable-flakes`（flakes 有効化）が必要であることだけを踏まえて実行すること。
>
> 既知の事実: hermes では **Nix 2.35.1 を macOS Tahoe 26.4.1 で導入し、動作確認済み**
> （[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md) 検証節）。

### 5. dotfiles を clone

```sh
git clone https://github.com/yoshihiko555/dotfiles.git ~/ghq/github.com/yoshihiko555/dotfiles
```

**このパスは `hostSpec.dotfilesDir` にホストごとハードコードされているため厳守する**
（[`modules/hostSpec.nix`](../modules/hostSpec.nix)、`hosts/<host>/default.nix`）。
別パスに置くと `mkOutOfStoreSymlink` の配線がすべて壊れる。

| ホスト | dotfilesDir |
|---|---|
| macbook | `/Users/yoshihiko/ghq/github.com/yoshihiko555/dotfiles` |
| hermes | `/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles` |

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

hermes のように、clone したユーザー（`agent`）と `switch` を叩くユーザー（root 経由）が
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
  switch --flake ~/ghq/github.com/yoshihiko555/dotfiles/config/.config/nix#macbook
```

macbook 向けの例。**hermes は `dotfilesDir` 自体が異なる**（手順 5 の表を参照）ため、
`#macbook` を `#hermes` に読み替えるだけでなく、flake 参照パスの前半も
`/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles/config/.config/nix#hermes`
に読み替える。

### 9. 2 回目以降

初回 switch 後は `darwin-rebuild` が `/run/current-system/sw/bin` に入るため、以下で足りる。

```sh
sudo darwin-rebuild switch --flake ~/ghq/github.com/yoshihiko555/dotfiles/config/.config/nix#macbook
```

macbook 向けの例。hermes の場合はパスの読み替えが手順 8 と同様に必要（手順 5 の表を参照）。

`switch` 前にビルドだけ試して安全確認したい場合は次を使う（マシンは無変化）。

```sh
cd ~/ghq/github.com/yoshihiko555/dotfiles
nix build ./config/.config/nix#darwinConfigurations.macbook.system
# ビルド結果を確認したら switch へ進む
```

日常運用のショートカット（`nxb` / `nxs` / `nxrb` 等）は [CHEATSHEET.md](CHEATSHEET.md) を参照。

### 10. switch 完了後

ここで初めて `task` / `mise` / `sheldon` / `gh` などが使えるようになる。
`go-task` は `hosts/macbook/packages.nix` で Nix 管理されている CLI で、`task` コマンドの
実体を提供する。

```sh
task --list    # 日常タスク一覧
task status    # 配線・drift の確認
```

mise の trust が switch の副作用で外れることがある
（[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md) 影響節）。
言語ランタイムが読み込まれない場合は `mise trust` を再実行する。

## host 一覧

`flake.nix` の `darwinConfigurations` より。

| ホスト | user | system | dotfilesDir |
|---|---|---|---|
| macbook | `yoshihiko` | `aarch64-darwin` | `/Users/yoshihiko/ghq/github.com/yoshihiko555/dotfiles` |
| hermes | `agent` | `aarch64-darwin` | `/Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles` |

## SSH 越しに hermes を構築する場合の注意

**システム設定 → 共有 → リモートログイン → リモートユーザーにフルディスクアクセスを許可** を
ON にしておく必要がある。OFF だと root でも `/etc/fstab` 等の rename が
`Operation not permitted` になる（[../README.md](../README.md) にも既述）。

---

## 未検証・未確定事項

- **この手順が実機で通っているのは hermes のみ。** macbook をまっさらな状態から
  再構築した記録は存在しない。
- **Nix 本体のインストールコマンド行が未記録。** 手順 4 の「要確認」参照。
- **ロールバック手順は未検証。** [ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)
  の「撤退条件とロールバック」節に「以下のロールバック手順は未検証」と明記されている。
  素の Nix → Determinate Nix の逆方向移行は行っていない。
