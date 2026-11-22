# Codex CLI

| アカウント | zsh での起動 | 設定・履歴の保存先（既定） |
|---|---|---|
| 個人用 | `cx` または `codex` | `~/.codex` |
| 会社用 | `cxw` | `~/.codex-work` |

会社用は専用の設定とログインを使う。初回の `task codex-work-init`、認証、スキルの同期は [会社アカウントの手順](../codex-work/README.md) を参照。

## 個人用の設定を変えるとき

MacBook では Home Manager が個人用の設定ファイルやディレクトリを `~/.codex/` にリンクする。[MacBook のリンク設定](../config/nix/hosts/macbook/dotfiles.nix)

| 変更したいもの | 編集先・反映方法 |
|---|---|
| CLI の設定 | [config.toml](config.toml) を編集する |
| セッション開始時の hook | [hooks.json](hooks.json) に実行コマンドを登録する。herdr との連携処理は [herdr-agent-state.sh](herdr-agent-state.sh) にある |
| コマンドの実行ルール | [rules/default.rules](rules/default.rules) を編集する |
| エージェントへの指示 | [shared/agents/](../shared/agents/) の `core.md`（共通）、`dev.md`（開発）、`diff-codex.md`（Codex 固有）の該当箇所を編集し、dotfiles のルートで `task sync-agents` を実行する。生成した [AGENTS.md](AGENTS.md) は会社用でも共有する |
| 自作スキル | [shared/skills/](../shared/skills/) の `common/` または `codex-only/` で管理する。追加・削除時は `task sync-skills` で個人用のリンクを更新する |

## 関連手順

- 共通ルールやスキルの配布先を確認する。[共通設定の管理](../shared/README.md)
- 個人用の MCP サーバーやプラグインの登録・同期を行う。[MCP の手順](../shared/mcp/README.md)・[プラグインの手順](../shared/plugins/README.md)
- プロジェクトの trust 登録を確認・整理する。[シェルの trust コマンド](../shell/zsh/README.md#codex-の-trust-設定-trust)
