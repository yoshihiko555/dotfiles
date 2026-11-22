# WezTerm から tmux への移行記録

移行ブランチは main に統合済み。以下は移行時の計画と確認結果で、「進行中」「保留」「要観察」は記録当時の状態を示す。
セッション復元、yazi ポップアップ、初回起動直後の `Prefix+f` の3件は当時の記録として残す。
現在の操作と保守手順は [tmux の README](../README.md) を参照。

> 原本: `~/ghq/github.com/yoshihiko555/digital-garden/content/notes/tech/2026-03-16_tmux-migration-plan.md`

## 概要

WezTerm のワークスペース管理を tmux セッションに移行し、tmux の中で生活する環境を構築する。

- **WezTerm の役割**: GUI レンダラー (背景画像, 透過, フォント) に限定
- **tmux ブランチの資産**: 分割済み `conf/` 群 + 18 個のヘルパースクリプト
- **ai-orchestra**: tmux-monitor は 2026-09-25 に ai-orchestra から削除（#450）

## 当時の進捗

| Phase | 内容 | 状態 | 備考 |
|-------|------|------|------|
| - | 基盤機能 (Prefix, smart-splits, pane_mode, popup, テーマ等) | **完了** | 移行前の tmux ブランチ資産 |
| 1 | 設定ファイル分割 + Stow 対応 | **完了** | `config/.config/tmux/` に分割・移動済み（その後 stow 層を除去し、現在は `config/tmux/`） |
| 2 | プロジェクト管理の移行 | **完了** | sessionizer (Prefix+f), kill-session (Prefix+W), セッション切替 (Prefix+w) |
| 3 | プラグイン導入 (TPM) | **部分完了** | fingers (Prefix+F), open 導入済み。resurrect/continuum は後回し |
| 4 | AI セッション管理 | **完了** | `baton` TUI を `Prefix+B` で popup 起動（`Prefix+b` は常駐の default セッションへ切替）。暫定ダッシュボードスクリプトは撤去済み。ADR-20260317-0007 参照 |
| 5 | コマンドパレット + URL ハンドラ | **保留** | チートシート (Prefix+.) で代替。URL は tmux-open で対応済み。必要になれば追加 |
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

`config/.config/tmux/` に統一。home-manager で `~/.config/tmux/` に配線する。
（その後 stow 由来の `config/.config` 中間層を除去し、現在は `config/tmux/`）

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
- データソース: `scripts/repo-list.sh` (`repo` / herdr-sessionizer と共有)

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

- `baton` TUI を `Prefix+B` で popup 起動 (90x90%)。`Prefix+b` は常駐の default セッションへ切替
- 暫定ダッシュボード (`tmux-popup-claude-dashboard`, `tmux-list-claude-panes`, `tmux-open-claude-target`) は撤去済み
- 補足: ai-orchestra 監視用の `tmux-watch-claude-panes` 系スクリプトは先行実装していたが、2026-09-23 に撤去した

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

移行前の全ファイルは `config/.config/wezterm.bak/` に保存していたが、tmux 構成が安定したため
2026-07-30 に削除した。参照が必要な場合は git 履歴から取得する。

```bash
git show fbf993a:config/.config/wezterm.bak/config/statusbar.lua
```

### WezTerm → tmux キー変換

| Cmd キー | 変換先 | tmux 操作 |
|---------|--------|----------|
| Cmd+1-8 | Alt+1-8 | ウィンドウ切替 |
| Cmd+T | Prefix+c | 新規ウィンドウ |
| Cmd+D / Shift+D | Prefix+r/d | ペイン分割 |
| Cmd+W | Prefix+x | ペイン閉じ |
| Cmd+Shift+W | Prefix+X | セッション閉じ (確認付き) |

### 注意: TabBarState ちらつき問題

WezTerm は `enable_tab_bar = false` でも内部で `TabBarState` を毎サイクル再計算する。
`format-tab-title` / `update-status` ハンドラが未登録だとデフォルト処理の結果が毎回異なり、
`window.invalidate()` が毎サイクル発火して画面がちらつく。
以下の対策で回避している（詳細は ADR-20260317-0008 参照）:

