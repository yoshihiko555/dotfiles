# Yazi 操作早見表

別の場所を少し覗くなら herdr の popup、そこで作業を続けるならシェルの `y`、編集中のファイルの隣を開くなら Neovim の `Space -` を使う。

| 場所 | キー・コマンド | 操作 |
|---|---|---|
| herdr | `Ctrl-Q` → `y` | 今のペインのディレクトリを popup で開く。`q` で元のペインに戻る |
| zsh | `y` / `y ~/Downloads` | 指定した場所で開く。`q` で終了するとシェルも最後のディレクトリへ移る |
| Neovim | `Space -` / `:Yazi` | 現在のファイルの場所を開く。選んだファイルは元の Neovim に開く |
| Yazi | `j` / `k` / `h` | 下へ・上へ・親ディレクトリへ移動 |
| Yazi | `l` | カーソル位置のディレクトリに入る、またはファイルを開く |
| Yazi | `z` / `Z` | `z` は fzf でファイルやディレクトリを検索。`Z` は zoxide の訪問履歴から移動 |
| Yazi | `Space` | 項目の選択を切り替える |
| Yazi | `O` | 選択したファイルを開くアプリや操作を選ぶ |
| Yazi | `d` / `D` | `d` はゴミ箱へ移動。`D` は完全に削除 |
| Yazi | `.` / `F1` | 隠しファイルの表示切り替え・キーのヘルプ |

画像・PDF・Markdown は選ぶだけで右側にプレビューが出る。Markdown は glow で整形する。Mac の popup でテキストを開くと、その中で Neovim が起動し、`:q` で Yazi に戻る。画像や PDF は既定の macOS アプリで開く。

この早見表は herdr の `Ctrl-Q` → `i` でも「yazi」で検索できる。

## 設定の変更先

| 変更したいもの | ファイル |
|---|---|
| `l` でディレクトリに入る・ファイルを開く動作 | [keymap.toml](keymap.toml) で `smart-enter` を割り当てる |
| Markdown のプレビュー | [yazi.toml](yazi.toml) の `prepend_previewers` で、`piper` が呼ぶ `glow` の引数を指定する |
| ファイルやディレクトリの Git 状態表示 | [yazi.toml](yazi.toml) の `prepend_fetchers` で対象を指定し、[init.lua](init.lua) で `git` プラグインを初期化する |
| 枠やカーソル行などの配色 | [theme.toml](theme.toml) で TokyoNight Moon の色を設定する |
| プラグインの種類とバージョン | [package.toml](package.toml) で復元するリビジョンを固定する |

## MacBook の初回セットアップ

1. `nxs` を実行する。Yazi 本体と Markdown 表示に使う `glow` が入り、`~/.config/yazi` がこのディレクトリにリンクされる。[パッケージ一覧](../nix/home/packages.nix)・[MacBook のリンク設定](../nix/hosts/macbook/dotfiles.nix)
2. `ya pkg install` を実行する。[package.toml](package.toml) に固定した `git`・`smart-enter`・`piper` が `plugins/` に復元される。このディレクトリは Git 管理外なので、新しいチェックアウトではこの手順が必要になる。
