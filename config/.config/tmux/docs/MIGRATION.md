# 移行計画: WezTerm → tmux-first 環境

> 原本: `~/ghq/github.com/yoshihiko555/digital-garden/content/notes/tech/2026-03-16_tmux-migration-plan.md`

## 概要

WezTerm のワークスペース管理を tmux セッションに移行し、tmux の中で生活する環境を構築する。

- **WezTerm の役割**: GUI レンダラー (背景画像, 透過, フォント) に限定
- **tmux ブランチの資産**: 分割済み `conf/` 群 + 18 個のヘルパースクリプト
- **ai-orchestra**: tmux-monitor は現行のまま維持

## 進捗

| Phase | 内容 | 状態 | 備考 |
|-------|------|------|------|
| - | 基盤機能 (Prefix, smart-splits, pane_mode, popup, テーマ等) | **完了** | 移行前の tmux ブランチ資産 |
| 1 | 設定ファイル分割 + Stow 対応 | **完了** | `config/.config/tmux/` に分割・移動済み |
| 2 | プロジェクト管理の移行 | **完了** | sessionizer (Prefix+f), kill-session (Prefix+W), セッション切替 (Prefix+w) |
| 3 | プラグイン導入 (TPM) | **部分完了** | fingers (Prefix+F), open 導入済み。resurrect/continuum は後回し |
| 4 | AI セッション管理 | **部分完了** | claude-tmux 採用 (Prefix+b)。claude-squad は保留。ADR-007 参照 |
| 5 | コマンドパレット + URL ハンドラ | **保留** | チートシート (Prefix+?) で代替。URL は tmux-open で対応済み。必要になれば追加 |
| 6 | WezTerm 設定の縮小 | **完了** | GUI レンダラーに限定。7 ファイル削除、keybinds.lua 大幅削減 |
| 7 | 試用 + 微調整 | **進行中** | 1 週間の試用 (目標: 2026-03-23 レビュー) |

## Phase 1: 設定ファイル分割 + 基盤整備

### 目標ディレクトリ構造

```
~/.config/tmux/
├── tmux.conf              # エントリーポイント (source-file のみ)
├── conf/
│   ├── general.conf       # 基本設定
│   ├── keybinds.conf      # キーバインド
│   ├── pane-mode.conf     # pane_mode + resize_mode
│   ├── copy-mode.conf     # copy-mode vi バインド
│   ├── smart-splits.conf  # Alt+hjkl Neovim 連携
│   ├── popup.conf         # display-popup
│   ├── session.conf       # セッション管理
│   ├── statusbar.conf     # ステータスバー
│   ├── appearance.conf    # 見た目
│   └── plugins.conf       # TPM プラグイン定義
├── bin/                   # ヘルパースクリプト
└── layouts/               # レイアウト定義
```

### Stow パス変更

`config/.config/tmux/` に統一。`stow config` で `~/.config/tmux/` にシンボリックリンク作成。

### 分割マッピング

| 現行 `.tmux.conf` セクション | 行数 | 移行先 |
|----------------------------|------|--------|
| 必須設定 (L1-59) | 59 | `general.conf` |
| Prefix (L62-66) | 5 | `keybinds.conf` |
| キーバインド (L70-134) | 65 | `keybinds.conf` |
| resize_mode (L96-107) | 12 | `pane-mode.conf` |
| pane_mode (L110-127) | 18 | `pane-mode.conf` |
| コピーモード (L130-131) | 2 | `copy-mode.conf` |
| display-popup (L140-157) | 18 | `popup.conf` |
| Alt+1-9 ウィンドウ直通切替 | 9 | `session.conf` |
| smart-splits (L177-181) | 5 | `smart-splits.conf` |
| 見た目 (L185-225) | 41 | `statusbar.conf` + `appearance.conf` |

## Phase 2: プロジェクト管理の移行

### tmux-sessionizer (Prefix+f)

GHQ リポジトリ + git worktree を fzf で選択 → tmux セッション作成/切替。

WezTerm の `select_project` と同等の UI を再現する:

```
  ○ 🖥 default
  ○ 🖥 digital-garden
  ● 🔀 dotfiles:tmux   (current)
  ○ 🖥 learno
  ○ 🖥 tech-site
```

- `repo-list.sh` の TYPE フィールドでアイコンを切替
  - `repo` → `○ 🖥` (通常リポジトリ)
  - `worktree` → `● 🔀` (worktree、親リポジトリ:ブランチ形式)
