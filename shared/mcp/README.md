# 個人用グローバル MCP

Figma・Pencil・drawio を1件ずつ定義し、Claude Code / Codex に同期する。
実装は Bash 3.2 対応の Shell。JSON は jq、TOML の読み取り・検証は taplo を利用する。
taplo が PATH にない場合は `nix shell --inputs-from config/nix nixpkgs#taplo` で補う。
任意の実行ファイルは `TAPLO_BIN` でも指定できる。Python は不要。

## 定義

- `servers/<名前>.json`: `type: http` と `url`、または `type: stdio` と `command`、任意の `args` / `env`。
  認証情報の実値は保存しない。
- `clients.json`: `claude` / `codex` ごとにサーバー名を列挙する。`{}` は共通定義を使用、
  `args` を指定すると配列全体を上書きする。Pencil の `--agent` はここで分ける。
- Codex では `type` を省き、管理対象は有効にする。既存の認証・タイムアウト・ツール設定は維持する。
  `env` は既存値と共通定義をマージする。共通定義からキーを外しても既存の環境変数は削除しない。
- stdio の空の `args` / `env`、Claude の省略時の `type: stdio`、Codex の省略時の `enabled: true` は同等。
  未対応フィールド、未定義サーバーへの参照、接続方式の変更はエラーにする。

## 操作

```sh
task mcp-list
task mcp-diff
task mcp-sync
task mcp-sync -- figma
bash scripts/tests/test-mcp-manage.sh
```

個人用の `~/.claude.json` と `~/.codex/config.toml` が対象。
`CLAUDE_CONFIG_DIR` / `CODEX_HOME` には追従しない。会社用 `ccw` は対象外。
比較・反映先を変える場合は明示する（親ディレクトリは作成済みであること）。

```sh
task mcp-diff -- --claude-config /tmp/example/claude.json --codex-config /tmp/example/config.toml
```

一覧・差分は実設定を更新しない。値は表示せず、サーバー名と追加・更新の区別を表示する。
MCP 自体は起動しないので、接続・OAuth 認証は各クライアントで別途確認する。
終了コードは成功 `0`（差分ありも含む）、設定不正や反映失敗 `1`。

## 反映と復旧

両クライアントの設定案を一時ディレクトリで作り、TOML の構文と設定全体の意味を検証してから反映する。
Codex の管理対象テーブルは書き直すため、その内部の整形・コメント位置は変わることがある。
通常の `[mcp_servers.NAME]` とそのサブテーブルを扱い、引用されたテーブル名などの未対応表記は
検証エラーで停止する。対象外の設定値は変更しない。

バックアップは `~/.local/state/dotfiles/mcp-backups/<日時>.<ランダム値>/` に保存する。
`--backup-dir DIR` で変更可能。認証情報を含み得るため、バックアップ用ディレクトリとファイルは
所有者だけがアクセスできる権限で作成する。

- `<client>.before`: 更新前のファイル。
- `<client>.path`: symlink 解決後の反映先。
- `<client>.state`: 元のファイルがあれば `present`、新規作成なら `missing`。

復旧時はクライアントを終了し、`present` なら `.before` を `.path` の実体へ戻す。
`missing` なら同期が新規作成したファイルを確認して取り除く。
後から加えた設定まで戻るため、復旧前に現在のファイルとの差分を確認すること。

設定ごとの置換は同じディレクトリの一時ファイルから行い、symlink と既存ファイルの権限を保持する。
反映直前にも原本との差分を確認するが、各アプリとの完全な排他はできないため、設定を同時編集しないこと。
2ファイル全体のトランザクションではない。途中で権限エラーなどが起きたら、反映済み表示とバックアップを確認し、
原因を解消して再実行する。差分なしなら書き込みを省略する。
同期同士はバックアップ先の `.sync-lock` で排他する。強制終了後に残った場合は実行中でないことを確認して空ディレクトリを除去する。

## 管理対象外

プラグイン由来 MCP・cocoindex-code・その他の直接登録は移行対象外。
定義から外したサーバーも自動削除しない。プラグインとの接続先重複の自動検出は未実装。
グローバル登録先ではない `claude/.mcp.json` とホームへの Nix リンク定義は廃止した。
プロジェクト単位で登録されている cocoindex-code は変更しない。
