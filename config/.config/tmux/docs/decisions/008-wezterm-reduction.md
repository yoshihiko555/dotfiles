# ADR-008: WezTerm 設定の縮小 (Phase 6)

- **状態**: 承認・実施済み
- **日付**: 2026-03-17

## コンテキスト

tmux-first 環境への移行に伴い、WezTerm の役割を GUI レンダラーに限定する。
タブ/ペイン/セッション管理を tmux に統一し、WezTerm の設定ファイルを最小化する。

## 決定

### 削除したモジュール (7 ファイル)

| ファイル | 役割 | tmux 側の代替 |
|---------|------|-------------|
| `actions.lua` | smart-splits, overlay, ワークスペース管理 | `smart-splits.conf`, `popup.conf` |
| `layouts.lua` | ペイン分割レイアウト | `bin/tmux-split-layout` (Prefix+2-8) |
| `statusbar.lua` | WezTerm ステータスバー | `statusbar.conf` |
| `tab.lua` | タブバーカスタマイズ | tmux ウィンドウ一覧 |
| `command_palette.lua` | コマンドパレット拡張 | `bin/tmux-cheatsheet` (Prefix+?) |
| `resurrect.lua` | セッション永続化 | tmux-resurrect (将来導入) |
| `context.lua` | 上記モジュールの依存ヘルパー | 不要 |

### 残したモジュール

`wezterm.lua`, `window.lua`, `font.lua`, `general.lua`, `keybinds.lua`, `notification.lua`

### キーバインド方針

| レイヤー | 修飾キー | 用途 |
|---------|---------|------|
| WezTerm (GUI) | `Cmd` | コピペ, フォントサイズ, アプリ管理 |
| tmux (Prefix なし) | `Alt` | ウィンドウ切替, ペイン移動/リサイズ |
| tmux (Prefix) | `Ctrl+Q` | 分割, ポップアップ, セッション管理 |

Cmd キーは tmux に直接届かないため、WezTerm が Alt や Prefix に変換して送信する。

## ちらつき問題と対策

### 問題

PH6 でイベントハンドラ (`format-tab-title`, `update-status`) を削除した結果、
画面のちらつきが発生した。

### 原因 (WezTerm ソースコード調査)

WezTerm は `enable_tab_bar = false` でも毎サイクル `TabBarState` を再計算する。
`TabBarState::new()` は以下のデータを含む:

```rust
TabBarState::new(
    width,
    mouse_coords,
    &tabs,       // format-tab-title の結果
    &panes,
    palette,
    config,
    &self.left_status,   // update-status で設定
    &self.right_status,  // update-status で設定
)
```

`format-tab-title` ハンドラが未登録だとデフォルト処理（pane title 等の動的データを含む）が
毎回異なる結果を返し、`new_tab_bar != self.tab_bar` が常に true になる。
これにより `window.invalidate()` が毎サイクル発火し、画面がちらつく。

### 対策

1. **`update-status` ハンドラ**: `left_status`, `right_status` を空文字に固定
2. **`format-tab-title` ハンドラ**: tab index ベースの固定値を返す
3. **`status_update_interval = 86400000`**: ステータス更新イベントの発火を実質停止
4. **`enable_tab_bar = false`**: タブバー描画自体を無効化

### 参考

- WezTerm ソース: `wezterm-gui/src/termwindow/mod.rs` (`update_title_impl`)
- WezTerm ソース: `wezterm-gui/src/tabbar.rs` (`TabBarState`)