- `update-status`: left/right status を空文字に固定
- `format-tab-title`: tab index ベースの固定値を返す
- `status_update_interval = 86400000`: イベント発火を実質停止

## Phase 7: 試用 + 微調整

目標: 2026-03-23 にレビュー。WezTerm に戻りたくなった場面とストレスポイントを記録。

### 当時の残課題

- default セッションの扱い（仕様検討が先）
- tmux-resurrect / tmux-continuum の導入検討
- yazi ポップアップ（WezTerm クラッシュ問題あり、保留）
- Prefix+f セッション切り替えが WezTerm 初回起動直後に失敗する可能性あり（要観察）

### 完了済み

- smart-splits.nvim 導入済み（ADR-20260317-0009 参照）

## リスク管理

- WezTerm の設定は削除しない (main ブランチはそのまま維持)
- 問題があれば nix-darwin の前世代へロールバック可能
- Phase 1-3 までは WezTerm と並行利用可能

## 撤去したヘルパースクリプト

| スクリプト | 経緯 |
|---|---|
| tmux-list-claude-panes | baton に移行済み |
| tmux-popup-claude-dashboard | baton に移行済み |
| tmux-open-claude-target | baton に移行済み |
| ai-orchestra 監視系 8 本 / tmux-popup-claude / tmux-switch-session | 2026-09-23 撤去（監視データが生成されなくなっていた） |
| tmux-cheatsheet | 2026-09-23 撤去。`tmux-cheatsheet-preview` に一本化 |

## 移行時の手動確認記録

チェックは当時の記入状態。キーや設定の名称も当時の表記を残す。

### 環境

- tmux: 3.7c（Nix のパッチ適用版）
- 設定パス: `~/.config/tmux/tmux.conf`
- 配線: home-manager の `mkOutOfStoreSymlink`

### 基本設定 (general.conf)

- [x] True Color が正常に表示される
- [x] マウス操作が有効
- [x] ウィンドウ番号が 1 から開始
- [x] ウィンドウ名が `#{pane_current_command}` で自動更新される

### キーバインド (keybinds.conf)

- [x] Prefix (Ctrl+Q) が機能する
- [x] Prefix+r で横分割
- [x] Prefix+d で縦分割
- [x] Prefix+x でペイン閉じ
- [x] Prefix+z でペインズーム (スナップショット保存付き)
- [ ] Alt+; でペインズーム (Prefix 不要)
- [x] Prefix+h/j/k/l でペイン移動
- [x] Prefix+c で新しいウィンドウ
- [x] Prefix+n / Prefix+P でウィンドウ切替
- [x] Prefix+R で設定リロード + "Reloaded!" メッセージ

### ペインモード (pane-mode.conf)

- [x] Prefix+p でペインモードに入る (ステータスバーに PANE バッジ)
- [x] h/j/k/l でペイン移動 (Prefix 不要で連続操作)
- [x] r で横分割 / d で縦分割
- [x] x でペイン閉じ
- [x] 1-5 でペイン番号ジャンプ
- [x] e でリサイズモードに切替
- [x] Escape / Enter / q でモード終了

### リサイズモード (pane-mode.conf)

- [x] Prefix+e でリサイズモードに入る (ステータスバーに RESIZE バッジ)
- [x] h/j/k/l で 5 セル単位リサイズ
- [x] H/J/K/L で 1 セル単位リサイズ
- [x] Escape / Enter / q でモード終了

### コピーモード (copy-mode.conf)

