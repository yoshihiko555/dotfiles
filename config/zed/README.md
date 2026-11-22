# Zed

Vim モード、テーマ、言語別のフォーマッタは [settings.json](settings.json) で設定する。キー割り当ては [keymap.json](keymap.json) で変更する。

| キー | 操作 |
| --- | --- |
| `jj` | 挿入モードからノーマルモードに戻る |
| `Alt+h/j/k/l` | Neovim と同じく、左・下・上・右のペインへ移動する |
| `z` | プロジェクトパネルでツリーをすべて折りたたむ |

JavaScript などの整形には `prettier-local-first` を使う。整形対象のファイルがあるディレクトリから親へ順にたどり、最初に見つかった実行可能な `node_modules/.bin/prettier` を使う。見つからなければ Nix 版を使う。この選択順は [prettier-local-first.nix](../nix/packages/prettier-local-first.nix) で変更する。
