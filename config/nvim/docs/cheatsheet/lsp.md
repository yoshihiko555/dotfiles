# LSP チートシート

**Leader: `Space`** | **Prefix: `<leader>l`** | Go / Python / TypeScript・JavaScript / Lua

## ナビゲーション

| キー | 操作 |
|------|------|
| `<leader>lf` | 定義・参照・実装などをまとめて表示 |
| `<leader>ld` | 定義を表示 |
| `<leader>lD` | 宣言を表示 |
| `<leader>lr` | 参照箇所を表示 |
| `<leader>li` | 実装を表示 |
| `<leader>lt` | 型定義を表示 |
| `<leader>lh` | 型情報・ドキュメントを表示 |
| `<leader>lp` | 関数の引数情報を表示 |
| `Ctrl+o` / `Ctrl+i` | ジャンプ履歴を戻る / 進む |

## 編集・診断

| キー | 操作 |
|------|------|
| `<leader>ln` | 名前を変更 |
| `<leader>la` | 修正候補を表示 |
| `<leader>lc` | コードレンズを実行 |
| `<leader>le` | 現在行の診断を表示 |
| `<leader>lj` / `<leader>lk` | 次 / 前の診断へ移動 |
| `<leader>fd` | 現在のファイルの診断を検索 |
| `<leader>xx` / `<leader>xX` | 全体 / 現在のファイルの診断を表示 |

## プロジェクトでのリント確認

Go・TypeScript・Python の実プロジェクトでの結果は、移行記録では未記入。
対象ファイルにプロジェクトのルールに反する箇所を用意し、保存して診断が出るのを待つ。
`:lua =vim.diagnostic.get(0)` で該当行の診断と `source` を確認する。変更を元に戻して保存し、診断が消えることを確かめる。

| 対象 | 確認する設定 |
|---|---|
| Go | golangci-lint が対象ファイルのパッケージで有効なルールを使う。 |
| TypeScript | プロジェクトに ESLint の設定とローカルの `node_modules/.bin/eslint` がある場合に実行する。 |
| Python | Ruff が対象プロジェクトで有効なルールを使う。 |

実行のタイミングと言語ごとの割り当ては [nvim-lint の設定](../../lua/plugins/lint.lua)を参照。

## シンボル・文字列検索

| キー | 範囲 | 操作 |
|------|------|------|
| `<leader>ls` | 現在のファイル | シンボルを検索 |
| `<leader>lS` | プロジェクト全体 | シンボルを検索 |
| `<leader>fg` | プロジェクト全体 | 文字列を検索 |

## FzfLua 一覧内

| キー | 操作 |
|------|------|
| 文字入力 | 候補を絞り込む |
| `Ctrl+j` / `Ctrl+k` | 次 / 前の候補を選択 |
| `Enter` | 選択した場所を開く |
| `Esc` | 一覧を閉じる |

## LSP Finder ラベル

| ラベル | 内容 |
|--------|------|
| `def` | 定義 |
| `decl` | 宣言 |
| `ref` | 参照箇所 |
| `impl` | 実装 |
| `tdef` | 型定義 |

## which-key

| キー | 操作 |
|------|------|
| `<leader>l` | LSP操作を表示 |
| `<leader>?` | 現在のキーマップを表示 |

## 確認コマンド

| コマンド | 確認内容 |
|----------|----------|
| `:checkhealth vim.lsp` | LSPの状態 |
| `:lua =vim.lsp.get_clients({ bufnr = 0 })` | 現在のファイルへのLSP接続 |
| `:messages` | `No references found` などのメッセージ |
