# Git / Release Policy

複数プロダクトで共通に使う Git / release 運用の標準。
この文書は repo 固有実装ではなく、グローバル運用方針の一次ソースとして扱う。

## 対象

- 作業ブランチ運用
- PR と merge の流れ
- `CHANGELOG.md` 更新責務
- release 実行の前提
- AI が PR を作るときの共通ルール

## 標準ルール

- `main` を唯一の release ブランチにする
- 日常開発は `main` から短命ブランチを切る
- `1 worktree = 1 branch = 1 PR` を原則にする
- 並列作業は `gtr` による `git worktree` を前提にする
- `main` へ直接 push しない
- `main` への統合は GitHub 上の `Squash and merge` を使う
- ユーザー向け変更がある PR では `CHANGELOG.md` の `Unreleased` を更新する
- release は `main` が clean な状態で実行する

## 日常開発フロー

1. `main` を最新化する
2. `gtr` で作業用 worktree と短命ブランチを作る
3. 実装、テスト、必要なドキュメント更新を行う
4. ユーザー向け変更がある場合は `CHANGELOG.md` の `Unreleased` を更新する
5. PR を作成する
6. CI 通過後に GitHub 上で `Squash and merge` する
7. root worktree の `main` を `git pull --ff-only origin main` で同期する

## ブランチと worktree

- worktree の管理は `gtr` に寄せる
- ルート worktree は `main` の確認と release 実行に使う
- 日常作業は作業用 worktree で行う
- ブランチ名は厳密にしすぎない
  - 例: `fix/123`, `docs/readme`, `chore/release`

## 競合解決

- 競合解決のためにローカルで `main` へ merge して push しない
- 競合は PR の head branch 側で解消する
- GitHub UI の conflict editor ではなく、原則ローカル worktree で解決する

例:

```bash
git fetch origin
git switch fix/123
git merge origin/main
# 競合解決
git push
```

## CHANGELOG 運用

- `Unreleased` の更新責任は PR 作成者が持つ
- AI が PR を作る場合も同じ
- reviewer は記載有無と内容の妥当性を確認する
- release 時に `Unreleased` を version セクションへ確定する
- ユーザー影響のない変更は `skip-changelog` ラベル相当で扱ってよい

更新対象の例:

- 新機能
- バグ修正
- 利用者が認識すべき挙動変更
- 導入方法や運用方法に影響する文書更新

更新不要の例:

- テストのみ
- 純粋な内部整理
- ユーザー影響のない CI / 補助スクリプト変更

## Release フロー

1. `CHANGELOG.md` の `Unreleased` を次 version に確定する
2. `main` の CI と worktree 状態を確認する
3. 各 repo の共通 `task release` を root worktree の `main` で実行する
4. tag push を契機に GitHub Release を作成する
5. assets が必要な repo は release 後の workflow で配布物を添付する

補足:

- assets の有無はプロジェクトごとに異なる
- 共通化するのは release 作成の核であり、配布方法までは固定しない

## GitHub 設定

- PR merge method は `Squash and merge` を標準とする
- `Automatically delete head branches` を有効にする
- branch 保護は legacy の branch protection より GitHub Rulesets を優先する
- Rulesets の JSON 管理と import 手順は [github-rulesets.md](github-rulesets.md) を参照する

## AI エージェント向け運用ルール

この文書の内容は、グローバル `CLAUDE.md` / `AGENTS.md` にも反映する。
少なくとも次を常時守らせる。

- `main` から作業ブランチを切る
- `main` へ直接 push しない
- PR を作成する
- ユーザー向け変更なら `CHANGELOG.md` の `Unreleased` を更新する
- 競合時は PR branch 側で `origin/main` を取り込んで解決する
- `main` への統合は GitHub 上の `Squash and merge` を前提にする

## repo 固有で残るもの

次の要素は各 repo に残る。

- `CHANGELOG.md`
- `.github/release.yml`
- release caller workflow
- asset workflow
- README や導入手順書などの利用者向け導線
