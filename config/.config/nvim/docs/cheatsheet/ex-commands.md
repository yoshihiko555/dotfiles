# キーマップ未割り当ての Ex コマンド

カスタムキーマップがない、または引数を指定して使い分ける価値がある `:` コマンドを記載する。
`<leader>ff` などで代替できる基本操作は [カスタムキーバインド](custom-keybinds.md) を参照。

コマンド名は大文字・小文字を区別する。

## CodeDiff

この設定ではサイドバイサイド表示が既定値。

| コマンド | 説明 |
|----------|------|
| `:CodeDiff` | 未コミットの変更をファイル一覧付きで表示 |
| `:CodeDiff main...` | `main` との共通祖先から作業ツリーまでを比較（未コミットを含む） |
| `:CodeDiff main...HEAD` | `main` から分岐後にコミットした変更だけを表示 |
| `:CodeDiff file HEAD` | 現在のファイルを `HEAD` と比較 |
| `:CodeDiff file main...` | 現在のファイルを PR と同じ基準で比較 |
| `:CodeDiff file old.txt new.txt` | 任意の2ファイルを比較 |
| `:CodeDiff dir old-dir new-dir` | 任意の2ディレクトリを比較 |
| `:CodeDiff history` | 直近50件のコミットを変更ファイル付きで表示 |
| `:CodeDiff history origin/main..HEAD` | 現在のブランチのコミットを順にレビュー |
| `:CodeDiff history HEAD~20 %` | 現在のファイルに関する直近の履歴を表示 |

Visual モードで行を選択して `:CodeDiff history` を実行すると、選択行を変更したコミットだけを追跡できる。

一時的に表示形式を変える場合は末尾に `--inline` または `--side-by-side` を付ける。

## FzfLua の未割り当て Picker

| コマンド | 説明 |
|----------|------|
| `:FzfLua commands` | 使用可能な Ex コマンドを検索 |
| `:FzfLua keymaps` | 有効なキーマップを検索 |
| `:FzfLua global` | ファイル・バッファ・LSPシンボルをまとめて検索 |
| `:FzfLua resume` | 直前の Picker と検索条件を再開 |
| `:FzfLua git_hunks` | Git の変更 hunk を一覧表示 |
| `:FzfLua git_blame` | 現在のファイルの blame を表示 |
| `:FzfLua git_branches` | Git ブランチを検索 |
| `:FzfLua git_stash` | Git stash を検索 |
| `:FzfLua marks` | マーク一覧を検索 |
| `:FzfLua jumps` | ジャンプリストを検索 |
| `:FzfLua changes` | 変更位置の履歴を検索 |
| `:FzfLua registers` | レジスタの内容を検索 |

## プラグイン・開発環境の管理

| コマンド | 説明 |
|----------|------|
| `:Lazy` | プラグインの状態確認・更新・同期 |
| `:Mason` | LSPサーバー・Formatter・Linterを管理 |
| `:ConformInfo` | 現在のファイルで使用する Formatter を確認 |
| `:Copilot status` | Copilot の接続・認証状態を確認 |
| `:Copilot enable` / `:Copilot disable` | Copilot を有効化 / 無効化 |

## 診断・トラブルシューティング

| コマンド | 説明 |
|----------|------|
| `:checkhealth` | Neovimとプラグイン全体を診断 |
| `:checkhealth vim.lsp` | LSPの状態を診断 |
| `:lua =vim.lsp.get_clients({ bufnr = 0 })` | 現在のバッファに接続中のLSPを表示 |
| `:messages` | エラーや通知の履歴を表示 |
| `:verbose map {key}` | キーマップを最後に定義した場所を表示 |
| `:verbose set {option}?` | オプションを最後に設定した場所を表示 |

例:

```vim
:verbose map <leader>ff
:verbose set formatoptions?
```

## 標準 Ex コマンド

### Undo 履歴を時間で移動

| コマンド | 説明 |
|----------|------|
| `:undolist` | Undo 履歴の分岐を表示 |
| `:earlier 5m` | 5分前の編集状態へ戻る |
| `:later 5m` | 5分後の編集状態へ進む |

`m` のほかに `s`（秒）、`h`（時間）、`d`（日）も指定できる。

### 行の整理

| コマンド | 説明 |
|----------|------|
| `:sort` | 選択範囲または全体を並べ替え |
| `:sort u` | 並べ替えながら重複行を削除 |
| `:g/{pattern}/d` | パターンに一致する行を削除 |
| `:v/{pattern}/d` | パターンに一致しない行を削除 |

Visual モードで選択して実行すると、自動的に `:'<,'>` の範囲指定が付く。

### 外部コマンド

| コマンド | 説明 |
|----------|------|
| `:terminal` | Neovim内でターミナルを開く |
| `:!{command}` | 外部コマンドを実行 |
| `:read !{command}` | 外部コマンドの出力を現在行の下へ挿入 |

例:

```vim
:read !date
:read !git rev-parse --show-toplevel
```

## コマンドを探す

| コマンド | 説明 |
|----------|------|
| `:FzfLua commands` | コマンド名や説明から検索 |
| `:command` | ユーザー定義コマンドを一覧表示 |
| `:help :{command}` | 標準コマンドのヘルプを表示 |

例: `:help :earlier`
