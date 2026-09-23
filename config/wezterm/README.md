# WezTerm Configuration (tmux-first)

[WezTerm](https://wezfurlong.org/wezterm/) を GUI レンダラーとして使用。
タブ/ペイン/セッション管理は tmux に統一。

## ファイル構成

```
wezterm/
├── wezterm.lua            # メインエントリーポイント
├── CHEATSHEET.md          # キーバインド一覧
├── background.jpg         # 背景画像
└── config/
    ├── general.lua           # 基本設定（カラースキーム, マウス, タブバー無効化）
    ├── font.lua              # フォント設定
    ├── window-appearance.lua # ウィンドウの見た目（背景, 透過, 装飾）
    ├── window.lua            # ウィンドウ設定（tmux 自動起動）
    ├── keybinds.lua          # キーバインド（Cmd→tmux 変換 + GUI 操作）
    └── notification.lua      # 通知設定（ベル音カスタマイズ）
```

## 主な特徴

### WezTerm の役割（GUI レンダラーに限定）

- **カラースキーム**: Tokyo Night Moon
- **背景**: 半透明ウィンドウ（70%透過）+ ぼかし効果 + 背景画像
- **フォント**: UDEV Gothic 35NFLG (Bold), 15pt, 行の高さ 1.2
- **起動時**: tmux default セッション（baton 常駐）に自動接続。ウィンドウ配置は AeroSpace に任せる
- **タブバー**: 無効化（tmux がウィンドウを管理）
- **tmux 専用**: 新規ウィンドウ（`Cmd+N`）・WezTerm 側のスクロール/検索/コピーモード・マウス設定は持たない
  （tmux 接続中は届かないため。tmux のコピーモード・tmux-fingers・tmux-open を使う）

### キーバインド方針

| レイヤー | 修飾キー | 用途 |
|---------|---------|------|
| WezTerm (GUI) | `Cmd` | コピペ, フォントサイズ, アプリ管理 |
| tmux 操作 | `Alt` | ウィンドウ切替, ペイン移動/リサイズ |
| tmux Prefix | `Ctrl+Q` | 分割, ポップアップ, セッション管理 |

Cmd キーは tmux に直接届かないため、WezTerm が Alt や Prefix に変換して送信する。

### 注意事項

#### format-tab-title ハンドラ

`enable_tab_bar = false` でも WezTerm 内部で `TabBarState` が毎サイクル再計算される。
`format-tab-title` ハンドラが未登録だとデフォルト処理の結果が毎回変わり、
`window.invalidate()` が発火して画面がちらつく。
`wezterm.lua` で安定した値を返す空ハンドラを登録して回避している。

## 位置づけ

サブ端末。常に tmux + baton で起動する（常用は Ghostty + herdr）。

## キーバインド

**[CHEATSHEET.md](CHEATSHEET.md)** を参照。

## 依存関係

- [UDEV Gothic](https://github.com/yuru7/udev-gothic) フォント（Nerd Fonts 版）
- 背景画像: `~/.config/wezterm/background.jpg`
- tmux (起動時に自動接続)

## バックアップ

tmux 移行前の完全な WezTerm 設定は git 履歴に残っている（`config/.config/wezterm.bak/` として保存していたが、
tmux 構成が安定したため 2026-07-30 に削除）。

```bash
# 一覧
git ls-tree -r --name-only fbf993a -- config/.config/wezterm.bak
# 個別ファイルの内容
git show fbf993a:config/.config/wezterm.bak/wezterm.lua
```
