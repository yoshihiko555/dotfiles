# WezTerm Configuration

[WezTerm](https://wezfurlong.org/wezterm/) のカスタム設定ファイル集です。

## 📁 ファイル構成

```
wezterm/
├── wezterm.lua          # メインエントリーポイント
├── background.jpg       # 背景画像（別途配置）
└── config/
    ├── general.lua      # 基本設定
    ├── font.lua         # フォント設定
    ├── window.lua       # ウィンドウ設定
    ├── tab.lua          # タブバー設定
    ├── keybinds.lua     # キーバインド設定
    └── notification.lua # 通知設定
```

## ✨ 主な特徴

### テーマ・外観

- **カラースキーム**: Tokyo Night Moon
- **背景**: 半透明ウィンドウ（70%透過）+ ぼかし効果 + 背景画像
- **タブバー**: カスタムスタイル（Nerd Fonts アイコン使用）

### フォント

- **フォント**: UDEV Gothic 35NFLG (Bold)
- **サイズ**: 15pt
- **行の高さ**: 1.2

### 起動時の動作

- サブモニター（DELL G2422HS）に自動移動
- 3ペイン分割で最大化起動
  ```
  ┌──────┬──────┐
  │      │  2   │
  │  1   ├──────┤
  │      │  3   │
  └──────┴──────┘
  ```

## ⌨️ キーバインド

### リーダーキー

| キー       | 説明                            |
| ---------- | ------------------------------- |
| `Ctrl + q` | リーダーキー（2秒タイムアウト） |

### タブ操作

| キー                         | 説明                    |
| ---------------------------- | ----------------------- |
| `Cmd + t`                    | 新規タブ（3ペイン分割） |
| `Cmd + w`                    | 現在のペインを閉じる    |
| `Cmd + Shift + w`            | 現在のタブを閉じる      |
| `Ctrl + Tab`                 | 次のタブ                |
| `Ctrl + Shift + Tab`         | 前のタブ                |
| `Cmd + {` / `Cmd + }`        | タブ移動                |
| `Cmd + 1-9`                  | タブ番号で直接移動      |
| `Ctrl + Shift + PageUp/Down` | タブの順序変更          |

### ペイン操作（Cmd系）

| キー                        | 説明                 |
| --------------------------- | -------------------- |
| `Cmd + d`                   | 水平分割             |
| `Cmd + Shift + d`           | 垂直分割             |
| `Ctrl + z`                  | ペインズーム切り替え |
| `Ctrl + Shift + 矢印`       | ペイン移動           |
| `Ctrl + Shift + Alt + 矢印` | ペインサイズ調整     |

### ペイン操作（Leader系）

| キー               | 説明                         |
| ------------------ | ---------------------------- |
| `Leader + d`       | 垂直分割                     |
| `Leader + /`       | 水平分割                     |
| `Leader + h/j/k/l` | ペイン移動（vim風）          |
| `Leader + H/J/K/L` | ペインサイズ調整（vim風）    |
| `Leader + p`       | ペイン操作モード（連続操作） |

### ペイン操作モード（`Leader + p` で入る）

| キー                     | 説明                 |
| ------------------------ | -------------------- |
| `h/j/k/l`                | ペイン移動           |
| `H/J/K/L`                | ペインサイズ調整     |
| `d`                      | 垂直分割             |
| `/`                      | 水平分割             |
| `x`                      | ペインを閉じる       |
| `z`                      | ペインズーム切り替え |
| `Escape` / `Enter` / `q` | モード終了           |

### コピー・ペースト

| キー                   | 説明             |
| ---------------------- | ---------------- |
| `Cmd + c`              | コピー           |
| `Cmd + v`              | ペースト         |
| `Ctrl + Shift + x`     | コピーモード開始 |
| `Ctrl + Shift + Space` | クイック選択     |
| `Cmd + f`              | 検索             |

### コピーモード（vim風）

| キー           | 説明         |
| -------------- | ------------ |
| `h/j/k/l`      | カーソル移動 |
| `w/b/e`        | 単語単位移動 |
| `0/$`          | 行頭/行末    |
| `g/G`          | 先頭/末尾    |
| `v`            | 選択開始     |
| `V`            | 行選択       |
| `Ctrl + v`     | 矩形選択     |
| `y`            | コピー＆終了 |
| `q` / `Escape` | モード終了   |

### フォントサイズ

| キー      | 説明             |
| --------- | ---------------- |
| `Cmd + =` | フォント拡大     |
| `Cmd + -` | フォント縮小     |
| `Cmd + 0` | フォントリセット |

### スクロール

| キー                  | 説明                   |
| --------------------- | ---------------------- |
| `Shift + PageUp/Down` | ページスクロール       |
| `Cmd + k`             | スクロールバッククリア |
| `Ctrl + l`            | 画面クリア（履歴保持） |

### ウィンドウ・その他

| キー               | 説明                   |
| ------------------ | ---------------------- |
| `Cmd + n`          | 新規ウィンドウ         |
| `Alt + Enter`      | フルスクリーン切り替え |
| `Cmd + h`          | アプリケーションを隠す |
| `Cmd + m`          | ウィンドウを隠す       |
| `Cmd + q`          | アプリケーション終了   |
| `Cmd + r`          | 設定リロード           |
| `Ctrl + Shift + p` | コマンドパレット       |
| `Ctrl + Shift + l` | デバッグオーバーレイ   |

## 🔔 通知設定

- WezTerm のビルトイン通知は無効化（Codex との重複防止）
- ベル音は `afplay` でカスタム音声を再生（`/System/Library/Sounds/Purr.aiff`）
- 連続通知を防ぐため最小間隔 1 秒

## 📋 依存関係

- [UDEV Gothic](https://github.com/yuru7/udev-gothic) フォント（Nerd Fonts 版）
- 背景画像: `~/.config/wezterm/background.jpg`

## 🔧 インストール

```bash
# シンボリックリンクを作成
ln -sf ~/.dotfiles/config/.config/wezterm ~/.config/wezterm

# または dotfiles 管理ツールを使用
```

## 📝 カスタマイズ

### 背景画像を変更

[config/window.lua](config/window.lua) の `background` セクションを編集:

```lua
config.background = {
  {
    source = {
      File = wezterm.home_dir .. "/.config/wezterm/your-image.jpg"
    },
    hsb = {
      brightness = 0.2,  -- 明るさ調整
    }
  }
}
```

### カラースキームを変更

[config/general.lua](config/general.lua) を編集:

```lua
color_scheme = "Your Scheme Name",
```

### 起動時のモニター位置を変更

[config/window.lua](config/window.lua) の AppleScript を編集:

```lua
wezterm.run_child_process({
  "osascript", "-e", [[
    tell application "System Events"
      tell process "WezTerm"
        set position of window 1 to {X座標, Y座標}
      end tell
    end tell
  ]]
})
```
