# dotfiles repository instructions

共通ルールは `shared/agents/core.md` を参照（各 CLI のグローバル設定として配布済み）。
このファイルには当リポジトリ固有のルールのみを書く。

## Git

- 当リポジトリは main ブランチで直接作業・コミットしてください（PR 運用の対象外）。

## フォーマット

- nix / shell / yaml / toml は treefmt 管理。整形は `task nix-fmt`。
- `.githooks/pre-commit` がステージ済みファイルの整形崩れを検出して commit を止める
  （検査のみ。ファイルは書き換えないので、落ちたら `task nix-fmt` → `git add`）。
- フックは `config/git/dotfiles.config` を includeIf 経由で読み込むことで有効化される。

## Mac mini（hermes）への接続

- エージェントが Mac mini へ SSH する場合は必ず `macmini-agent` を使ってください。
- `macmini-hermes` は使わないでください。`LocalForward 13000` を持つ `hermes-ui` 専用の
  プロファイルで、ユーザーがダッシュボードを開いている間はポートが衝突します。
- admin 権限が必要な操作のみ `macmini-admin` を使い、その理由を明示してください。
