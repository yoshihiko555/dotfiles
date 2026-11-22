# WezTerm の設定

[WezTerm](https://wezfurlong.org/wezterm/) は tmux と組み合わせて使うサブ端末。常用端末は Ghostty + herdr。
ウィンドウの配置は AeroSpace、ターミナル内のセッション・ウィンドウ・ペインは tmux が管理する。
Cmd キーの操作は [WezTerm のチートシート](CHEATSHEET.md)、tmux の設定と操作は [tmux の README](../tmux/README.md) を参照。

## 起動

通常の GUI 起動では、tmux の `default` セッションがあれば接続し、初回はセッションを作って `baton` を起動する。
外部から起動コマンドを指定した場合は、そのコマンドを実行する。起動時の作業ディレクトリは指定があればその値、既定はホームディレクトリ。[起動処理](config/window.lua)

## 表示と設定ファイル

[wezterm.lua](wezterm.lua) が各ファイルの設定を読み込む。変更したい項目に応じて次のファイルを編集する。

| 項目 | 設定ファイル | 現在の設定 |
|---|---|---|
| 配色・タブバー | [general.lua](config/general.lua) | Tokyo Night Moon。tmux がウィンドウを管理するため、タブバーは非表示 |
| 背景 | [window-appearance.lua](config/window-appearance.lua) | ウィンドウの不透明度は 70%。macOS のぼかしと背景画像（`~/.config/wezterm/background.jpg`）を設定 |
| フォント | [font.lua](config/font.lua) | [UDEV Gothic](https://github.com/yuru7/udev-gothic) 35NFLG Bold、15pt、行の高さ 1.2 |
| キー割り当て | [keybinds.lua](config/keybinds.lua) | クリップボードやフォント操作は WezTerm が処理し、ペイン分割などは tmux のキー列に変換 |
| 通知音 | [notification.lua](config/notification.lua) | ベルを受けると macOS の効果音 Purr を再生 |

### タブバーを非表示にしてもタイトルを設定する理由

タブバーが非表示でも、WezTerm は内部でタブの状態を更新する。再描画時のちらつきを抑えるため、
`wezterm.lua` の `format-tab-title` はタブ番号を使った安定したタイトルを返す。`update-status` は左右のステータスを空にする。

## tmux 移行前の設定

切り替えの経緯と当時の検証結果は [tmux 移行記録](../tmux/docs/MIGRATION.md) にある。
旧設定のバックアップは 2026-07-30 に削除した。削除前の内容は Git 履歴から確認できる。

```bash
# 旧設定のファイル一覧
git ls-tree -r --name-only fbf993a -- config/.config/wezterm.bak
# 当時のエントリーポイントの内容
git show fbf993a:config/.config/wezterm.bak/wezterm.lua
```
