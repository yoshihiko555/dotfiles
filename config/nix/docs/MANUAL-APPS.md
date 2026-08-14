# 手動インストールアプリの棚卸し

Nix（home-manager）/ Homebrew（nix-darwin `homebrew.*` 宣言）のいずれの管理下にも
**無い**、手動インストールで運用している macOS アプリの一覧。旧 `Brewfile` の
コメントアウト部分（「既存アプリは一旦保留」節 / 「deprecated/disabled」節）を
削除前に引き継いだもの。作成: 2026-08-13（Brewfile 廃止に伴う退避）。

## 位置づけ

- ここに載っているアプリは brew/nix いずれの宣言にも無く、`darwin-rebuild switch`
  の `cleanup = "zap"` の対象にもならない（宣言が無いので消しようがない）。
- 用途列は不明なものは空欄のまま（推測で埋めていない）。
- brew 管理へ移したくなった場合は、`Brewfile` は存在しないので
  `config/nix/hosts/<host>/homebrew.nix` の `homebrew.casks` に追加すること。

## 一覧（保留中の cask）

| cask | 用途 | 備考 |
|---|---|---|
| `1password` | パスワード管理 | `hosts/hermes/homebrew.nix` の `homebrew.casks` で hermes 用に宣言済み（host 差分。macbook では未宣言＝本表の対象） |
| `alfred` | ランチャー | |
| `alt-tab` | ウィンドウ切替 | |
| `amical` | | |
| `appcleaner` | アンインストーラ | |
| `bettertouchtool` | トラックパッド/ジェスチャ拡張 | |
| `chatgpt` | | |
| `claude` | Claude デスクトップアプリ | |
| `coteditor` | テキストエディタ | |
| `discord` | | |
| `docker-desktop` | コンテナ管理 | OrbStack（`cask "orbstack"`、Nix 管理下）が代替稼働中のため保留（`PHASE-3-2-BREW-INVENTORY.md` 参照） |
| `dropbox` | クラウドストレージ | |
| `easydict` | 辞書・翻訳 | `hosts/macbook/homebrew.nix` の `homebrew.casks` で既に宣言済み。旧 Brewfile では有効行とコメント行が重複していた（stale なコメント）。実質的に管理対象外ではないが、原文保持のため掲載 |
| `figma` | | |
| `google-chrome` | ブラウザ | `hosts/hermes/homebrew.nix` の `homebrew.casks` で hermes 用に宣言済み（host 差分。macbook では未宣言＝本表の対象） |
| `google-drive` | クラウドストレージ | |
| `google-japanese-ime` | 日本語入力 | |
| `hiddenbar` | メニューバー整理 | |
| `iterm2` | ターミナル | |
| `karabiner-elements` | キーボードカスタマイズ | |
| `logi-options+` | Logicool デバイス設定 | |
| `loupedeck` | ハードウェアコントローラ設定 | |
| `microsoft-teams` | | |
| `notion` | | |
| `notion-calendar` | | |
| `notion-mail` | | |
| `nudge` | | tap `yoshihiko555/nudge` は `hosts/macbook/homebrew.nix` で宣言済みだが cask 本体は未導入（意図的、2026-08-02判断） |
| `onedrive` | クラウドストレージ | |
| `slack` | | |
| `soundsource` | オーディオ管理 | |
| `tableplus` | DB クライアント | |
| `visual-studio-code` | エディタ | |
| `wezterm` | ターミナル | `wezterm@nightly` は別 cask として `hosts/macbook/homebrew.nix` で宣言済み（Nix 管理下）。無印 `wezterm` は別物で保留中 |
| `yoink` | ドラッグ&ドロップ補助 | |

## 一覧（deprecated / disabled）

旧 Brewfile 上の注記をそのまま保持。

| cask | 状態 |
|---|---|
| `affinity-photo` | deprecated |
| `dia` | disabled |
| `kindle` | disabled |

## 関連

- [PHASE-3-2-BREW-INVENTORY.md](PHASE-3-2-BREW-INVENTORY.md) — MacBook Pro の brew 棚卸し（宣言済み分の詳細）
- [CHEATSHEET.md](CHEATSHEET.md) — 日常運用コマンド集
