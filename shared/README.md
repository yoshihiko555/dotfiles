# エージェント共通設定

## ルールの編集と反映

全 CLI に適用するルールは [core.md](agents/core.md)、開発時のコーディング・テスト・Git 運用は [dev.md](agents/dev.md) を編集する。CLI 固有の指示は [agents/](agents/) の `diff-claude.md`、`diff-codex.md`、`diff-gemini.md`、`diff-pi.md` に置く。

- Claude Code は [CLAUDE.md](../claude/CLAUDE.md) から共通・開発用・Claude 固有のルールを直接読み込む。`daily` プロファイルでは `dev.md` を除く。
- Codex・Antigravity・pi は、編集後に dotfiles のルートで `task sync-agents` を実行する。共通・開発用・各 CLI 固有のルールを連結し、各 CLI の `AGENTS.md` を生成する。[生成タスク](../taskfiles/agents.yml)
- dotfiles 内だけに適用するルールはリポジトリ直下の [AGENTS.md](../AGENTS.md) を編集する。

## スキルの編集と配布

スキルの本体は [skills/](skills/) に置く。共通のものは `common/`、CLI 専用のものは `claude-only/`、`codex-only/`、`antigravity-only/`、`pi-only/`、会社アカウント向けに追加するものは `work/` を使う。

スキルを追加・削除したら、dotfiles のルートで使いたい配布先のタスクを実行する。既存スキルの本文を編集した場合は、リンク先の変更が各配布先に届く。

| 配布先 | リンクするスキル | リンクを更新するコマンド |
|---|---|---|
| 個人用の Claude Code・Codex・Antigravity・pi | `common/` と各 CLI の専用ディレクトリ | `task sync-skills` |
| 会社用 Claude Code | `common/` と `work/` | `task sync-claude-work-skills` |
| 会社用 Codex | `common/`、`codex-only/`、`work/` | `task codex-work-init` |

個人用のリンクは `claude/skills/`、`codex/skills/`、`gemini/config/skills/`、`pi/skills/` に作る。Antigravity は `~/.gemini/config/skills/<スキル名>/SKILL.md` を参照し、MacBook の pi は `~/.pi/agent/skills/` からスキルを読む。pi の拡張の管理先は [pi の README](../pi/README.md) を参照。

会社アカウントの初期設定は [Claude Code](../claude-work/README.md) と [Codex](../codex-work/README.md) の手順に従う。

### 外部スキルの取り込みと更新

GitHub で配布されているスキル（yomiyasu など）は `gh skill install <owner/repo> <skill> --dir shared/skills/common` で取り込み、表のタスクで配布先にリンクする。出典は `SKILL.md` の frontmatter の `metadata.github-*` に記録される。取り込んだ本文は直接編集せず、`task skill-outdated` で更新を確認し、`task skill-update` で差し替える。差し替え後は差分を確認してコミットする。

## MCP・プラグイン

個人用 Claude Code・Codex の接続先は [MCP の登録と同期](mcp/README.md)、プラグインは [プラグインの管理](plugins/README.md) を参照。
