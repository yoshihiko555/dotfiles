# Claude Code

| 使いたい環境 | 起動コマンド | 設定ディレクトリ |
|---|---|---|
| 個人用・開発 | `cc` / `claude` | `~/.claude` |
| 個人用・プロキシ経由でモデルを切り替える | `ccx` / `ccx -f` | `~/.claude`。[CLIProxyAPI の初回設定と使い方](../shared/cliproxyapi/README.md) |
| 個人用・調べものや文章作成 | `ccp daily` | `~/.claude`。開発向けの規則を外し、[daily の指示](profiles/daily/prompt.md)を加える |
| 会社アカウント | `ccw` | `~/.claude-work`。[初期設定・設定差分の回収・hooks の確認状況](../claude-work/README.md) |

## プロファイル

`ccp <name>` は、`claude/profiles/<name>/` の設定を重ねて Claude Code を起動する。
`ccp` だけ（または 1 つ目がオプション）なら fzf で profile を選び、残りの引数は `claude` に渡す。
設定ディレクトリは分けないので、ログイン・履歴・MCP 登録は profile をまたいで共有する。
statusline の先頭の箱は、色でアカウント（個人は青・仕事は橙）を、文字で profile（profile なしは `dev`）を表す。

profile を足すときは `claude/profiles/<name>/` を作り、次のどちらか、または両方を置く。

- `prompt.md`: `--append-system-prompt-file` で足す指示。`@import` は展開されないので、本文を直接書く。
- `settings.json`: `--settings` で重ねる設定。`claudeMdExcludes`（CLAUDE.md の除外）・`skillOverrides`（個人スキル）・`enabledPlugins` が使える。`skillOverrides` はプラグインのスキルには効かないので、プラグインごと外す。

読み込まれたものは `ccp <name> -p /context` で確認できる。会社用（`ccw`）との組み合わせは未対応。

プロファイルで設定と指示を重ねる理由は [プロファイルの ADR](docs/adr/ADR-20261121-0002-claude-profile-overlay.md) にある。

## 関連文書

- [共通ルールとスキルの管理](../shared/README.md)
- [turn-receipt の使い方](plugins/turn-receipt/README.md)
- [mattpocock/skills の使い分け](docs/mattpocock-skills-guide.md)（v1.2.3 時点の記録）
- [Claude Code の ADR 索引](docs/adr/DECISIONS.md)
