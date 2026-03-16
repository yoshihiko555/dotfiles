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
| 3 | プラグイン導入 (TPM) | **未着手** | resurrect, continuum, fingers, open |
| 4 | AI セッション管理 (claude-squad 検証) | **未着手** | baton との比較 |
| 5 | コマンドパレット + URL ハンドラ | **未着手** | command-menu, urlscan |
| 6 | WezTerm 設定の縮小 | **未着手** | GUI レンダラーに限定 |
| 7 | 試用 + 微調整 | **未着手** | 1 週間の試用 (目標: 2026-03-23 レビュー) |

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

| プラグイン | 用途 | WezTerm 相当 |
|-----------|------|-------------|
| tmux-resurrect | セッション保存/復元 | resurrect.lua |
| tmux-continuum | 自動保存 (15 分間隔) | - |
| tmux-fingers | テキスト選択 (URL, UUID 等) | QuickSelect |
| tmux-open | URL/ファイルパスを開く | - |

## Phase 4: AI セッション管理

- claude-squad の導入検証 (baton の代替候補)
- `tmux-init-panes`: ペイン数に応じて nvim/claude/codex を自動起動
- 判断基準: Phase 7 の試用期間で baton と比較して決定
- 補足: ai-orchestra 監視用の `tmux-watch-claude-panes` 系スクリプトは先行実装済み

## Phase 5: コマンドパレット + URL ハンドラ

- `tmux-command-menu`: fzf ベースのコマンドパレット (Leader+Space)
- urlscan: 画面中の URL を一覧 → 選択 → ブラウザで開く (Leader+u)

## Phase 6: WezTerm 設定の縮小

### 残すもの

- `window.lua`: 背景画像, 透過, blur, フォント, tmux 自動起動
- `font.lua`: フォント設定
- `general.lua`: カラースキーム (fallback)
- `keybinds.lua`: 最小限 (Cmd+C/V, フォントサイズ)

### 削除するもの

- `actions.lua`, `layouts.lua`, `statusbar.lua`, `tab.lua`
- `command_palette.lua`, `resurrect.lua`, `context.lua`, `notification.lua`

## Phase 7: 試用 + 微調整

目標: 2026-03-23 にレビュー。WezTerm に戻りたくなった場面とストレスポイントを記録。

## リスク管理

- WezTerm の設定は削除しない (main ブランチはそのまま維持)
- 問題があれば `stow-worktree.sh revert tmux config` で即座にロールバック可能
- Phase 1-3 までは WezTerm と並行利用可能
