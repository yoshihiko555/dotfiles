# takt

## 起動とアカウント切替

```bash
# Claude・Codex とも個人アカウント
takt

# Claude・Codex それぞれのアカウントを fzf で選んでから起動する（引数は takt にそのまま渡る）
takts
takts manager
```

| 起動 | Claude | Codex |
|---|---|---|
| `takt` | 個人（`~/.claude`） | 個人（`~/.codex`） |
| `takts` | 個人 / 会社（`~/.claude-work`、`ccw` と同じ）から選ぶ | 個人 / 会社（`~/.codex-work`、`cxw` と同じ）から選ぶ |

- この方式を選んだ理由は [ADR-20261123-0001](docs/adr/ADR-20261123-0001-takt-account-select.md) を参照。
- `takts` は選んだ内容に応じて `CLAUDE_CONFIG_DIR` / `CODEX_HOME` を付け外しして takt を起動します。
  takt は provider の子プロセスへ環境変数をそのまま渡すため、`claude-sdk` も `codex` もこれで切り替わります。
  - 2 つは別の変数なので、「Claude は会社、Codex は個人」のような組み合わせも選べます。
  - 個人を選んだときも変数を外します。`ccw` などから継承した値で会社側に寄らないようにするためです。
  - 会社 Codex は `cxw` と同じ確認（`~/.codex` を指していないか、`config.toml` があるか）と、
    `OPENAI_API_KEY` などの認証用の環境変数の除去を行います。
  - 選択には端末が必要です。端末が無いとエラーで止まります。
- 環境変数はプロセス単位で効くため、同一実行内で同じ provider のアカウントを混在させることはできません。
- 会社 Codex を選ぶと、Codex のステップは `codex-work/config.toml` の設定で動きます。
  - レートリミット時に Codex へ退避したステップの reasoning effort は、そちらの `model_reasoning_effort` に従います。
  - MCP のマージ元とユーザースキルも `~/.codex-work` 側になります。
  - 作業クローンの trust は `codex-work/config.toml` に書き戻され、Git の差分になります（個人側の `codex/config.toml` と同じ）。
  - `runtime.yaml` で coding 系から外している Notion は、個人 Codex のプラグインで補っている前提です。
    会社側にはプラグインのログインをコピーしていないため、会社側で Notion を設定していなければ使えません。
- OpenCode のステップは `takts` の選択に関係なく、同じ認証のままです。
- **`takt manager` / `takt director` では、アカウントは daemon を起動した側の環境で決まります。**
  これらのステップは daemon が起動する子プロセスで動き、daemon の環境変数を引き継ぎます。
  daemon は `~/.takt` につき 1 つで、動いている間は環境が違っても既存の daemon が再利用されます。
  - `takts manager` / `takts director` は、動いている daemon の環境が選択と違うとき、
    または環境を読めないときに中断して知らせます。実行中のタスクがありうるので daemon は自動で止めません。
  - 切り替えるときは、実行中のタスクが無いことを確かめて `takt daemon stop` で止めてから起動し直します。
  - 素の `takt manager` はこの確認をしません。
  - daemon は manager を閉じて仕事がなくなると自動で止まり、次の起動時の環境で立ち上がり直します。
  - 動いている daemon のアカウントは、`ps -wwE -o command= -p <daemon の pid>` の出力に
    `CLAUDE_CONFIG_DIR` / `CODEX_HOME` があるかで確認できます（pid は `pgrep -f takt/dist/app/daemon/index.js`）。
- takt は Claude SDK を `settingSources: ['project']` で起動します。そのため `~/.claude`
  （会社 Claude では `~/.claude-work`）のユーザー設定と CLAUDE.md は、Claude のステップには読まれません。
  組織の管理設定（managed settings）は、SDK の仕様上この指定にかかわらず読まれます。
- API キー（`anthropic_api_key` など）は config.yaml / runtime.yaml に書かず、`TAKT_ANTHROPIC_API_KEY` 等の環境変数を使います。

## 設定の配置と反映

設定は YAML 2 ファイルと権限プリセットで管理します。全設定項目は
[takt の configuration.md](https://github.com/nrslib/takt/blob/main/docs/configuration.md) を参照。

| ファイル | 配置先 | 中身 |
|---|---|---|
| [config.yaml](config.yaml) | `~/.takt/config.yaml` | 実行制御・作業ディレクトリ・権限（`provider_profiles`）・レートリミット時の退避 |
| [runtime.yaml](runtime.yaml) | `~/.takt/runtime.yaml` | provider / model / ステップごとの振り分け・補助レビュー（companion）・MCP サーバー |
| [provider-options/](provider-options/) | `~/.takt/provider-options/` | ビルトインの `edit` / `readonly` プリセットの上書き（MCP ツールの許可） |

`config.yaml` と `runtime.yaml` は home-manager の `mkOutOfStoreSymlink` でリポジトリへリンクしているため、
編集は即反映されます（リンクの追加・変更時だけ `nxs` が必要）。

`provider-options/` だけは `nxs` のたびに実ファイルとしてコピーしています（`home.activation.taktProviderOptions`）。
takt はプリセットの探索先が symlink だと拒否し、そのプリセットを使う全ワークフローが
`failed to resolve capabilities "readonly"` で読み込めなくなるためです。編集の反映には `nxs` が必要です。

`takt/logs/` `takt/analytics/` は takt が生成するランタイム成果物で、Git 管理外（`.gitignore` 済み）。

- [プロバイダ設定](docs/providers.md) — ステップごとのモデル割り当て、補助レビュー、OpenCode の制約
- [権限と MCP](docs/permissions-and-mcp.md) — 権限モード、ツールの許可、認証とトラブル対応

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