- [x] Prefix+[ でコピーモード開始 (ステータスバーに COPY バッジ)
- [x] vi キーバインドでスクロール/検索
- [x] マウスドラッグで選択 → コピー (コピーモード維持)
- [x] 通常状態からのマウスドラッグで `copy-mode -M` に入れる
- [x] ドラッグ終了時に `copy-selection` のみ実行され、モードが維持される
- [x] Prefix+V でペインスナップショット表示

### smart-splits (smart-splits.conf)

- [x] Alt+h/j/k/l でペイン移動 (Prefix 不要)
- [x] Neovim 内では Neovim のペイン移動として動作

### display-popup (popup.conf)

- [x] Prefix+g で lazygit (80x80%)
- [x] Prefix+t で一時シェル (80x80%)
- [ ] Prefix+C で Claude Code (90x90%)
- [x] Prefix+s でセッション一覧 (fzf)

### ウィンドウ直通切替 (session.conf)

- [x] Alt+1-9 で N 番目のウィンドウに切替

### ステータスバー (statusbar.conf)

- [x] ステータスバーが上部に表示
- [x] 左側: モードバッジ (`COPY` / `PANE` / `RESIZE` / `PREFIX`)
- [x] 中央: tmux ネイティブのウィンドウ一覧
- [x] 右側: セッション名 + 日時
- [x] Powerline 風のウィンドウハイライトが適用される

### 見た目 (appearance.conf)

- [x] ペイン境界線が表示される
- [x] アクティブ / 非アクティブで境界線色が変わる
- [x] `pane-border-indicators colour` が効く
- [x] 非アクティブペインが明確に暗転する
- [x] コピーモードの選択ハイライトが見やすい
- [x] メッセージ表示の色が正常

### WezTerm → tmux 移行検証 (機能対比)

WezTerm バックアップと現行 tmux 設定を照合（バックアップは 2026-07-30 に削除。
参照が必要な場合は `git show fbf993a:config/.config/wezterm.bak/<path>` で取得する）。

#### ペインレイアウト分割 (Prefix+2~8)

- [ ] 新規ウィンドウ → Prefix+2 で左右2分割される
- [ ] 新規ウィンドウ → Prefix+3 で左1:右上下の3分割になる
- [ ] 新規ウィンドウ → Prefix+4 で2x2グリッドになる
- [ ] 既にペインがあるウィンドウでは拒否メッセージが出る

#### ペイン初期化 (Prefix+0)

- [ ] 2ペイン: pane1=nvim, pane2=free で起動する
- [ ] 3ペイン: pane1=nvim, pane2=claude, pane3=free で起動する
- [ ] 4ペイン: pane1=claude, pane2=codex, pane3=free, pane4=free で起動する
- [ ] GHQ リポジトリ外では拒否メッセージが出る
- [ ] TUI プロセス実行中のペインがあると拒否される
- [x] ~~既知バグ: ターゲット未指定~~ → 2026-09-23 修正（`#{pane_id}` を渡し、ペイン ID で指定）

#### WezTerm Cmd→tmux 変換 (keybinds.lua)

- [ ] Cmd+1-8 でウィンドウ切替 (WezTerm が Alt+1-8 に変換)
- [ ] Cmd+T で新規ウィンドウ (Prefix+c に変換)
- [ ] Cmd+D でペイン横分割 (Prefix+r に変換)
- [ ] Cmd+Shift+D でペイン縦分割 (Prefix+d に変換)
- [ ] Cmd+W でペイン閉じ (Prefix+x に変換)
- [ ] Cmd+Shift+W でセッション閉じ (Prefix+X に変換、確認付き)

#### セッション管理

- [ ] Prefix+f でプロジェクト picker が開く (WezTerm の Leader+f 相当)
- [ ] picker でリポジトリ選択 → セッション作成/切替される
- [ ] picker で worktree 選択 → `repo:branch` 形式のセッションになる
- [ ] Prefix+w でセッション一覧切替 (WezTerm の Leader+w 相当)
- [ ] Prefix+W でセッション削除 (WezTerm の Leader+W 相当)
- [ ] 現在のセッションと claude-* セッションは削除候補から除外される

#### ポップアップ / オーバーレイ

- [ ] Prefix+g で lazygit が起動する (WezTerm の overlay_lazygit 相当)
- [ ] Prefix+t で一時シェルが開く (WezTerm の open_bottom_shell 相当)
- [ ] Prefix+C で Claude Code が開く
- [ ] Prefix+b で default セッション (baton) へ切り替わる / Prefix+B で baton popup が開く
- [ ] Prefix+. でチートシート (トピック一覧 + プレビュー) が開く

#### smart-splits.nvim 連携

- [ ] Alt+h/j/k/l で tmux ペイン移動する (WezTerm を経由してパススルーされる)
- [ ] Neovim 内では Neovim の split 移動として動作する
- [ ] Alt+Shift+H/J/K/L でペインリサイズする

#### プラグイン

- [ ] Prefix+F で tmux-fingers が起動する (WezTerm の QuickSelect 相当)
- [ ] URL/UUID/パス等にラベルが表示され、キーで選択・コピーできる
- [ ] コピーモードで `o` でブラウザを開く (tmux-open)
- [ ] コピーモードで `S` で Google 検索 (tmux-open)

#### WezTerm 側で失われた機能 (意図的な削除 or 代替あり)

| WezTerm 機能 | 状態 | tmux 代替 |
|---|---|---|
| QuickSelect (Leader+/) | 削除 | tmux-fingers (Prefix+F) |
| yazi オーバーレイ (Leader+y) | 保留 | WezTerm クラッシュ問題あり |
| baton オーバーレイ (Leader+B) | 削除 | baton popup (Prefix+B) に置換 |
| ワークスペース復元 (Leader+r) | 保留 | tmux-resurrect (Phase 3 で検討) |
| Alfred 外部トリガー | 削除 | tmux-sessionizer で代替 |
| 画面クリア (Ctrl+L 拡張) | 削除 | tmux 標準のスクロールバック動作に依存 |
| Cmd+Click で URL を開く | 削除 | tmux の `mouse on` 下では WezTerm に届かないため 2026-09-23 に設定ごと削除。URL は tmux-open / tmux-fingers で開く |

### 課題・気づき

| # | 内容 | 重要度 | 対応 |
|---|------|--------|------|
| 1 | `.zshrc` での tmux 自動起動は WezTerm タブ追加/分割時に全て同じセッションに接続してしまう | 中 | `gui-startup` 方式に変更済み。tmux-first 運用で解消 |
| 2 | ~~WezTerm が `Alt+h/j/k/l` を smart-splits 用に捕捉~~ | ~~高~~ | **解決済み**: Phase 6 で WezTerm の `split_nav` を削除、tmux にパススルー |
| 3 | `Alt+1-9` は現状ウィンドウ切替。セッションの direct switch は popup (`Prefix+w`) のみ | 低 | 現行の運用で十分。必要になれば追加 |
| 4 | ~~claude-squad の detach キー衝突~~ | ~~高~~ | **一時解消済み**: claude-squad は廃止。`claude-tmux` も試用終了し、現在は暫定 Claude pane ダッシュボードを運用 |
| 5 | ~~claude-squad の popup スタック問題~~ | ~~高~~ | **解決済み**: claude-squad 廃止 |
| 6 | ~~`tmux-init-panes` に `tmux-split-layout` と同じターゲット未指定バグ~~ | ~~高~~ | **解決済み (2026-09-23)**: `#{pane_id}` を渡し、ペイン ID で全操作を指定。0 始まりの番号指定（`pane-base-index 1` と不一致）も解消 |
| 7 | Claude Code pane ダッシュボードの status 判定が一部 UI 変更に追従できない可能性 | 低 | 実ペイン末尾のパターン依存。必要なら判定語彙を追加 |

### 検討課題 (将来)

- **tmux 自動起動方式の最終決定**: `.zshrc` vs `gui-startup` vs tmux-continuum (Phase 3)
  - tmux-first で WezTerm のタブ/分割を完全に使わない運用にするなら `.zshrc` で OK
  - 併用するなら `gui-startup` が安全
  - tmux-continuum にはターミナルアプリ別の自動起動機能あり

- **セッション作成の仕様策定**
  - `default` セッションの役割が未定義
    - 汎用作業用？ダッシュボード (baton 等) 用？一時的なシェル用？
    - WezTerm の `gui-startup` が `tmux new-session -A -s default` で作成している
  - sessionizer で作成するセッションの初期レイアウト
    - Phase 4 の `tmux-init-panes` と関連 (ペイン数に応じて nvim/claude/codex を自動起動)
  - セッション復元のポリシー
    - Phase 3 の tmux-resurrect/continuum と関連
    - どこまで自動復元するか (ウィンドウ構成のみ？プロセスも？)
