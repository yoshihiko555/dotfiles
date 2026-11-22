# プロジェクトを選んでタスクを実行する（`tk`）

go-task (Taskfile) のタスクを、プロジェクトを明示したうえで実行するワークフロー。

## 使い方

1. Alfred で `tk` と入力すると、Taskfile を持つ ghq リポジトリが並ぶ
2. プロジェクトを選択すると、そのプロジェクトの desc 付きタスクが並ぶ（変数・引数のヒントを subtitle に表示）
3. タスクを選択すると、実行方法（バックグラウンド / ターミナル）を選ぶ画面になる。
   ここで入力欄に `KEY=VALUE` や `-- 追加引数` を打つと、実行対象の title に反映される
4. 選択した方法でタスクが実行される（入力した引数付きで `task タスク名 ...` が呼ばれる）

## 3 段階に分けている理由（誤発火防止）

`tk` の後にタスク名だけを打つ方式だと、同名タスクを持つ別プロジェクトで
誤って実行してしまう事故が起きやすい。そのため
「プロジェクト選択 → タスク選択 → 実行方法選択」の 3 段階にし、
常に `プロジェクト名 › タスク名` の形式で対象を明示してから実行する。

## 対象プロジェクト

`ghq list --full-path` の結果のうち、直下に
`Taskfile.yml` / `Taskfile.yaml` / `taskfile.yml` / `taskfile.yaml`
のいずれかを持つものだけを一覧する。

## タスク一覧

- `task --list --json`（desc ありのみ。`--list-all` は使わない）
- includes 経由で別ファイルに定義されたタスクは、サブタイトル末尾に
  `[taskfiles/xxx.yml]` のように相対パスを表示する

## タスク引数

- タスク選択画面で、各タスクに対し `task --summary <name>` を実行して既定値を取得しつつ、
  Taskfile 本文のタスク定義ブロックからそのタスク自身が持つ `vars:` 直下のキーと
  `requires: vars:` の必須変数・`.CLI_ARGS` 参照の有無を調べ、subtitle 末尾にヒントを付ける
  - `task --summary` の `vars:` にはトップレベル vars や include 元の変数も混ざるため、
    既定値の取得にのみ使い、ヒント表示はタスク自身が定義した変数だけに絞り込む
  - 例: `⌨ TARGET=all`（変数と既定値）／`⌨ NAME=<必須>`（既定値なしの必須変数）／
    `⌨ -- <args>`（`.CLI_ARGS` を使うタスク。複数ヒントはスペース区切りで並ぶ）
  - タスク自身に `vars:` も `requires:` も無ければヒントは付かない
- 続く「実行方法を選ぶ」画面の入力欄に、そのヒントに従って引数を打つ
  - `KEY=VALUE` は go-task の変数として渡る（例: `TARGET=claude`）
  - `--` 以降はそのまま `task` の CLI 引数（`.CLI_ARGS`）として渡る
    （例: `-- --dry-run`）
  - 入力はシェルと同じ規則（`shlex`）でトークン化するため、スペースを含む値は
    引用符で囲む
  - 必須変数が未指定だと `valid: false` になり実行できない
- タスク側で使い方を案内したい場合は Taskfile に `summary:` を書く。
  `task --summary` で確認できる文面がそのまま「実行方法を選ぶ」画面の
  subtitle に出る（例: `adopt-settings` の `TARGET=all|claude|...` 案内）
- `desc` または `summary` に `KEY=a|b|c`（値は 2 つ以上）と書くと、そのタスク自身の
  `vars:`／`requires: vars:` にある変数に限り、値の選択肢として「実行方法を選ぶ」
  画面に列挙される（入力欄が空のときは値ごとの item、`KEY=` の途中まで打つと
  前方一致で絞り込む。既定値と一致する値には `(既定)` が付き先頭に並ぶ）
  - 列挙変数が 2 つ以上あるタスクでも選択肢化するのは最初の 1 つだけで、
    残りは従来どおり自由入力になる

## `config.json`（`$alfred_workflow_data/config.json`）

`Open-VS-or-IT` の `favorites.json` と同様の方式。ただし本ワークフローは
bundleid を持つため `alfred_workflow_data` は Alfred のサポートフォルダ
（`~/Library/Application Support/Alfred/Workflow Data/com.yoshihiko.taskfile/`）を
指し、repo 管理外・端末ローカルの設定になる（`favorites.json` のように
ワークフローディレクトリ直下には置かれない）。

```json
{
  "excludes": ["ai-orchestra"],
  "extras": [{ "name": "手動プロジェクト", "path": "/path/to/project" }],
  "overrides": { "baton": { "name": "Baton改名" } },
  "terminal": ["dotfiles/nix-fmt", "learno/backend:dev"]
}
```

| キー | 内容 |
|---|---|
| `excludes` | 一覧から除外する（basename、または owner を除いた相対パス） |
| `extras` | ghq 管理外のプロジェクトを追加（Taskfile の有無は検査しない） |
| `overrides` | 表示名を変更する（キーは owner を除いた相対パス。単純な `owner/repo` 構成では basename と一致する） |
| `terminal` | `"プロジェクト名/タスク名"` または `"プロジェクト名/*"` で、実行方法の選択肢でターミナル実行を先頭に出し、バックグラウンド側に `⚠ 設定でターミナル推奨` を付ける（対話・sudo・長時間タスク向け）。プロジェクト名は `overrides` 適用後の表示名で照合するため、改名すると `terminal` 側のキーも合わせる必要がある |

## 実行方法

| 方法 | 動作 |
|---|---|
| バックグラウンド | `nohup` 相当で実行し、開始・終了（終了コード付き）を通知する |
| ターミナル | herdr のワークスペース `tasks` にタブ `プロジェクト名:タスク名` を作り、プロジェクトのディレクトリで `task タスク名 引数...` を実行して Ghostty を前面に出す（`container` の `shell` と同じ動線。タスク終了後もシェルが残るので出力を確認できる。引数トークンはシェル注入を避けるため `printf %q` でクォートする） |

## ログ

バックグラウンド実行の標準出力・標準エラーは
`$alfred_workflow_cache/logs/プロジェクト名-タスク名-YYYYmmdd-HHMMSS.log`
（引数を指定した場合は `プロジェクト名-タスク名-引数-YYYYmmdd-HHMMSS.log`）
に保存する。失敗時は通知にログパスを含める。

**依存:** `go-task`（`task` コマンド。Nix 管理）。

[Alfred のワークフロー一覧](../README.md)
