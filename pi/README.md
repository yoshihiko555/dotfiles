# pi

MacBook では作業したいリポジトリで `pi` を起動する。ユーザー設定の配置先は `~/.pi/agent/`。拡張本体とその権限ルール（`config/gate.json`）は [pi-harness](https://github.com/yoshihiko555/pi-harness) で管理する。

## 設定の編集先

| 変えたいもの | dotfiles の編集先 | 反映方法 |
|---|---|---|
| 既定のプロバイダ・モデル、表示設定、拡張パッケージの登録 | [settings.json](settings.json) | 下記の手順で実機へコピー |
| 利用できるプロバイダ・モデルの定義 | [models.json](models.json) | Home Manager のリンク経由で pi が読む |
| MCP サーバー | [mcp.json](mcp.json) | 同じくリンク経由。`/mcp` で保存した変更もこのファイルに入る |
| エージェントへの指示 | [共通・開発用の指示](../shared/agents/) と [pi 固有の指示](../shared/agents/diff-pi.md) | `task sync-agents` で [AGENTS.md](AGENTS.md) を生成 |
| スキル | [共通スキル](../shared/skills/common/)・[pi 専用スキル](../shared/skills/pi-only/) | `task sync-skills` で [skills/](skills/) のリンクを更新 |

## settings.json の反映と回収

dotfiles のルートで、変更した側に応じて実行する。

| 操作 | コマンド |
|---|---|
| dotfiles で編集した設定を実機に反映する | `task apply-settings TARGET=pi` |
| pi の `/model` などで変更した設定を dotfiles に取り込む | `task adopt-settings TARGET=pi` |
| 実機に未回収の変更があるか確認する | `task status` の `pi settings` 欄を見る |

Nix の switch でも設定が反映される。実機側に未回収の変更があると上書きを見送る。両側を編集した場合は、回収前に差分を確認する。`deviceId` と `lastChangelogVersion` は回収時に除かれ、反映時には端末側の値が引き継がれる。[MacBook の配布設定](../config/nix/hosts/macbook/dotfiles.nix)

## 設計の経緯

- [設定を dotfiles、拡張を pi-harness に置く理由（ADR-0007）](../docs/adr/ADR-20261013-0007-pi-harness-separate-repo.md)
- [settings.json を実ファイルとして配り、端末固有の値を除く理由（ADR-0008）](../docs/adr/ADR-20261026-0008-pi-settings-mutable-copy.md)
