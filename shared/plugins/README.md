# 個人用プラグインの共通管理

Claude Code / Codex の既存プラグインを論理名でまとめ、クライアント別の配布元・ID・導入方針を
[`plugins.json`](plugins.json) で管理する。選定理由と対象外一覧は [`INVENTORY.md`](INVENTORY.md) を参照。
マニフェストやキャッシュをコピー・変換せず、導入は各 CLI の標準コマンドを使う。
自作プラグインの共通配布は対象外。

## 初期対象

| 論理名 | Claude Code | Codex |
|---|---|---|
| context7 | 公式マーケットプレイスの既存プラグインを同期 | Upstash の Codex プラグインを同期 |
| notion | 公式マーケットプレイスの既存プラグインを同期 | 公式リモート配布を CLI で同期。直接登録 MCP は廃止 |
| claude-mem | thedotmack の既存プラグインを同期 | 対応版あり。フック・ワーカーを伴うので初期状態は候補のみ |

初期定義で新規導入候補になるのは Codex の Context7。基盤追加時には実インストールしていない。

## 操作

Python 3.11 以上（標準ライブラリの `tomllib` を使用）が必要。
`list` / `diff` は導入・設定変更を行わない。Git 配布はローカル状態を確認し、
Notion などリモート配布は `codex plugin list --json` でアカウント側の状態を確認するため、
ネットワークと Codex のログインが必要。CLI 自身のキャッシュ更新が発生する場合はある。

```sh
task plugin-list
task plugin-diff
task plugin-diff -- context7 --client codex
task plugin-sync -- notion
task plugin-sync -- context7
task plugin-sync
PYTHONDONTWRITEBYTECODE=1 python3 scripts/tests/test-plugin-manage.py
```

同期対象は個人用の `~/.claude` と `~/.codex`。会社用 `ccw`、プロジェクト単位の導入は対象外。
`CLAUDE_CONFIG_DIR` / `CODEX_HOME` の環境変数には追従せず、起動する CLI にも対象ディレクトリを明示する。
一時環境で検証するときは配布用設定も含めて指定する。

```sh
python3 scripts/plugin-manage.py diff \
  --claude-home /tmp/example/claude \
  --codex-home /tmp/example/codex \
  --claude-source /tmp/example/claude-source.json \
  --backup-dir /tmp/example/backups
```

終了コードは成功 `0`（差分ありも含む）、定義・状態の不正や CLI の失敗 `1`。

## 定義

`plugins.json` の `plugins.<論理名>.clients.<claude|codex>` に以下を置く。

- `id`: クライアント固有の `plugin@marketplace`。同一クライアント内で重複不可。
- `mode`: `sync`（導入・有効化）、`candidate`（採用候補のみ）、`remote`（アプリ管理）。
- `marketplace`: GitHub の `owner/repo`、または Codex 公式リモート配布を表す `remote`。
  `mode: sync` + `marketplace: remote` は CLI 同期対象。`mode: remote`（手動管理）とは異なる。
  現在の共通定義では手動管理の対象はない。
- `note`: 選定上の補足。`description` とあわせて人が読むための情報。

claude-mem を Codex でも使うと決めたら、Codex の `mode` を `candidate` から
`sync` に変更し、`task plugin-diff -- claude-mem` で確認する。
対象の追加時は両 CLI の配布物・ID を確認する。ID を名前から推測して登録しない。

## 同期と設定の関係

1. 共通定義と対象クライアントの設定を検証する。同名マーケットプレイスが別リポジトリを
   指す場合は上書きせず停止する。GitHub 配布と Codex 公式リモート配布に対応。
2. 不足するマーケットプレイスを登録し、未導入・無効の対象を各 CLI で導入・有効化する。
   Claude は `--scope user` を指定する。
   リモート配布は配布元の追加を行わず、`codex plugin add <ID>` を使う。
3. ローカルの登録・キャッシュ、またはリモートの導入・有効状態を再検査する。CLI が成功終了しても差分が残れば失敗扱いにする。
4. Claude の対象フラグを dotfiles の `claude/settings.json` にも反映し、Nix 再適用時の巻き戻りを
   防ぐ。対象外キーと symlink は保持する。

Claude の実設定は `~/.claude/settings.json`、導入登録簿は `~/.claude/plugins/installed_plugins.json`。
Codex の実設定は `~/.codex/config.toml`（この環境では `codex/config.toml` へのリンク）。
共通定義が管理対象の導入方針の正典で、これらの有効化フラグは CLI 用の反映先となる。
Claude の Nix 配布済み比較用ファイル `.settings.json.nix-managed` は変更しないので、
配布用設定を更新した場合は次の Nix 適用まで `task status` で drift が出ることがある。

`sync` は有効化を意図する。無効化・削除・バージョン固定・更新は扱わない。
導入済みプラグインを自動アップグレードせず、定義から外しても削除しない。
本体の更新は各 CLI の操作で行う。

## 判定の限界

- Claude は user scope の登録・導入ディレクトリ・有効化フラグを確認する。
  project / local scope の登録だけでは導入済みとみなさない。
- Codex の Git 配布は設定の登録・有効化とマニフェストを持つキャッシュを確認する。
  孤立したキャッシュ（`.orphaned_at`）やキャッシュだけの残存を導入済みとみなさない。
- `marketplace: remote` は CLI のリモート一覧で導入・有効状態を確認する。取得失敗・タイムアウト・
  不正な応答は未導入とみなさず停止する。初回のアカウント認証は同期とは別途必要。
- `mode: remote` は常に「アプリ管理（状態未検証）」とする。キャッシュや `config.toml` から
  アカウント側の導入状態を推測せず、アプリで確認する。
- OAuth、フック信頼、ツール動作、管理ポリシーやプロジェクト設定による上書きは別途確認する。
- Context7 導入時は CLI が OAuth 認証を始めることがある。標準プロンプトに従い、
  導入後は新しいセッションで読み込む。

## バックアップ・途中失敗

変更がある同期では `~/.local/state/dotfiles/plugin-backups/sync-*/` に更新前の設定・Claude 登録簿と
`index.json`（元の実体パスと存在状態）を保存する。ディレクトリは所有者だけがアクセスできる。
途中失敗は部分反映があり得るので、再度 `plugin-diff` で確認する。
必要なら CLI を終了し、`index.json` をもとに設定を復旧する。
**キャッシュ・アカウント状態はバックアップしないため、完全な導入のロールバックではない。**
同期同士はロックするが、アプリの設定変更までは排他できない。同期中は設定を同時編集しない。

Notion の `[mcp_servers.notion]` は移行時に削除済み。プラグイン内部の MCP は引き続き利用する。
同期処理自体は直接登録 MCP を削除しない。Figma / Pencil / drawio は既存の共通 MCP 管理を維持する。
接続定義の管理は [`../mcp/README.md`](../mcp/README.md) を参照。
