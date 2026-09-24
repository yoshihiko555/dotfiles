# 共通プラグインの対象調査

確認日: 2026-09-24（Notion の同期移行は 2026-09-25 に更新）。個人用 Claude Code の user scope 導入済み13種、Codex の
`config.toml` にある8種、および会話に提供されたアプリ由来プラグインを対象とした。
ストア全体の網羅ではなく、現在の利用資産を共通管理できるかの調査。

確認元: `claude/settings.json`、`codex/config.toml`、各 CLI の一覧・ヘルプ、
`~/.claude/plugins/installed_plugins.json` / `known_marketplaces.json`、導入済みマニフェスト、
公開元のリポジトリ、Plugin Management の Notion 検索結果。
会社用 `ccw` は個人用同期の対象外（設定上は typescript-lsp が有効）。

## 共通管理に対応する3件

| 対象 | Claude Code の現在 | Codex の現在 | 判定・初期方針 |
|---|---|---|---|
| Context7 | `context7@claude-plugins-official` が有効 | 未登録 | 共通同期対象。Codex は `context7@context7-marketplace` |
| Notion | `notion@claude-plugins-official` が有効 | 公式リモート版の CLI 導入・有効化を確認。直接登録 MCP は削除 | 両 CLI とも同期 |
| claude-mem | `claude-mem@thedotmack` が有効 | ローカル登録なし | Codex は対応するが、初期状態は候補のみ |

### Context7

Upstash は Claude / Codex 向け配布物を別々に提供している。
既存 Claude の配布元を維持し、Codex の ID を対応づける。
Codex 版には MCP と検索スキルが含まれ、導入時に認証が必要になる場合がある。

- [Codex プラグインの公式 README](https://github.com/upstash/context7/blob/master/plugins/codex/context7/README.md)
- [Codex 用 marketplace](https://github.com/upstash/context7/blob/master/.agents/plugins/marketplace.json)

### Notion

同名でも配布内容・認証経路が異なる。Claude の導入済み版は Notion MCP、
Codex のアプリ版には4つのワークフロースキルと外部接続の定義がある。
`codex plugin list --json` で正式 ID `notion@openai-curated-remote` と導入・有効状態を確認し、
`codex plugin add notion@openai-curated-remote --json` の成功を確認した。
この ID を共通同期で使用し、`[mcp_servers.notion]` の直接登録は削除した。
プラグイン経由の `fetch self` で接続と必要なツールの利用権限も確認済み。

Git 配布の `openai/plugins` も調べたが、配布元追加は `openai-curated` の予約名制約で
CLI が拒否したため採用しない。リモート版を CLI で同期すれば、日常の導入管理にアプリ画面は不要。
認証自体はアカウント側で保持され、dotfiles に認証情報を保存しない。

ネットワーク制限下の `codex plugin list --json` はリモート一覧取得に失敗しても
ローカル8件だけを返して成功終了した。その一覧に無いことを未導入の証拠にしない。

### claude-mem

導入済み v13.25.3 の上流には両 CLI 用のマニフェストと Codex 用 marketplace がある。
Codex の ID は `claude-mem@claude-mem-local`、配布リポジトリは `thedotmack/claude-mem`。
MCP だけでなくフック・ワーカーを含むため、対応確認と有効化を分ける。Codex の実動作は未検証。

- [Codex マニフェスト](https://github.com/thedotmack/claude-mem/blob/main/plugin/.codex-plugin/plugin.json)
- [Codex marketplace](https://github.com/thedotmack/claude-mem/blob/main/.agents/plugins/marketplace.json)

## Claude 側のその他10種

| プラグイン | 個人用の状態 | 共通同期から外す理由 |
|---|---|---|
| frontend-design | 有効 | Codex は `shared/skills/codex-only/frontend-design` から配布済み。二重導入を避ける |
| skill-creator | 有効 | Codex に `.system/skill-creator` がある。別実装なので同一プラグイン扱いしない |
| mattpocock-skills | 有効 | 導入済み README では Codex はスキル配布、ネイティブプラグインは計画段階。自動移植しない |
| codex（openai-codex） | 有効 | Claude から Codex を呼ぶプラグイン。Codex 自身への導入は目的が異なる |
| turn-receipt | 有効 | Claude の mod を含む自作プラグイン。両 CLI 向け移植は別作業 |
| swift-lsp | 有効 | Claude 用 LSP 統合。Codex 対応の同等パッケージは今回確認できず |
| gopls-lsp | 有効 | 同上。言語サーバー本体は Nix 共通層（ADR-20260925-0005） |
| typescript-lsp | 有効 | 同上。会社用でも有効 |
| pyright-lsp | 有効 | 同上 |
| playwright | 無効 | 現在の導入物は Claude 向け MCP プラグイン。Codex は Browser を利用中。同等のプラグイン配布は今回確認できず |

[mattpocock の上流 README](https://github.com/mattpocock/skills#installation) も参照。
スキルや MCP を直接配布できることと、プラグインとしての対応は区別する。

## Codex 側のその他

| プラグイン | 確認した状態 | 方針 |
|---|---|---|
| sites / visualize / browser | `openai-bundled` の3件が設定上有効 | アプリ同梱の配布元を維持 |
| documents / pdf / spreadsheets / presentations / template-creator | `openai-primary-runtime` の5件が設定上有効 | ランタイム付属の配布元を維持 |
| github / plugin-management | キャッシュと会話への提供を確認 | アプリ管理。Claude の個人用導入済み一覧に対応物なし |
| openai-templates | キャッシュのみ確認 | 導入・有効状態は未判定。残存キャッシュを管理対象にしない |

似た機能が他製品にあっても、同じ配布物・動作環境とは限らないので共通同期に加えない。
Figma / Pencil / drawio は `shared/mcp/` で管理済み。新たなプラグインを重ねて導入しない。

## 再調査するとき

1. Claude の `plugin list --json` と Codex の `plugin list --json` を確認する。Codex の警告も読む。
2. 上流のマニフェスト・marketplace の ID と内容を確認する。
3. アプリ管理のものはアプリの一覧でも確認し、キャッシュだけで導入済みと判断しない。
4. 対応が確認できたものを `plugins.json` に登録し、`plugin-diff` で確認する。

実装は CLI の 2026-09-24 時点のヘルプに合わせた。
[Codex の仕様](https://developers.openai.com/plugins/concepts/plugins) と
[Claude Code の仕様](https://code.claude.com/docs/en/plugins) は別々に確認する。
