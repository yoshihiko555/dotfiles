# 個人用グローバル MCP

Figma・Pencil・drawio の共通定義を、個人用 Claude Code の `~/.claude.json` と Codex の `~/.codex/config.toml` に同期する。既定の同期先は固定で、`ccw` や `cxw` の環境（`CLAUDE_CONFIG_DIR` / `CODEX_HOME`）から実行しても個人用を指す。

## 定義の編集先

- [servers/](servers/) の `<名前>.json`: `type: http` と `url`、または `type: stdio` と `command`、任意の `args` / `env`。
  認証情報の実値は保存しない。
- [clients.json](clients.json): `claude` / `codex` ごとにサーバー名を列挙する。`{}` は共通定義を使用、
  `args` を指定すると配列全体を上書きする。Pencil の `--agent` はここで分ける。
- Codex では `type` を省き、管理対象は有効にする。既存の認証・タイムアウト・ツール設定は維持する。
  `env` は既存値と共通定義をマージする。共通定義からキーを外しても既存の環境変数は削除しない。
- stdio の空の `args` / `env`、Claude の省略時の `type: stdio`、Codex の省略時の `enabled: true` は同等。
  未対応フィールド、未定義サーバーへの参照、接続方式の変更はエラーにする。

## 登録状況と差分の確認

dotfiles のルートで実行する。mise 管理の Python 3.11 以上が必要。未導入なら `mise install python` で準備する。

| 確認したいこと | 読み取り専用コマンド |
|---|---|
| クライアントごとの登録状況（一致・追加候補・更新候補） | `task mcp-list` |
| 同期すると追加・更新されるサーバー | `task mcp-diff` |
| Figma だけの差分 | `task mcp-diff -- figma` |

表示するのはサーバー名と状態で、設定値は出力しない。差分があっても終了コードは `0`、設定不正や反映失敗は `1`。

比較・反映先を変える場合は明示する（親ディレクトリは作成済みであること）。

```sh
task mcp-diff -- --claude-config /tmp/example/claude.json --codex-config /tmp/example/config.toml
```

## 差分を反映する

確認した範囲に合わせて実行する。全件なら `task mcp-sync`、Figma だけなら `task mcp-sync -- figma` を使う。反映後に同じ範囲で `task mcp-diff` を実行し、追加・更新候補が消えたことを確認する。同期は MCP を起動しないため、接続・OAuth 認証は各クライアントで確認する。

両クライアントの設定案をメモリ上で作り、TOML の構文と設定全体の意味を検証してから反映する。
Codex の管理対象テーブルは書き直すため、その内部の整形・コメント位置は変わることがある。
通常の `[mcp_servers.NAME]` とそのサブテーブルを扱い、引用されたテーブル名などの未対応表記は
検証エラーで停止する。対象外の設定値は変更しない。

変更がある設定の一時ファイルとバックアップをすべて揃えてから、ファイルごとに置換する。symlink と既存ファイルの権限は保持する。反映直前に原本を再確認するが、各アプリとの排他はできないため、同期中は設定を同時編集しない。

## 途中失敗と復旧

片方のクライアントだけ反映される場合がある。途中で失敗したら、出力の「反映済み」とバックアップ先で更新されたクライアントを確認する。同期を完了するには原因を解消して再実行する。差分が消えた設定ファイルは書き込みを省略する。

バックアップは `~/.local/state/dotfiles/mcp-backups/<日時>.<ランダム値>/` に保存する。
`--backup-dir DIR` で変更可能。認証情報を含み得るため、バックアップ用ディレクトリとファイルは
所有者だけがアクセスできる権限で作成する。

- `<client>.before`: 更新前のファイル。
- `<client>.path`: symlink 解決後の反映先。
- `<client>.state`: 元のファイルがあれば `present`、新規作成なら `missing`。

復旧時はクライアントを終了し、`present` なら `.before` を `.path` の実体へ戻す。
`missing` なら同期が新規作成したファイルを確認して取り除く。
後から加えた設定まで戻るため、復旧前に現在のファイルとの差分を確認すること。

同期同士はバックアップ先の `.sync-lock` で排他する。強制終了後に残った場合は、同期が実行中でないことを確認してから空のロックディレクトリを取り除く。

## 管理対象外

プラグイン由来 MCP・その他の直接登録は移行対象外。
プラグイン単位の共通管理は [`../plugins/README.md`](../plugins/README.md) を参照。
定義から外したサーバーも自動削除しない。プラグインとの接続先重複の自動検出は未実装。
グローバル登録先ではない `claude/.mcp.json` とホームへの Nix リンク定義は廃止した。

## プロジェクト単位の登録と一時利用

Claude Code でプロジェクトのメンバーと共有する MCP は `claude mcp add --scope project` で登録する。
自分だけがそのプロジェクトで使うものは `--scope local`、全プロジェクトで使うものは
`--scope user` を選ぶ。OAuth が必要な接続先は、登録後に Claude Code の `/mcp` で認証する。

Codex 専用の追加 MCP は原則 `enabled = false` で登録する。そのセッションで使うときは
`codex -c mcp_servers.computer-use.enabled=true` のように登録名を指定して起動する。

## 同期スクリプトの保守・検証

[同期スクリプト](../../scripts/mcp-manage.py) は Python 標準ライブラリの JSON / TOML パーサーで検証する。通常の同期に外部 Python パッケージや jq / taplo は不要。

```sh
python3 scripts/tests/test-mcp-manage.py
bash scripts/tests/test-mcp-manage.sh
```

Python テストは標準ライブラリで動き、Task 経由の検証は Task がある場合に実行する。Bash 統合テストは結果照合に jq / taplo を使う。taplo は `TAPLO_BIN` で指定でき、未指定で PATH にもない場合は Nix から起動する。
