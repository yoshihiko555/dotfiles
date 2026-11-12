# takt

設定は 2 ファイルに分かれています。全設定項目は
[takt の configuration.md](https://github.com/nrslib/takt/blob/main/docs/configuration.md) を参照。

| ファイル | 配置先 | 中身 |
|---|---|---|
| `takt/config.yaml` | `~/.takt/config.yaml` | 実行制御・作業ディレクトリ・権限（`provider_profiles`）・レートリミット時の退避 |
| `takt/runtime.yaml` | `~/.takt/runtime.yaml` | provider / model / ステップごとの振り分け・補助レビュー（companion） |

どちらも home-manager の `mkOutOfStoreSymlink` でリポジトリへリンクしているため、編集は即反映されます
（リンクの追加・変更時だけ `nxs` が必要）。

`takt/logs/` `takt/analytics/` は takt が生成するランタイム成果物で、Git 管理外（`.gitignore` 済み）。

## SDK の導入と更新

0.71.0 以降、SDK を使う provider（`claude-sdk` / `codex` / `opencode` など）の SDK は takt に同梱されません。
`takt install` で `~/.takt/<provider>/` に npm で導入します。**Nix の管理外**です。

| 目的 | コマンド |
|---|---|
| 導入できる SDK の一覧 | `takt install --help`（`component` の欄） |
| 導入 | `takt install claude-sdk` / `takt install codex` / `takt install opencode` |
| 導入済みの版 | `cat ~/.takt/<provider>/sdk/package.json` |
| 本体の固定版に合わせて更新 | `takt update`（固定版とずれているものだけ更新） |

- 本体は Nix（`nxu takt`）で更新するため、適用後に `takt update` を実行します。
  忘れても端末での実行時に更新を促されますが、`takt watch` など非対話の実行では促されません。
- Claude / Codex は CLI バイナリも SDK 側で管理し、PATH 上の `claude` / `codex` は使いません
  （`TAKT_CLAUDE_CLI_PATH` / `TAKT_CODEX_CLI_PATH` で明示した場合を除く）。
  OpenCode は外部 CLI（Nix で入れている `opencode`）も必要です。

## プロバイダ割り当て（runtime.yaml）

0.61.0 以降の runtime モードで、`runtime.yaml` に profile（provider + model + options の組）を定義し、
既定とステップごとの振り分けを書きます。

| 対象 | profile | 中身 |
|---|---|---|
| 既定（下記以外すべて） | `claude-opus` | Claude（`claude-sdk`, `opus`） |
| tag `coding` / `test-planning` | `codex-sol-high` | Codex（`gpt-6-sol`, reasoning_effort `high`） |
| step `ai-antipattern-review-2nd` | `opencode-kimi` | OpenCode（`opencode-go/kimi-k3`） |

- 計画・レビュー・最終判定（tag `plan` / `review` / `final-gate` / `supervise` など）、companion、
  対話アシスタントなどの内部 agent は既定の `claude-opus` で動きます。
- 実装リーダー（`takt-default-team` の `implement` / `fix` など）は tag `coding-leader` と `coding` を
  両方持つため、Codex で動きます。
- `default` 系ワークフローの `ai-antipattern-review` は意図的に OpenCode へ振らず、Claude のままです（後述）。

解決順は `defaults < personas < tags < steps`（後ろほど強い）で、実行時の `--provider` / `--model` が最優先です。
実際にどの step がどの provider / model / 権限で動くかは `takt workflow inspect <workflow>` で確認できます
（解決元も表示されます）。

- `config.yaml` に `provider` / `model` / `provider_routing` を書くと、`runtime.yaml` と衝突して
  `Mixed provider configuration detected` で agent を起動する前に止まります。
- `targets.tags` に書けるのはビルトインワークフローが実際に付けている tag だけです
  （0.75.0 では 11 種。一覧は `runtime.yaml` のコメントにあります。`policy:` や `knowledge:` の値は
  tag ではないため空振りします）。
- 1 つの step が複数の tag を持つことがあり（例: `write_tests` は `coding` + `test-planning`）、
  同じ優先度で別の profile に当たると fail-fast します。組み合わせで現れる tag は同じ profile に揃えます。
- Claude の provider 名は `claude-sdk` で揃えています。0.68.0 で `claude` は `claude-sdk` の別名になりましたが、
  `config.yaml` の `provider_profiles` は provider に書いた名前のまま引かれるため、名前が混在すると権限設定が効きません。
- レートリミット時は `config.yaml` の `rate_limit_fallback` で Codex（`gpt-6-sol`）へ退避して実行を継続します
  （runtime モードでも `config.yaml` から読まれます）。`switch_chain` は options を書けないため、
  この経路の reasoning_effort は `~/.codex/config.toml` の `model_reasoning_effort` に従います。

### AI アンチパターン review を OpenCode へ振っている理由

`ai-antipattern-*` は tag ではなく step 名です。`review` 系は tag `review`、`fix` 系は tag `coding`
を持つため、`steps` で review だけを名指しすれば **fix 系は tag `coding` のまま Codex に残ります**。
`steps` は `tags` より強いのでこの上書きが成立します。狙いは Claude / Codex の枠を
消費せずに検出パスを 1 本増やすことです。

- キーは完全一致のみ（ワイルドカード無し）。`<workflow>/<step>` 形式での限定も可能です。
- `personas` は `tags` より弱いため、tag `review` の割り当てがある状態で
  `personas.ai-antipattern-reviewer` を書いても効きません。
- 0.75.0 の ja ビルトインに存在する step 名は次の 6 つです。指定しているのは `ai-antipattern-review-2nd` だけです。

  | step 名 | tag | 使っているワークフロー | 振り先 |
  |---|---|---|---|
  | `ai-antipattern-review-2nd` | `review` | mini-core / review-takt-default / terraform | OpenCode |
  | `ai-antipattern-review` | `review` | default / maintenance / review / review-fix / takt-default 系 | Claude |
  | `ai-antipattern-review-1st` | `review` | 共通 step（`ai-antipattern-first-pass`） | Claude |
  | `ai-antipattern-no-fix` | `review` | 共通 step（`ai-antipattern-arbitration`） | Claude |
  | `ai-antipattern-fix` | `coding` | mini-core / terraform | Codex |
  | `ai-antipattern-fix-parallel` | `coding` | terraform | Codex |

  `default` 系の `ai-antipattern-review` は追加の検出パスではなく並列レビュアーの 1 本で、
  振るとその担当が Claude から kimi-k3 に替わります。品質とのトレードオフから**意図的に振っていません**。
- takt を更新したら `builtins/ja` の `workflows` / `steps` 配下を `name: ai-antipattern` で再確認してください
  （`ai-antipattern-review.md` などのレポート名も当たるため、`persona` / `tags` を持つものだけを数えます）。

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
- **reasoning effort に相当する指定がありません**。profile の `options` で渡せるのは
  `network_access` / `variant` / `allowed_tools` / `guards.*` のみです。
- wall-clock 上限は既定 60 分。超えうるステップは `options.guards.call_timeout_ms` を明示します（最大 86,400,000）。
- 構造化出力は `StructuredOutput` 疑似ツールで回収するため、指示追従が弱いモデルでは
  `returned no structured output` で失敗しえます。安価モデルを実装ステップに使わない理由です。

使用量とモデル選択は opencode 側のコマンドで確認します。

| 目的 | コマンド |
|---|---|
| 選べるモデル一覧 | `opencode models \| grep '^opencode-go/'` |
| モデル別の使用量・コスト | `opencode stats --models`（`--days N` / `--project .`（現在のプロジェクト）で絞り込み） |

モデルのメタデータ（context / max output / 単価 / reasoning・tool_call 対応）は
`~/.cache/opencode/models.json` に入っています。現在の `kimi-k3` は context 1,048,576 /
max output 131,072 / in $3・out $15 per M tokens で、一覧中では最も高価です。
消費するのは opencode-go の契約枠なので、claude / codex 側の枠は使いません。

## 補助レビュー（companion）

実装・修正ステップに付き添う読み取り専用のレビュアーです。実装エージェント（Codex）の差分を
作業の直後に見て、その場で指摘を返します。`runtime.yaml` の `companion.enabled: true` で有効にしています。

| | 補助レビュー（companion） | 通常のレビュー |
|---|---|---|
| タイミング | 実装・修正ステップの最中・直後 | 実装が終わった後 |
| 指摘の扱い | 参考情報。ワークフローの遷移は変えない | 結果で修正ループに戻すかが決まる |
| `default` での担当 | AI アンチパターン、テスト、指摘の採否を決める moderator | 並列のピアレビュー → 裁定 → 修正 |

- `review_mode` / `fix_policy` は既定（`completion` / `single`）のままです。
  - `completion`: 実装エージェントの応答が終わるたびに累積差分をレビュー（`live` は作業中も監視）
  - `single`: 採用された指摘で 1 回だけ修正し、再レビューはしない（`loop` は指摘がなくなるまで上限なしで反復）
- provider は `targets.companions` を書いていないので既定の `claude-opus` です。
  権限は `provider_profiles` にかかわらず `readonly` で動きます。
- 実装・修正ステップのたびに companion 2 名と moderator が追加で呼ばれるため、Claude の使用量が増えます。
- 採用された指摘は `.takt/runs/{run}/companion/{step}/{companion}.jsonl` に記録されます。
- **companion は runtime モードでしか使えません**。`config.yaml` に provider 設定がある状態で有効にすると、
  `default` が `Companion reviewers require runtime.yaml` で検証エラーになります。

## アカウント切替

```bash
# 個人アカウント
takt

# 会社アカウント（Claude 側のステップのみ ~/.claude-work を使う）
taktw
```

- `taktw` は `CLAUDE_CONFIG_DIR` を渡すだけなので、Codex / OpenCode のステップは影響を受けません。
  `claude-sdk` も環境変数をそのまま子プロセスへ引き継ぐため、0.75.0 でも切り替わります。
- 環境変数はプロセス単位で効くため、同一実行内で Claude アカウントを混在させることはできません。
- **`takt manager` では、アカウントは daemon を起動した側の環境で決まります。**
  manager の Claude ステップは daemon が起動する子プロセスで動き、daemon の環境変数を引き継ぎます。
  daemon は `~/.takt` につき 1 つで、`taktw` も同じ daemon を使います。
  そのため、daemon が動いている間に `taktw manager` を実行しても、既存の daemon につながるだけで
  先に起動した側のアカウントのままになります（逆も同じ）。
  - 切り替えるときは `takt daemon stop` で止めてから `takt manager` / `taktw manager` を実行します。
  - daemon は manager を閉じて仕事がなくなると自動で止まり、次の起動時の環境で立ち上がり直します。
  - 動いている daemon のアカウントは、`ps eww -p <daemon の pid>` の出力に `CLAUDE_CONFIG_DIR` があるかで確認できます
    （pid は `pgrep -f takt/dist/app/daemon/index.js`）。
- takt は Claude SDK を `settingSources: ['project']` で起動します。そのため `~/.claude`
  （`taktw` では `~/.claude-work`）のユーザー設定と CLAUDE.md は、Claude のステップには読まれません。
  組織の管理設定（managed settings）は、SDK の仕様上この指定にかかわらず読まれます。
- API キー（`anthropic_api_key` など）は config.yaml / runtime.yaml に書かず、`TAKT_ANTHROPIC_API_KEY` 等の環境変数を使います。

## 作業ディレクトリの配置

`worktree_dir: .worktrees` で、takt の作業ディレクトリをプロジェクト直下に寄せています。

- 既定のままだと `<project>/../takt-worktrees` に作られ、ghq 構成では `~/ghq/github.com/<user>/` が汚れます。
- **名前に反して takt が作るのは git worktree ではなく独立クローン**
  （`git clone --reference <project> --dissociate`）です。したがって:
  - `gtr`（`wt` コマンド）の `list` / `go` / `rm` からは見えません（gtr 管理外）。
  - `scripts/repo-list.sh` は `.worktrees/*` をディレクトリ走査するため、`repo` コマンドと
    tmux / herdr の sessionizer からは拾えます。gtr と同居させているのはこのためです。
  - `--dissociate` なのでオブジェクトは実体コピーになります（容量 = タスク数 × リポジトリサイズ）。
- takt を使うプロジェクトでは `.gitignore` に `.worktrees/` を追加してください。

## 権限モード

`config.yaml` の `provider_profiles` は claude-sdk / codex / opencode すべて `edit` です。
`provider_profiles` は runtime モードでも移行対象外で、`config.yaml` から読まれます。
キーは `runtime.yaml` の profile に書いた provider 名と一致させます（`claude` と `claude-sdk` は別キー扱いで、
一致しないと takt 組み込みの既定 `edit` に落ちます）。
takt の抽象モードは各 CLI に次のように写されます。

| takt | Claude（claude-sdk） | Codex | OpenCode（ツール単位の permission） |
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
