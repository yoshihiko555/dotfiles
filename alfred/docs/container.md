# コンテナと Compose を操作する（`ctr`）

Docker / OrbStack のコンテナと Compose プロジェクトを操作するワークフロー。

## 使い方

1. Alfred で `ctr` と入力（続けて絞り込みワードを入力可）
2. 一覧から対象を選択
   - 📦 … Compose プロジェクト（`docker compose ls -a`）
   - 🟢 / ⚪️ … コンテナ（`docker ps -a`、稼働中 / 停止中）
3. 対象の状態に応じたアクションを選択

## アクション

| 対象 | 状態 | アクション |
| --- | --- | --- |
| Compose | 稼働中 | `restart` / `stop` / `down` |
| Compose | 停止・未作成 | `up` (`-d`) / `down` |
| コンテナ | 稼働中 | `shell` / `restart` / `stop` |
| コンテナ | 停止中 | `start` |

## shell の動線

herdr のワークスペース `containers` にコンテナ名のタブを作り、`docker exec -it` で入る。
そのタブへフォーカスを移し、Ghostty を前面に出す。

- `containers` ワークスペースが無ければ自動で作成する（最初のタブをそのまま使う）
- herdr が起動していなければ Ghostty を起動してから作成する

## down 対策

`docker compose down` するとプロジェクトが `compose ls -a` から消え、Alfred から `up` し直せなくなる。
そのため一覧表示のたびに `プロジェクト名 → ConfigFiles` を
`$alfred_workflow_data/projects.json` に保存し、消えたプロジェクトも「未作成」として一覧に残す。

## 動作

- `shell` 以外はバックグラウンドで実行し、開始時と完了時に通知する（`compose up` のビルド待ちで Alfred が固まらない）
- Docker / OrbStack が停止している場合は一覧に「Docker / OrbStack が起動していません」と表示する

[Alfred のワークフロー一覧](../README.md)
