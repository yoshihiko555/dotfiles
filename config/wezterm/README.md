# WezTerm Configuration (tmux-first)

[WezTerm](https://wezfurlong.org/wezterm/) を GUI レンダラーとして使用。
タブ/ペイン/セッション管理は tmux に統一。

## ファイル構成

```
wezterm/
├── wezterm.lua            # メインエントリーポイント（~/.config/use-herdr の有無で tmux/herdr を切り替え）
├── CHEATSHEET.md          # キーバインド一覧
├── background.jpg         # 背景画像
└── config/
    ├── general.lua           # 基本設定（カラースキーム, マウス, タブバー無効化）
    ├── font.lua              # フォント設定
    ├── window-appearance.lua # ウィンドウの見た目（背景, 透過, 装飾。tmux/herdr 共通）
    ├── window.lua            # ウィンドウ設定（tmux 自動起動）※既定
    ├── window-herdr.lua      # ウィンドウ設定（herdr 自動起動）※切り替え時のみ
    ├── keybinds.lua          # キーバインド（Cmd→tmux 変換 + GUI 操作）※既定
    ├── keybinds-herdr.lua    # キーバインド（Cmd→herdr 変換。keybinds.lua を土台に一部差し替え）※切り替え時のみ
    ├── notification.lua      # 通知設定（ベル音カスタマイズ）
    └── baton-status.lua      # symlink → baton リポジトリ（別リポジトリ管理）
```

## 主な特徴

### WezTerm の役割（GUI レンダラーに限定）

- **カラースキーム**: Tokyo Night Moon
- **背景**: 半透明ウィンドウ（70%透過）+ ぼかし効果 + 背景画像
- **フォント**: UDEV Gothic 35NFLG (Bold), 15pt, 行の高さ 1.2
- **起動時**: tmux default セッションに自動接続 + ウィンドウ最大化
- **タブバー**: 無効化（tmux がウィンドウを管理）

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

## tmux ⇔ herdr 切り替え（試用中）

既定は tmux + baton。切り替えはリポジトリ外のファイル `~/.config/use-herdr` の
**有無**だけで行う。中身は見ない。存在そのものが意思表示。
ファイルが無いのが正常系なので、読めない場合もすべて既定（tmux）に倒れる。

| `~/.config/use-herdr` | 読み込むファイル |
|---|---|
| 無い | `config/window.lua` + `config/keybinds.lua`（既定） |
| ある | `config/window-herdr.lua` + `config/keybinds-herdr.lua` |

### herdr に切り替える

```bash
touch ~/.config/use-herdr
```

作ったあと、WezTerm を**完全に終了して再起動**する。`gui-startup`
（起動時に tmux/herdr のどちらを立ち上げるか）は WezTerm プロセス起動時に
一度だけ実行されるため、`Cmd+R`（ReloadConfiguration）ではキーバインドや
見た目は切り替わっても、起動済みの多重化バックエンドは切り替わらない。

### tmux（既定）に戻す

```bash
rm ~/.config/use-herdr
```

同様に WezTerm を完全に終了して再起動する。これだけで元の tmux + baton の
挙動に戻る（repo 側の変更は不要）。

### 実装メモ

- 見た目（背景・透過・装飾・タイトルバー）は `config/window-appearance.lua`
  に切り出し、`config/window.lua`（tmux 版）と `config/window-herdr.lua`
  （herdr 版）の両方から require することで二重管理を避けている。
  `gui-startup` ハンドラ（起動コマンドのみ）だけが両ファイルで異なる。
- herdr の起動 (`config/window-herdr.lua`) は tmux 版と同じく `zsh -lic` 経由
  （ログイン+対話シェル）でコマンドを実行する。herdr 配下のエージェント
  ペインが呼び出すコマンド（claude/codex 等）や herdr 自身の config.toml 内
  popup コマンドも同じ PATH 解決に依存しているため、これに揃えている。
- `config/keybinds-herdr.lua` は `config/keybinds.lua` を土台に、herdr 側で
  送出先が変わるキーだけ差し替える構造（詳細は同ファイル内コメント参照）。

## キーバインド

**[CHEATSHEET.md](CHEATSHEET.md)** を参照。tmux 版（既定）の内容。herdr 版の
差分は `config/keybinds-herdr.lua` のコメントを参照。

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
