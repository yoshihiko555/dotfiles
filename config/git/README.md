# Git

| 変更したいもの | 編集先 |
| --- | --- |
| 全リポジトリ共通の設定（pull・push の挙動、delta の差分表示、git gtr の worktree 作成先など） | [config](config) |
| この dotfiles リポジトリ専用の設定（フックの読み込み先） | [dotfiles.config](dotfiles.config) |
| 全リポジトリで無視するファイルやディレクトリ（`.DS_Store`、`.worktrees/` など） | [ignore](ignore) |

## コミットフックの確認

[config](config) の `includeIf` が、このチェックアウトとその worktree で [dotfiles.config](dotfiles.config) を読み込む。コミット時には [pre-commit](../../.githooks/pre-commit) が整形対象ファイルのステージ済み内容を検査する。

このリポジトリ内で次のコマンドを実行し、設定元が `dotfiles.config`、値が `.githooks` になっていることを確認する。

```sh
git config --show-origin --get core.hooksPath
```
