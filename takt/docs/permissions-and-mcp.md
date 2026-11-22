# takt の権限と MCP

プロバイダの権限モードは [config.yaml](../config.yaml)、MCP サーバーの割り当ては [runtime.yaml](../runtime.yaml)、Claude ステップで許可するツールは [edit](../provider-options/edit.yaml) と [readonly](../provider-options/readonly.yaml) で変更します。プリセットの反映には `nxs` を実行します。[設定の配置と反映](../README.md#設定の配置と反映)

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

## MCP サーバー（runtime.yaml）

`runtime.yaml` の `mcp:` で pencil / drawio / Notion を定義し、内部 agent（selector / assistant / manager）以外の
すべての実行に割り当てています。

| サーバー | 起動方法 | 注意 |
|---|---|---|
| pencil | Pen.app 同梱の MCP サーバー | Pen.app の起動が必要。GUI で開いているファイルを操作する（後述） |
| drawio | `npx -y @drawio/mcp` | 定義の正典は `shared/mcp/servers/`。`task mcp-sync` の対象外なので手で揃える |
| notion | `npx -y mcp-remote@0.15.2 https://mcp.notion.com/mcp` | takt は OAuth を扱えないため、mcp-remote で stdio に変換する |

- **`mcp:` があると、Claude 系のステップは `--strict-mcp-config` で起動します。**
  ここで割り当てた MCP しか使えず、対象リポジトリの `.mcp.json` やプラグインの MCP は読まれません。
  割り当てが空のステップでも同じです。
- codex のステップは strict にならず、`~/.codex/config.toml` の MCP に同名で上書きマージされます。
- プロジェクトの `.takt/runtime.yaml` に `mcp:` があると、グローバルの `mcp:` は丸ごと置き換わります
  （learno は作業クローンの `.pen` に接続する中継をプロジェクト側で定義しています）。
- ワークフローの `mcp_servers` や `config.yaml` の `workflow_mcp_servers`（旧方式）と併用すると、起動前にエラーで止まります。
- `${VAR}` は未定義だと全実行が起動前に落ちるため使っていません。

### Claude ステップでの MCP ツールの許可

takt は Claude を `settingSources: ['project']` で起動するため、`~/.claude/settings.json` の
`permissions.allow` はステップに届きません。許可の無い MCP ツールは
`Claude requested permissions to use mcp__..., but you haven't granted it yet.` で拒否されます。

そこで、ビルトインのステップが参照する権限プリセット `edit` / `readonly` を `takt/provider-options/` で上書きし、
`allowed_tools` に MCP を足しています（探索順は `.takt/provider-options` → `~/.takt/provider-options` → ビルトイン）。

| プリセット | 追加した許可 |
|---|---|
| `edit` | pencil / drawio はサーバー単位で全ツール。Notion は検索・取得・ページ作成と更新・コメントなどの読み書きだけ（削除・移動・予定の操作・エージェントの起動は外す） |
| `readonly` | 書き込みの無いツールだけ（Notion の検索・取得、drawio の参照、pencil の状態取得など） |

- `readonly` で pencil の `execute` を外しているのは、読み取りにも使うが書き込みもできるためです。
  計画・レビューのステップから `.pen` を読ませたくなったら、ここを見直します。
- profile の `options.allowed_tools` は使いません。ステップのプリセットとは合成されずに丸ごと置き換わるため、
  読み取り専用のステップにも Edit / Write の許可が付いてしまいます。
- MCP 以外の中身はビルトインの写しです。takt を更新したら `builtins/ja/provider-options/` との差分を確認してください。

### Notion のログイン

トークンは `~/.mcp-auth/mcp-remote-v1/` に保存されます。失効すると、takt の実行中に Notion だけが使えなくなります。
そのときは次のコマンドでブラウザからログインし直します。

```bash
npx -y -p mcp-remote@0.15.2 mcp-remote-client https://mcp.notion.com/mcp
```

mcp-remote は原作者（geelen）から punkpeye（glama.ai）へリポジトリごと移管されたパッケージです。
更新が頻繁なため版を固定しています。上げるときは公開から 2 週間以上たった版を選んでください。

### pencil の注意点

- ヘッドレスモードが無く、Pen.app が起動していないと `failed to connect to running Pencil app` で失敗します。
- GUI で開いているファイルを操作するため、作業クローンの `.pen` を編集させるときは、
  `filePath` に作業クローン内の絶対パスを渡させてください。渡さないと本体側の `.pen` を編集しえます。

### 既知の問題

- **codex のステップの MCP は、takt の定義だけでは動きません。**
  - npx で起動するサーバーは、codex の既定の起動待ち（10 秒）を超えるとツールが登録されません。
  - 承認が要るツールは `MCP tool call requires approval, but approval policy is never` で止まります。
    takt が codex に `approval_policy: never` を強制するためです。
  - takt の stdio 定義には起動待ちも承認も書けません。そのため drawio は `codex/config.toml` 側で
    `startup_timeout_sec = 60` と `default_tools_approval_mode = "approve"` を指定しています（普段の codex にも効きます）。
  - notion は codex に振っている tag（`coding` / `test-planning`）から外しています。codex の Notion はプラグイン
    （`codex_apps`）経由で使えます。
- **`capabilities` を指定していないステップには、Claude の MCP 許可が付きません。**
  ビルトインでは `audit-*` 系の plan / audit / review / supervise などが該当します。
