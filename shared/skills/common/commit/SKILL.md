---
name: commit
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit (context-aware version)
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## コミット手順

会話で扱った変更だけを1件のコミットにする。対象が曖昧な場合は確認する。

1. `git status --short`、`git diff`、`git diff --cached` で対象とステージ状態を確認する。
2. 対象ファイルの変更を丸ごと含める場合、追跡済みの編集・削除はそのまま `git commit --only -m "…" -- <対象パス…>` に渡す。対象に未追跡ファイル（`??`）があれば、そのファイルだけを先に `git add -- <パス>` で個別に登録する。ほかのファイルのステージ状態は維持する。
3. 部分ステージをコミットする場合、パス指定の `--only` は作業ツリーの内容を採用するので使わない。ステージ済み差分が依頼内容と一致すれば通常の `git commit -m "…"` を使い、無関係な差分もステージされていれば既存のステージを保ったまま対象を確認する。
4. Codex で `.git/index.lock` の作成が `Operation not permitted` になったら、必要な Git 操作を対象パス付きで特定し、その操作について権限昇格を要求する。追跡済みファイル全体をコミットできる条件なら、`git commit --only` 自体を承認対象にする。
5. 成功後はコミットのハッシュと変更パスを確認して報告する。
