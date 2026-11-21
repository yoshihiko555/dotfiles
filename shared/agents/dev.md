## General coding policy

- 既存の仕様や振る舞いを壊さないことを最優先してください。
- 既存のコードスタイル（命名・インデント・フォーマット）に合わせてください。
- 削除や大規模リファクタを行う前に、目的とリスクを明示してください。

## Runtime & dependencies

- 言語ランタイムと CLI ツールは mise で管理し、ライブラリはプロジェクトごとに閉じ込めてください。
- Python のライブラリを mise の Python 本体（グローバル）に `pip install` しないでください。プロジェクトの `.venv` に uv（`uv sync` / `uv add`）で入れます。単発のツールは `uvx`、常用するツールは mise の `pipx:` で入れます。

## Tests & validation

- 可能な範囲で、変更に対応するテストコードの追加・修正も提案してください。

## Git / PR / changelog

プロジェクトのコンテキストファイルに Git 運用の定めがある場合はそちらを優先してください。以下は定めがない場合の既定です。

- 作業ブランチは常に `main` から切ってください。
- `main` へ直接 push しないでください。変更は PR を作成して取り込みます。
- `main` への統合は GitHub 上の squash merge を前提にしてください。
- `CHANGELOG.md` があるリポジトリでは、ユーザー向け変更がある PR で `Unreleased` を更新してください。更新不要の変更（テストのみ、内部整理など）は、その判断を PR 内で明示してください。
- `CHANGELOG.md` が無いリポジトリでは作らず、PR やコミットでも changelog に触れないでください。
- 競合時は PR branch 側で `origin/main` を取り込んで解消してください。
- release は root worktree の `main` で行います。作業用 worktree から release を実行しないでください。
- ブランチ名は `<種別>/<内容>` にしてください。種別は feat / fix / chore / docs / refactor / test / ci / perf / build / release で、どれにも当たらなければ task にします。内容は小文字の英数字をハイフンでつなぎます（例: `fix/hook-tweak`）。
- worktree は `git gtr new <ブランチ> --from origin/main` で作り、`git gtr rm <ブランチ>` で消してください。`git worktree add` で手作りしないでください（置き場所は gtr の設定 `gtr.worktrees.dir` に任せます）。
- worktree で作った Git に入らないもの（`dist/` などの生成物、`.claude/plans/` の plan、生成した画像）は、worktree を消す前に root のチェックアウトへ移すか、root で作り直してください。
