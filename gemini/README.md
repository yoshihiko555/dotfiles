# Antigravity CLI

MacBook では作業したいリポジトリに移動して `agy` を起動する。プロンプトを渡して一度だけ実行し、ターミナルコマンドを使わせる場合はサンドボックスを明示する。

```bash
agy -p "git status --short で作業ツリーの状態を確認してください" --sandbox
```

## 設定の変更先

`agy` は `~/.gemini/` 配下を読む。以下は dotfiles 側の編集先と MacBook への反映方法。

| 変えたいもの | 編集先 | 反映方法 |
|---|---|---|
| モデル・ツール権限 | [settings.json](antigravity-cli/settings.json) | 下表の `antigravity-settings` |
| キー割り当て | [keybindings.json](antigravity-cli/keybindings.json) | 下表の `antigravity-keybindings` |
| MCP サーバー | [mcp_config.json](antigravity/mcp_config.json) | Home Manager のリンク経由で参照 |
| エージェントへの指示 | [共通・開発用の指示と CLI 別の差分](../shared/agents/)（`core.md`、`dev.md`、`diff-gemini.md`） | `task sync-agents` で [AGENTS.md](AGENTS.md) を生成 |
| スキル | [共通スキル](../shared/skills/common/)・[Antigravity 専用スキル](../shared/skills/antigravity-only/) | `task sync-skills` で [config/skills/](config/skills/) のリンクを同期 |

権限設定は `proceed-in-sandbox` と拒否ルールを使う。リポジトリの `permissions.allow` は `read_url(antigravity.google)` と `command(agy)` の2件。採用理由、当時の実測、CLI 更新時の再検証手順は [権限設計の ADR](docs/adr/ADR-20260806-0001-headless-sandbox.md) にまとめている。領域内の決定は [意思決定ログ](docs/adr/DECISIONS.md) からたどれる。

## 設定の反映と回収

`agy` は起動時に設定を書き戻す。以前は `settings.json` のシンボリックリンクが実ファイルに置き換わり、リポジトリ側の編集が届かないことがあった。MacBook の Home Manager は `settings.json` と `keybindings.json` を書き込み可能な実ファイルとして配り、前回反映した内容のコピーも保存する。[配布設定](../config/nix/hosts/macbook/dotfiles.nix)

dotfiles のルートで、変更した側に応じて実行する。

| 対象 | dotfiles の編集を実機に反映 | 実機の変更を dotfiles に回収 |
|---|---|---|
| 設定 | `task apply-settings TARGET=antigravity-settings` | `task adopt-settings TARGET=antigravity-settings` |
| キー割り当て | `task apply-settings TARGET=antigravity-keybindings` | `task adopt-settings TARGET=antigravity-keybindings` |

Nix の switch でも同じ反映処理が走る。実機側に未回収の変更があると、そのファイルの上書きを見送る。回収は実機の JSON 全体を dotfiles にコピーするので、両側を編集したときは先に差分を確認する。[反映スクリプト](../scripts/apply-managed-settings.sh)・[回収スクリプト](../scripts/adopt-managed-settings.sh)
