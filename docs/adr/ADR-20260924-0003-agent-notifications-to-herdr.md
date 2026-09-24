# ADR-20260924-0003: エージェントの完了・承認待ちの通知を herdr に一本化する

- ステータス: 採用
- 決定日: 2026-09-24
- 関連: [ADR-20260922-0001](ADR-20260922-0001-herdr-migration-trial.md)（herdr の採用）

## 背景

herdr を採用した後も、Claude Code の hook（`claude/claude_message.sh`）と
Codex の notify（`codex/codex_message.sh`）が、それぞれ独自に OS 通知と通知音を出していた。
herdr 側にも同じ出来事の通知があるため、herdr 内では二重になっていた。

| | hook / notify | herdr |
|---|---|---|
| 音 | afplay（Glass / Ping / Basso）。常に鳴る | `[ui.sound]`。見ていない workspace のときだけ |
| OS バナー | osascript（スクリプトエディタ名義）。常に出る | herdr-terminal-notifier。見ている workspace かつターミナルが最前面なら出さない |
| 画面内トースト | なし | `[ui.toast] delivery = "herdr"`（prefix+o） |

見ていない workspace では、音が 2 回、バナーが 2 枚出る。

## 選択肢

### A. herdr 内だけ hook を黙らせる（`HERDR_ENV=1` なら通知しない）

- herdr の外（WezTerm + tmux + baton）では hook の通知が残る
- 通知の分岐が dotfiles のスクリプトに残る

### B. hook の音だけ止める

- 音の二重は消えるが、バナーは 2 枚のまま

### C. hook / notify からの呼び出しをやめる（採用）

- 通知は herdr だけになる
- herdr の外では完了・承認待ちの通知が出ない

## 決定

**C を採用する。** Claude Code の hook から `claude_message.sh` を、Codex の notify から
`codex_message.sh` を外す。

- herdr の通知はエージェントを問わず、見ている画面かどうかも見て抑止する。hook 側はどちらもしない
- herdr の外で使う WezTerm はサブ環境で、そこでの通知は当面なくてよい
- スクリプト（`claude_message.sh` / `codex_message.sh` / `shared/notify_message.sh`）は
  消さずに残す。呼び出しを戻せばすぐ復帰できる

### C で失うもの

- 「失敗」の区別。herdr の状態は idle / working / blocked と未読の done だけで、
  Claude Code と Codex は画面から判定しているため、失敗で止まっても done として通知される。
  ただし hook の「失敗」は「ターン最後のツール呼び出しがエラーだったか」を見ているだけで、
  タスクの成否を表していなかった
- バナー本文の最終メッセージ。herdr-terminal-notifier の本文は workspace と worktree だけ
- 見ている workspace での通知音
- herdr の外での通知

## 影響

- `claude/settings.json`: Stop から `claude_message.sh stop` を外し、
  Notification / PostToolUse / PostToolUseFailure の hook を削除（`check-settings-drift.sh` は残す）。
  手元への反映は switch 時
- `claude-work/settings.json`: Notification の hook を削除（同上）
- `codex/config.toml`: notify を Computer Use の `turn-ended` だけにする
  （`--previous-notify` は省略できる引数）。mkLink なので保存した時点で反映
- `config/herdr/config.toml`: `[ui.sound]` の「二重に鳴る」注記を削除

## 未確定事項

- herdr の外でも通知が欲しくなったら、呼び出しを戻したうえで
  `HERDR_ENV=1` のときは通知しない分岐を入れる（A）
