# Nix チートシート（日常運用）

当リポジトリの構成（nix-darwin + home-manager、hermes 運用）前提の実用コマンド集。
仕組みの解説は [GUIDE.md](GUIDE.md)、初回セットアップは [../README.md](../README.md) を参照。

---

## 毎日使うもの: 設定の反映

```sh
# 【基本形】設定を hermes に反映（hermes 上で実行）
git -C "$DOTFILES" pull
sudo darwin-rebuild switch --flake "$DOTFILES/config/.config/nix#hermes"

# 適用せずビルドだけ試す（安全確認。マシンは無変化）
darwin-rebuild build --flake "$DOTFILES/config/.config/nix#hermes"

# MacBook Pro から一連を流す場合
ssh -t macmini-admin 'sudo darwin-rebuild switch --flake /Users/agent/hermes-workspace/ghq/github.com/yoshihiko555/dotfiles/config/.config/nix#hermes'
```

> 反映フロー: **リポジトリ編集 → push → hermes で pull → switch**。
> ただし `mkOutOfStoreSymlink` 対象（.zshrc / starship / nvim 等の**設定ファイルの中身**）は
> pull だけで即反映され、switch は不要。switch が要るのは**パッケージや配線の変更**時。

## 元に戻す

```sh
sudo darwin-rebuild --list-generations            # 世代一覧
sudo darwin-rebuild switch --rollback             # 1 つ前の世代へ（数秒）
sudo darwin-rebuild switch --switch-generation 3  # 番号指定（-G 3）
```

## パッケージを増やす・減らす

```sh
# 1. 置き場所を選んで編集（詳細は GUIDE.md §6）
#    CLI（3台共通）      → home/packages.nix
#    hermes だけの brew   → hosts/hermes/default.nix の brews
#    cask                → hosts/hermes/default.nix の casks
# 2. あるか探す
nix search nixpkgs ripgrep            # nixpkgs を検索
nix eval --raw nixpkgs#fd.name        # 属性名の存在＆バージョン確認
# 3. ローカルでビルド確認 → commit → push → hermes で pull + switch
nix build ./config/.config/nix#darwinConfigurations.hermes.system --no-link
```

> **重要**: hermes に `brew install` で直接入れたものは宣言に無ければ
> **次の switch で zap に消される**。必ず宣言に追加すること。

## インストールせずに試す

```sh
nix run nixpkgs#cowsay -- "hello"     # 一回だけ実行（何も残らない）
nix shell nixpkgs#jq nixpkgs#yq      # そのシェルの間だけ PATH に入る
nix develop ~/.config/nix             # リポジトリの devShell（git/jq/ripgrep）
```

## バージョン更新（宣言的アップデート）

```sh
# MacBook Pro 側で実行し、flake.lock の変更を commit → push する
nix flake update --flake ./config/.config/nix
nix build ./config/.config/nix#darwinConfigurations.hermes.system --no-link  # ビルド確認
# → hermes で pull + switch すると全パッケージが lock 通りに更新される
```

> brew の「随時 upgrade」と違い、**lock ファイルの更新 = 更新の実行**。
> いつ何が上がったか git 履歴に残り、問題があれば lock を戻せば環境も戻る。

## 調べる

```sh
command -v rg                          # どこ由来か確認
                                       #   /etc/profiles/per-user/agent/bin/... = Nix
                                       #   /opt/homebrew/bin/...               = brew
brew list --formula                    # brew 残留の確認（cask + git-gtr + LLM 基盤のみが正常）
brew leaves                            # brew の明示インストール分
nix flake metadata ./config/.config/nix  # lock されている入力の日付・rev
```

## 掃除

```sh
nix store gc                           # 参照されていないものを削除
sudo nix-collect-garbage --delete-older-than 30d  # 30 日より古い世代ごと削除
nix store optimise                     # 重複ファイルのハードリンク化
```

> **注意**: 古い世代を消すと、その世代への rollback はできなくなる。
> 「切り戻し先として残したい世代があるうちは GC しない」が原則。

## トラブル時

```sh
darwin-rebuild build --flake … --show-trace   # 評価エラーの詳細を出す
/nix/var/nix/profiles/default/bin/nix --version  # PATH が壊れた時の nix 直叩き
sudo darwin-rebuild switch --rollback         # まず前の世代に戻して落ち着く
```

- `command not found` → 新しいシェルを開き直す（PATH は起動時に決まる）
- switch が `Permission denied`（brew 系）→ `/opt/homebrew` の所有権を確認
  （`ls -ld /opt/homebrew`。agent 所有が正）
- 詳細なハマりどころは [ROADMAP.md](ROADMAP.md) Phase 3-1「実施記録」参照

---

## hermes 運用の約束事（要点だけ再掲）

| すること | 使うもの |
|---|---|
| 通常の SSH | `ssh macmini-agent` |
| 管理者作業（switch 等） | `ssh -t macmini-admin '…'`（理由を明示） |
| brew で何か入れたら | 必ず宣言（hosts/）にも追加 |
| 設定ファイルの中身の変更 | pull だけで反映（switch 不要） |
| パッケージ・配線の変更 | pull + switch |
