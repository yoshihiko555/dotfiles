# 個人用プラグイン台帳

確認日 2026-11-22。個人用 Claude Code は `claude plugin list --json` の `scope: user` と導入登録簿、個人用 Codex は `codex plugin list --json` の `installed` で確認した。「有効」は導入一覧上の状態を示す。OAuth やフックの動作確認は別途行う。

## 共通管理

同期するかどうかは [plugins.json](plugins.json) で決める。Codex の Notion は公式リモート配布だが、導入・有効化は共通同期で管理する。

| CLI | プラグイン ID | 管理方針 | 導入状態 |
|---|---|---|---|
| Claude Code | `context7@claude-plugins-official` | 共通同期 | 有効 |
| Codex | `context7@context7-marketplace` | 共通同期 | 有効 |
| Claude Code | `notion@claude-plugins-official` | 共通同期 | 有効 |
| Codex | `notion@openai-curated-remote` | 共通同期 | 有効 |
| Claude Code | `claude-mem@thedotmack` | 共通同期 | 有効 |
| Codex | `claude-mem@claude-mem-local` | 候補（フック・ワーカーの採用時に再検討） | 導入一覧に登録なし |

## Claude Code 個別管理

| プラグイン ID | 管理方針 | 導入状態 |
|---|---|---|
| `frontend-design@claude-plugins-official` | 個人用 CLI | 有効 |
| `gopls-lsp@claude-plugins-official` | 個人用 CLI | 有効 |
| `lua-lsp@claude-plugins-official` | 個人用 CLI | 有効 |
| `mattpocock-skills@mattpocock` | 個人用 CLI | 有効 |
| `md-prompt@nogu66` | 個人用 CLI | 有効 |
| `pyright-lsp@claude-plugins-official` | 個人用 CLI | 有効 |
| `qa-guide@claude-qamods` | 個人用 CLI | 有効 |
| `skill-creator@claude-plugins-official` | 個人用 CLI | 有効 |
| `swift-lsp@claude-plugins-official` | 個人用 CLI | 有効 |
| `turn-receipt@dotfiles` | [dotfiles の自作プラグイン](../../claude/plugins/turn-receipt/README.md) | CLI は有効と表示。登録簿の導入先ディレクトリが存在せず、動作未確認 |
| `typescript-lsp@claude-plugins-official` | 個人用 CLI | 有効 |

## Codex 個別・アプリ管理

| プラグイン ID | 管理方針 | 導入状態 |
|---|---|---|
| `browser@openai-bundled` | CLI 同梱 | 有効 |
| `visualize@openai-bundled` | CLI 同梱 | 有効 |
| `documents@openai-primary-runtime` | ランタイム付属 | 有効 |
| `pdf@openai-primary-runtime` | ランタイム付属 | 有効 |
| `presentations@openai-primary-runtime` | ランタイム付属 | 有効 |
| `spreadsheets@openai-primary-runtime` | ランタイム付属 | 有効 |
| `template-creator@openai-primary-runtime` | ランタイム付属 | 有効 |
| `github@openai-curated-remote` | アプリ管理 | 有効 |
| `openai-templates@openai-curated-remote` | アプリ管理 | 有効 |
| `pages@openai-curated-remote` | アプリ管理 | 有効 |
| `plugin-management@openai-curated-remote` | アプリ管理 | 有効 |
| `product-design@openai-curated-remote` | アプリ管理 | 有効 |
| `sites@openai-curated-remote` | アプリ管理 | 有効 |
| `visualize@openai-curated-remote` | アプリ管理 | 有効 |
| `work-pets@openai-curated-remote` | アプリ管理 | 有効 |
| `sites@openai-bundled` | CLI 同梱用の個人設定 | 設定に有効フラグあり。CLI の導入一覧にこの ID はない |

## 台帳の更新

1. 個人用の環境で両 CLI の導入一覧を取得する。Claude は user scope を選び、Codex はリモート配布の取得エラーも確認する。リモート取得に失敗した場合、その範囲は「未確認」とする。
2. ID（配布元を含む）ごとに導入・有効状態を照合する。Claude の導入先は `~/.claude/plugins/installed_plugins.json`、Codex の設定フラグは [config.toml](../../codex/config.toml) で確認する。キャッシュだけが残っているものは導入済みに数えない。
3. 確認日と状態を更新する。共通同期の方針も変える場合は [README の反映手順](README.md) に従う。
