# takt

`takt/config.yaml` はグローバル設定（→ `~/.takt/config.yaml`）。
全設定項目は [takt の configuration.md](https://github.com/nrslib/takt/blob/main/docs/configuration.md) を参照。

`takt/logs/` `takt/analytics/` `takt/runtime.yaml` は takt が生成するランタイム成果物で、
Git 管理外（`.gitignore` 済み）。

## プロバイダ割り当て

ステップの役割（tags）ごと、および一部は step 名単位でプロバイダを割り当てる。

- 実装・テスト（`coding` / `test-planning`）: Codex（`gpt-5.6-sol`, reasoning_effort `high`）
- 計画・レビュー・最終判定（`plan` / `review` / `merge-readiness` / `final-gate` / `supervise` / `leader`）: Claude（`opus`）
- AI アンチパターン検出の review（step `ai-antipattern-review-2nd`）: OpenCode（`opencode-go/kimi-k3`）

ビルトインワークフローはステップに `provider:` を書いていないため、`provider_routing` の指定が
全ワークフローに横断で効きます。優先度は数値が小さいほど強く、実行時の `takt --provider claude`
（= 0）が最優先です。

| 優先度 | 解決元 |
|---|---|
| 0 | `--provider` / `--model`、環境変数 |
| 2 | ワークフローの step 直書き |
| 3 | `provider_routing.steps` |
| 4 | `provider_routing.tags` |
| 5 | `provider_routing.personas` |
| 9 / 10 | プロジェクト設定 / グローバル設定 |
| 11 | トップレベルの `provider` / `model` |

（takt 0.60.0 の `dist/core/workflow/provider-resolution.js` の `PROVIDER_MODEL_SOURCE_PRIORITY` 実測値）

- `provider_routing.tags` に書けるのはビルトインワークフローが実際に付けている tag だけです
  （上記 8 種。`policy:` や `knowledge:` の値は tag ではないため空振りします）。
- Codex / OpenCode へ振るエントリには `model` を必ず併記します。省略するとトップレベルの `opus` が
  そのまま渡ります（model の解決は provider 一致で絞り込まれないため）。
- レートリミット時は `rate_limit_fallback` で Codex（`gpt-5.6-sol`）へ退避して実行を継続します。
  `switch_chain` は `provider_options` を書けないため、この経路の reasoning_effort は
  `~/.codex/config.toml` の `xhigh` に従います（`provider_routing` 側の `high` は効きません）。

### AI アンチパターン review を OpenCode へ振っている理由

`ai-antipattern-*` は tag ではなく step 名です。`review` 系は tag `review`、`fix` 系は tag `coding`
を持つため、`steps` で review だけを名指しすれば **fix 系は tag `coding` のまま Codex に残ります**。
`steps`（3）は `tags`（4）より強いのでこの上書きが成立します。狙いは Claude / Codex の枠を
消費せずに検出パスを 1 本増やすことです。

- キーは完全一致のみ（ワイルドカード無し）。`<workflow>/<step>` 形式での限定も可能です。
- `personas`（5）は `tags`（4）より弱いため、`tags.review: claude` がある状態で
  `personas.ai-antipattern-reviewer` を書いても効きません。
- 0.60.0 の ja ビルトインに存在する step 名は `ai-antipattern-review-2nd`（tag `review`）、
  `ai-antipattern-fix` / `ai-antipattern-fix-parallel`（tag `coding`）の 3 つです。
  takt を更新したら `builtins/ja/workflows/*.yaml` を `name: ai-antipattern` で再確認してください。

### OpenCode プロバイダの制約

takt 側のプロバイダ名は `opencode` で、`opencode-go` はプロバイダ名ではなく**モデル名の前半**です。

- `model` は `provider/model` 形式必須。モデル名だけでは
  `requires model in 'provider/model' format` で落ちます。
- 認証は opencode 側（`~/.local/share/opencode/auth.json`）に完全依存します。
  `opencode_api_key` / `TAKT_OPENCODE_API_KEY` は opencode zen（`opencode/*`）用で、
  `opencode-go` には効きません。使えるモデルは `opencode models` で確認します。
- takt は `@opencode-ai/sdk` の `createOpencode` で 127.0.0.1 のランダムポートにサーバを立て、
  `model` / `small_model` / `permission` / takt 専用 agent を自前で組み立てます。
  `~/.config/opencode` の agent 設定には依存しません。
- **reasoning effort に相当する指定がありません**。`provider_options.opencode` で渡せるのは
  `network_access` / `variant` / `allowed_tools` / `guards.*` のみです。
- wall-clock 上限は既定 60 分。超えうるステップは `guards.call_timeout_ms` を明示します（最大 86,400,000）。
- 構造化出力は `StructuredOutput` 疑似ツールで回収するため、指示追従が弱いモデルでは
  `returned no structured output` で失敗しえます。安価モデルを実装ステップに使わない理由です。

使用量とモデル選択は opencode 側のコマンドで確認します。

| 目的 | コマンド |
|---|---|
| 選べるモデル一覧 | `opencode models opencode-go` |
| モデル別の使用量・コスト | `opencode stats --models`（`--days N` / `--project ""` で絞り込み） |

モデルのメタデータ（context / max output / 単価 / reasoning・tool_call 対応）は
`~/.cache/opencode/models.json` に入っています。現在の `kimi-k3` は context 1,048,576 /
max output 131,072 / in $3・out $15 per M tokens で、一覧中では最も高価です。
消費するのは opencode-go の契約枠なので、claude / codex 側の枠は使いません。

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

`provider_profiles` は claude / codex / opencode すべて `edit` です。
takt の抽象モードは各 CLI に次のように写されます。

| takt | Claude Code | Codex | OpenCode（ツール単位の permission） |
|---|---|---|---|
| `readonly` | `default` | `read-only` | `read` / `glob` / `grep` のみ allow |
| `edit` | `acceptEdits` | `workspace-write` | 上記 + `edit` / `write` / `bash` / `todowrite` / `web*` を allow、`question` は deny |
| `full` | `bypassPermissions` | `danger-full-access` | 全 allow（使いません） |

`readonly` の Claude Code は書き込み禁止ではなく都度確認で、headless では応答できず停止しえます。

編集の可否はワークフロー側の `edit` フラグ（`plan` は `edit: false`）が制御するので、
プロバイダ側で `readonly` に二重に絞っていません。
Codex は takt が `approvalPolicy: never` を強制するため、サンドボックスモードが唯一の砦になります。
OpenCode を未設定にすると permission mode が未解決のまま `ask` 相当に落ち、headless で停止しうるため、
他 2 つと同じく明示しています。

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
