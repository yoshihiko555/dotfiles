# GitHub リポジトリを検索する（`gh`）

GitHub のリポジトリを検索してブラウザで開くワークフロー。

## 使い方

1. Alfred で `gh` と入力すると、リポジトリが最終 push 順に並ぶ
2. `gh dotfiles` のようにリポジトリ名・オーナー名で絞り込む
3. 選択すると GitHub のリポジトリページがブラウザで開く

## 動作

- 対象は gh CLI の認証ユーザーがアクセスできる全リポジトリ
  （`/user/repos` の `owner,collaborator,organization_member`）
- 絞り込みは Alfred 側で行う（`alfredfiltersresults`）。
  スクリプトはキーワード起動時に一度だけ走り、打鍵ごとには走らない
- 一覧は 10 分キャッシュする（`alfred_workflow_cache`）。取得に失敗した場合は
  期限切れキャッシュで代替する
- private / archived / fork はサブタイトルにバッジで表示する

**依存:** `gh`（Nix 管理）。事前に `gh auth login` を済ませておくこと。

## 秘匿情報の扱い

認証は gh CLI の keyring を使うため、ワークフロー側にトークンを保存しない。
`prefs.plist` も生成されない。

> Alfred の Script Filter は最小 PATH で起動するため、`gh` は絶対パス候補
> （Nix profile / Homebrew / `/usr/local`）から探す。見つからない環境では
> Configure Workflow の `GH_BIN` に絶対パスを設定する。

[Alfred のワークフロー一覧](../README.md)
