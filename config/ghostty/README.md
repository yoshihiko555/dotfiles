# Ghostty

Ghostty は常用のターミナル。起動時の最初のウィンドウでは、[config](config) の `initial-command` が `/bin/zsh -lic herdr` を実行する。

| 変更したいもの | 編集先 |
| --- | --- |
| テーマ、フォント、背景画像の表示、起動コマンド | [config](config) |
| 背景画像そのもの | [background.png](background.png) |
| herdr に送るキー（`Cmd+D` でペイン分割、`Cmd+1`〜`9` でタブ切り替えなど） | [herdr.conf](herdr.conf) |

設定を編集したら、Ghostty で `Cmd+R` を押して再読み込みする。起動コマンドを変えた場合は Ghostty を起動し直して確認する。

herdr 側の操作とキーバインドの編集先は [herdr の README](../herdr/README.md) を参照。
