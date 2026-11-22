# lazygit の設定

lazygit でステージ、コミット、ブランチ操作を行う。よく使うキーは [操作チートシート](CHEATSHEET.md) を参照。

## 起動

| 起動元 | 操作 |
|---|---|
| 対話 zsh | `lg` または `lazygit` |
| herdr / tmux | `Ctrl+Q` に続けて `g` を押し、ポップアップを開く |

herdr で操作表を見るには、`Ctrl+Q` → `i` で一覧を開き、「lazygit チートシート」を選ぶ。

MacBook では Home Manager がこのディレクトリを `~/.config/lazygit` にリンクする。どちらのポップアップも対話 zsh を起動し、シェルからの起動と同じ `lazygit` 関数を通る。この関数は lazygit に `XDG_CONFIG_HOME=$HOME/.config` を渡す。[MacBook の設定](../nix/hosts/macbook/dotfiles.nix)・[zsh 関数](../../shell/zsh/functions.zsh)・[herdr の設定](../herdr/config.toml)・[tmux の設定](../tmux/conf/popup.conf)

設定を編集したら lazygit を開き直す。別のシェルから起動して表示が異なる場合は、そのシェルで `lazygit --print-config-dir` を実行すると、実際の参照先が分かる。

## 表示と差分

- 表示言語は日本語。ファジーフィルターと、ファイル一覧の追加・削除行数を有効にしている。TokyoNight Moon の配色を使い、選択中のパネル枠はシアンで表示する。画面下のヒントを隠す場合は `gui.showRandomTip` を `false` にする。[config.yml](config.yml)
- 差分は `|` で delta の通常表示と横並び表示を切り替える。呼び出すコマンドは `git.diffRenderers`、差分の色は Git 設定の `[delta]`、lazygit 用のハンク見出しは `[delta "lazygit"]` で変更する。[lazygit の設定](config.yml)・[Git の設定](../git/config)

## Antigravity でコミットメッセージを作る

1. ファイルパネルでコミットに含める変更をステージする。
2. 同じパネルで `Ctrl+G` を押す。独自コマンドがステージ済みの差分（`git diff --cached`）を Antigravity CLI に渡し、日本語の Conventional Commits 形式のメッセージを生成する。
3. Git のエディタで文面を確認・編集し、保存して閉じるとコミットする。Neovim で中止するには `:cq` で閉じる。

実行には `agy` と `jq` が必要。CLI の場所は `AGY_BIN`、モデルは `AGY_MODEL` で上書きできる。[独自コマンドの定義](config.yml)
