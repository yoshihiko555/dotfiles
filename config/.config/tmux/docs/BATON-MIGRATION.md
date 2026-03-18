# baton 移行メモ

- 作成日: 2026-03-19
- 目的: `Prefix+b` まわりの暫定 Claude pane ダッシュボードを、将来的に `baton` へ置き換えたあと確実に整理する

## 背景

現状の `Prefix+b` は `claude-tmux` ではなく、tmux 上の Claude Code pane をペイン単位で列挙する暫定スクリプト群で実装している。

- 理由: `claude-tmux` は session 単位のモデルで、同一 session 内の複数 Claude Code を正しく扱いにくい
- 方針: 本命は `baton`。現在のスクリプトは `baton` が育つまでの暫定運用

## 暫定実装の対象

以下は `baton` 移行後に削除または置換を検討する対象。

- `config/.config/tmux/conf/popup.conf`
- `config/.config/tmux/bin/tmux-list-claude-panes`
- `config/.config/tmux/bin/tmux-popup-claude-dashboard`
- `config/.config/tmux/bin/tmux-open-claude-target`
- `config/.config/tmux/docs/CHEATSHEET.md`
- `config/.config/tmux/docs/SCRIPTS.md`
- `config/.config/tmux/docs/VERIFICATION.md`

## baton 側の完了条件

以下が揃ったら、暫定実装の撤去を始めてよい。

- Claude Code を手動起動した pane を後追いで検出できる
- 主キーが tmux session ではなく `TMUX_PANE` になっている
- 同一 session 内の複数 Claude Code を個別に保持できる
- `working / waiting / idle` を hook ベースで更新できる
- pane 一覧とジャンプ UI がある
- 閉じた pane の state を掃除できる

## 移行手順

1. `baton` 側で上記の完了条件を満たす
2. `Prefix+b` のバインド先を `baton` に切り替える
3. 1日以上、実運用で切り替え後の導線を確認する
4. 暫定スクリプト 3 本を削除する
5. 関連ドキュメントの記述を `baton` 前提に更新する

## チェックリスト

- [ ] `baton` 側に pane ベースの state 管理が入った
- [ ] `baton` 側に pane 一覧 / jump 導線が入った
- [ ] `popup.conf` の `Prefix+b` を `baton` に切り替えた
- [ ] `tmux-list-claude-panes` を削除した
- [ ] `tmux-popup-claude-dashboard` を削除した
- [ ] `tmux-open-claude-target` を削除した
- [ ] `CHEATSHEET.md` を更新した
- [ ] `SCRIPTS.md` を更新した
- [ ] `VERIFICATION.md` を更新した

## 補足

- `tmux-agent-status` を一時運用する場合も、最終到達点は `baton` とする
- 暫定ツールを増やしても、このメモのチェックリストを更新しない限り「完了」とみなさない
