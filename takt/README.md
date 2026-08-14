# takt

`takt/config.yaml` はグローバル設定（→ `~/.takt/config.yaml`）。
全設定項目は [takt の configuration.md](https://github.com/nrslib/takt/blob/main/docs/configuration.md) を参照。

`takt/logs/` `takt/analytics/` `takt/runtime.yaml` は takt が生成するランタイム成果物で、
Git 管理外（`.gitignore` 済み）。

## プロバイダ割り当て

ステップの役割（tags）ごとにプロバイダを割り当てる。

- 実装・テスト（`coding` / `test-planning`）: Codex（`gpt-5.6-sol`, reasoning_effort `xhigh`）
- 計画・レビュー・最終判定（`plan` / `review` / `merge-readiness` / `final-gate` / `supervise` / `leader`）: Claude（`opus`）

ビルトインワークフローはステップに `provider:` を書いていないため、`provider_routing.tags` の指定が
全ワークフローに横断で効きます（優先度は `provider_routing.tags` = 5 > `workflow` = 9 で、数値が小さいほど強い）。
実行時に `takt --provider claude` のように上書きする方法が最優先（= 0）です。

- `provider_routing.tags` に書けるのはビルトインワークフローが実際に付けている tag だけです
  （上記 8 種。`policy:` や `knowledge:` の値は tag ではないため空振りします）。
- Codex へ振るエントリには `model` を必ず併記します。省略するとトップレベルの `opus` が
  そのまま Codex に渡ります（model の解決は provider 一致で絞り込まれないため）。
- レートリミット時は `rate_limit_fallback` で Codex（`gpt-5.6-sol`）へ退避して実行を継続します。

## アカウント切替

```bash
# 個人アカウント
takt

# 会社アカウント（Claude 側のステップのみ ~/.claude-work を使う）
taktw
```

- `taktw` は `CLAUDE_CONFIG_DIR` を渡すだけなので、Codex / OpenCode のステップは影響を受けません。
- 環境変数はプロセス単位で効くため、同一実行内で Claude アカウントを混在させることはできません。
- API キー（`anthropic_api_key` など）は config.yaml に書かず、`TAKT_ANTHROPIC_API_KEY` 等の環境変数を使います。

## 作業ディレクトリの配置

`worktree_dir: .worktrees` で、takt の作業ディレクトリをプロジェクト直下に寄せています。

- 既定のままだと `<project>/../takt-worktrees` に作られ、ghq 構成では `~/ghq/github.com/<user>/` が汚れます。
- **名前に反して takt が作るのは git worktree ではなく独立クローン**
  （`git clone --reference <project> --dissociate`）です。したがって:
  - `gtr`（`wt` コマンド）の `list` / `go` / `rm` からは見えません（gtr 管理外）。
  - `scripts/repo-list.sh` は `.worktrees/*` をディレクトリ走査するため、`repo` コマンドと
    WezTerm セレクタからは拾えます。gtr と同居させているのはこのためです。
  - `--dissociate` なのでオブジェクトは実体コピーになります（容量 = タスク数 × リポジトリサイズ）。
- takt を使うプロジェクトでは `.gitignore` に `.worktrees/` を追加してください。

## 権限モード

`provider_profiles` は claude / codex とも `edit` です。takt の抽象モードは各 CLI に次のように写されます。

| takt | Claude Code | Codex | 備考 |
|---|---|---|---|
| `readonly` | `default` | `read-only` | 書き込み禁止ではなく都度確認。headless では応答できず停止しうる |
| `edit` | `acceptEdits` | `workspace-write` | |
| `full` | `bypassPermissions` | `danger-full-access` | 全許可のため使いません |

編集の可否はワークフロー側の `edit` フラグ（`plan` は `edit: false`）が制御するので、
プロバイダ側で `readonly` に二重に絞っていません。
Codex は takt が `approvalPolicy: never` を強制するため、サンドボックスモードが唯一の砦になります。

## 実行制御

- `concurrency: 2` — 同時実行タスク数（既定 1）
- `auto_requeue_max_attempts: 1` — 一時的な失敗を 1 回だけ拾い直す（既定 0）
- `prevent_sleep: true` — 長時間実行中の macOS スリープを抑止
- `auto_fetch: true` — 作業ディレクトリを切る前に remote を fetch
- `branch_name_strategy: ai` — 日本語タスク名を romaji 直訳せず英語ブランチ名を生成

`base_branch` は**意図的に設定していません**。未設定なら `origin/HEAD` → `main` → `master` の順で
自動判定されますが、明示するとブランチ存在チェックが走り、`master` を使うリポジトリでエラーになります。

その他「既定のまま使う」と判断した項目（`auto_pr`、`observability` など）は
`takt/config.yaml` の末尾に理由付きで列挙しています。
