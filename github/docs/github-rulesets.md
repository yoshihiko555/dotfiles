# GitHub Rulesets

複数 repo で同じ branch / tag ルールを再利用するための運用手順。
Ruleset は repo ごとに毎回手で作り直さず、export した JSON をこの repo で管理する。

## 管理方針

- branch 保護は GitHub Rulesets を基準にする
- JSON 本体は `github/rulesets/` 配下で管理する
- まずは手動 import を標準とする
- `gh api` などによる自動同期は後続フェーズで判断する

## 配置先

- `github/rulesets/*.json`
- 命名例:
  - `main-protection.json`
  - `main-protection-strict.json`
  - `tag-protection.json`

## Ruleset の生成・更新

1. reference repo で Ruleset を作成または更新する
2. GitHub の `Settings` -> `Rules` -> `Rulesets` を開く
3. 対象 Ruleset を export する
4. export した JSON を `github/rulesets/` 配下へ保存する
5. この文書または関連コミットで、変更理由と適用対象を記録する

## 新しい repo への import 手順

1. 対象 repo の `Settings` -> `Rules` -> `Rulesets` を開く
2. `New ruleset` を開く
3. `Import a ruleset` を選ぶ
4. `github/rulesets/` 配下の JSON を読み込む
5. import 内容を確認して作成する
6. import 後に repo 固有差分を確認する

## import 後に確認する項目

- target pattern が `main` など意図した対象になっている
- required status checks がその repo の CI 名と一致している
- bypass actor が意図どおりか
- `Require a pull request before merging` が有効か
- force push 禁止や linear history が有効か
- tag ruleset を使う repo では tag 側も設定したか

## GitHub UI 側で別途そろえる設定

Rulesets とは別に、各 repo で次も確認する。

- `Settings` -> `General` -> `Pull Requests`
  - `Allow squash merging`: ON
  - `Allow merge commits`: OFF
  - `Allow rebase merging`: OFF
  - `Automatically delete head branches`: ON

## Baton で確定した基準

- `main` を唯一の release ブランチにする
- `main` への統合は PR 経由の squash merge に限定する
- `main` 直 push は行わない
- 競合解決は PR branch 側で行う
- release 実行は root worktree の `main` で行う

## 参考

- GitHub Docs: Managing rulesets for a repository
  - https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/managing-rulesets-for-a-repository
