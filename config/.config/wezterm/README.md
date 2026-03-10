# WezTerm Configuration

[WezTerm](https://wezfurlong.org/wezterm/) のカスタム設定ファイル集です。

## ファイル構成

```
wezterm/
├── wezterm.lua          # メインエントリーポイント
├── CHEATSHEET.md        # キーバインド一覧
├── background.jpg       # 背景画像（別途配置）
└── config/
    ├── actions.lua      # アクション定義（overlay pane, smart-splits, レイアウト等）
    ├── general.lua      # 基本設定（カラースキーム, マウス, Alt キー等）
    ├── font.lua         # フォント設定
    ├── window.lua       # ウィンドウ設定（背景, 起動時レイアウト）
    ├── tab.lua          # タブバー設定（タイトル表示ロジック）
    ├── keybinds.lua     # キーバインド設定（Leader, Key Tables）
    ├── statusbar.lua    # ステータスバー（モード表示, プロセス名, 日時）
    └── notification.lua # 通知設定（ベル音カスタマイズ）
```

## 主な特徴

### テーマ・外観

- **カラースキーム**: Tokyo Night Moon
- **背景**: 半透明ウィンドウ（70%透過）+ ぼかし効果 + 背景画像
- **タブバー**: カスタムスタイル（Nerd Fonts アイコン、プロセス/プロジェクト名自動表示）
- **ステータスバー**: モード表示（COPY/PANE/SEARCH）+ プロセス名 + プロジェクト名 + 日時
- **非アクティブペイン**: 暗転表示でアクティブペインを強調

### フォント

- **フォント**: UDEV Gothic 35NFLG (Bold)
- **サイズ**: 15pt / **行の高さ**: 1.2

### ペイン操作

- **smart-splits.nvim 統合**: `Alt+h/j/k/l` で Neovim ↔ WezTerm シームレス移動
- **pane_mode**: `Leader+p` で連続操作モード（移動/リサイズ/分割/swap/rotate）
- **overlay pane**: split + zoom でフローティング相当（lazygit, yazi, Claude Code）

### レイアウト

- **起動時**: サブモニターに自動移動、3ペイン分割で最大化
- **3ペインレイアウト** (`Cmd+t`):
  ```
  ┌──────┬──────┐
  │      │  2   │
  │  1   ├──────┤
  │      │  3   │
  └──────┴──────┘
  ```
- **8ペインレイアウト** (`Leader+8`): 4x2 グリッド
- **ワークスペース初期化** (`Leader+i`): ペイン構成に応じて nvim/claude/codex 等を自動起動

## キーバインド

**[CHEATSHEET.md](CHEATSHEET.md)** を参照。

主要なキーバインド:

| Namespace | 修飾キー | 用途 |
|-----------|---------|------|
| WezTerm OS | `Cmd` | タブ管理・ウィンドウ操作 |
| WezTerm カスタム | `Leader` (`Ctrl+Q`) | ペイン操作・overlay pane |
| ペイン移動 | `Alt+h/j/k/l` | smart-splits.nvim 統合 |
| ペインリサイズ | `Alt+Shift+H/J/K/L` | smart-splits.nvim 統合 |

## 通知設定

- WezTerm のビルトイン通知は無効化（Codex との重複防止）
- ベル音は `afplay` でカスタム音声を再生（`/System/Library/Sounds/Purr.aiff`）
- 連続通知を防ぐため最小間隔 1 秒

## 依存関係

- [UDEV Gothic](https://github.com/yuru7/udev-gothic) フォント（Nerd Fonts 版）
- 背景画像: `~/.config/wezterm/background.jpg`
- [glow](https://github.com/charmbracelet/glow) (チートシート表示用、optional)
