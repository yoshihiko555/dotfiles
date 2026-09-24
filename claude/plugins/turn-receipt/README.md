# turn-receipt

ターンごとに「編集・実行・curl」の件数をフッターへ出す Claude Code の mod。

- 編集したのに何も実行していないターンは `⚠ no run` を付け、入力欄に「run the tests and show the output」を提案する
- 実行せずに完了を宣言した（fixed / 修正しました など）ら、次の spinner に `unverified claim pending` を出す
- 破壊的な Bash（`rm -r`、`git push -f` など）はツール表示を折りたたまない
- `/turn-receipt on|off|status`、`CLAUDE_MODS_DISABLE=turn-receipt` で停止

「実行」は読み取り系（`ls`・`grep`・`jq` など）とファイル・git の操作（`cp`・`mkdir`・`git` など）以外のすべての Bash を数える。

## 由来

[yash-gadodia/claude-mods](https://github.com/yash-gadodia/claude-mods) の `receipt`（コミット `f4c1c751f679`、MIT）を元に、実行の判定と日本語の完了宣言の検知を変えたもの。上流の更新は追従しない。

## 開発

```bash
CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1 claude plugin test claude/plugins/turn-receipt
claude plugin validate claude/plugins/turn-receipt
```