- 現在のセッションと一致する項目に `(current)` を表示
- セッション名: worktree は `repo:branch`、repo は末尾ディレクトリ名 (`.` → `-` に変換)
- データソース: `scripts/repo-list.sh` (WezTerm と共有)

### tmux-kill-session (Prefix+W)

fzf でセッション選択 → 削除。現在のセッションと `claude-*` セッションは除外。

## Phase 3: プラグイン導入

TPM を自動ブートストラップ方式で導入。初回 tmux 起動時に自動 clone + プラグインインストール。

| プラグイン | 用途 | WezTerm 相当 | 状態 |
|-----------|------|-------------|------|
| tmux-fingers | テキスト選択 (URL, UUID 等) | QuickSelect | **導入済み** (Prefix+F) |
| tmux-open | URL/ファイルパスを開く | - | **導入済み** (コピーモードで o/S) |
| tmux-resurrect | セッション保存/復元 | resurrect.lua | 後回し (マシン再起動時のみ必要) |
| tmux-continuum | 自動保存 (15 分間隔) | - | 後回し (resurrect と同時に検討) |

## Phase 4: AI セッション管理

- claude-squad の導入検証 (baton の代替候補)
- `tmux-init-panes`: ペイン数に応じて nvim/claude/codex を自動起動
- 判断基準: Phase 7 の試用期間で baton と比較して決定
- 補足: ai-orchestra 監視用の `tmux-watch-claude-panes` 系スクリプトは先行実装済み

## Phase 5: コマンドパレット + URL ハンドラ

- `tmux-command-menu`: fzf ベースのコマンドパレット (Leader+Space)
- urlscan: 画面中の URL を一覧 → 選択 → ブラウザで開く (Leader+u)

## Phase 6: WezTerm 設定の縮小

### 方針

WezTerm を GUI レンダラーに限定し、タブ/ペイン/セッション管理を tmux に統一。

### 残したファイル

| ファイル | 役割 | 変更 |
|---------|------|------|
| `wezterm.lua` | エントリーポイント | 削除モジュールの require 除去。空の `update-status` / `format-tab-title` ハンドラ追加 |
| `window.lua` | 背景画像, 透過, blur, tmux 自動起動 | 変更なし |
| `font.lua` | フォント設定 | 変更なし |
| `general.lua` | カラースキーム, マウス, QuickSelect パターン | `enable_tab_bar = false`, `status_update_interval` 最大化 |
| `keybinds.lua` | キーバインド | Leader 系全削除。Cmd→tmux 変換追加 (Cmd+1-8, Cmd+D, Cmd+T, Cmd+W) |
| `notification.lua` | ベル音制御 | 変更なし |

### 削除したファイル

`actions.lua`, `layouts.lua`, `statusbar.lua`, `tab.lua`, `command_palette.lua`, `resurrect.lua`, `context.lua`

### バックアップ

`config/.config/wezterm.bak/` に全ファイル保存済み。ロールバック可能。

### WezTerm → tmux キー変換

| Cmd キー | 変換先 | tmux 操作 |
|---------|--------|----------|
| Cmd+1-8 | Alt+1-8 | ウィンドウ切替 |
| Cmd+T | Prefix+c | 新規ウィンドウ |
| Cmd+D / Shift+D | Prefix+r/d | ペイン分割 |
| Cmd+W | Prefix+x | ペイン閉じ |

### 注意: TabBarState ちらつき問題

WezTerm は `enable_tab_bar = false` でも内部で `TabBarState` を毎サイクル再計算する。
`format-tab-title` / `update-status` ハンドラが未登録だとデフォルト処理の結果が毎回異なり、
`window.invalidate()` が毎サイクル発火して画面がちらつく。
以下の対策で回避している（詳細は ADR-008 参照）:

- `update-status`: left/right status を空文字に固定
- `format-tab-title`: tab index ベースの固定値を返す
- `status_update_interval = 86400000`: イベント発火を実質停止

## Phase 7: 試用 + 微調整

目標: 2026-03-23 にレビュー。WezTerm に戻りたくなった場面とストレスポイントを記録。

### 残課題

- smart-splits.nvim の Neovim 導入（tmux バックエンド連携が必要）
- default セッションの扱い（仕様検討が先）
- tmux-resurrect / tmux-continuum の導入検討
- yazi ポップアップ（WezTerm クラッシュ問題あり、保留）

## リスク管理

- WezTerm の設定は削除しない (main ブランチはそのまま維持)
- 問題があれば `stow-worktree.sh revert tmux config` で即座にロールバック可能
- Phase 1-3 までは WezTerm と並行利用可能
