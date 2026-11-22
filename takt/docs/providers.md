# takt のプロバイダ設定

各ステップのモデルと補助レビューは [runtime.yaml](../runtime.yaml)、レートリミット時の退避先は [config.yaml](../config.yaml) で変更します。SDK の導入と更新は [takt の README](../README.md#sdk-の導入と更新) を参照してください。

## プロバイダ割り当て（runtime.yaml）

0.61.0 以降の runtime モードで、`runtime.yaml` に profile（provider + model + options の組）を定義し、
既定とステップごとの振り分けを書きます。

| 対象 | profile | 中身 |
|---|---|---|
| 既定（下記以外すべて） | `claude-opus` | Claude（`claude-sdk`, `opus`） |
| tag `coding` / `test-planning` | `codex-sol-high` | Codex（`gpt-6.1-sol`, reasoning_effort `high`） |
| step `ai-antipattern-review-2nd` | `opencode-deepseek-flash` | OpenCode（`opencode-go/deepseek-v4.1-flash`） |

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
- レートリミット時は `config.yaml` の `rate_limit_fallback` で Codex（`gpt-6.1-sol`）へ退避して実行を継続します
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
  振るとその担当が Claude から OpenCode のモデルに替わります。品質とのトレードオフから**意図的に振っていません**。
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

モデルのメタデータ（context / max output / 単価 / reasoning・tool_call・structured_output 対応）は
[models.dev](https://models.dev/api.json) の `opencode-go`、モデル別の月間上限は
[OpenCode Go のドキュメント](https://opencode.ai/docs/go/) の Usage limits で確認します。
消費するのは opencode-go の契約枠なので、claude / codex 側の枠は使いません。

- 現在の `deepseek-v4.1-flash` は context 1,000,000 / max output 384,000 /
  in $0.15・out $0.6 per M tokens（平日 UTC 01–04 時・06–10 時のピークは倍額）です。
- DeepSeek は OpenCode Go のワークスペースの **Settings › Privacy › Regions を Global** にしないと拒否されます。
  ワークスペース全体の設定なので、同じキーを使う CLIProxyAPI 経由の Go モデルにも効きます。

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
