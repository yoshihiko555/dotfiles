# エージェント共通設定

## 共通ルール

- CLAUDE.md / AGENTS.md の実体は `shared/agents/` に集約
  - `core.md`: 全エージェント共通ルール（用途を問わない）
  - `dev.md`: 開発向けルール（コーディング・依存管理・テスト・Git）。Claude の profile `daily` では読み込まない
  - `diff-claude.md` / `diff-codex.md` / `diff-gemini.md` / `diff-pi.md`: CLI 固有の差分
- Claude Code: `claude/CLAUDE.md` が `@import` で core + dev + diff を参照（生成不要）
- Codex / Gemini / pi: `task sync-agents` で core + dev + diff を連結して各 AGENTS.md を生成（pi は `~/.pi/agent/AGENTS.md` へリンク。拡張は別リポジトリ [pi-harness](https://github.com/yoshihiko555/pi-harness)）
- リポジトリルートの `AGENTS.md` は当リポジトリ固有ルールのみ（`CLAUDE.md` は `@AGENTS.md` で橋渡し）
- core.md / dev.md / diff-*.md を編集したら `task sync-agents` を実行すること

## スキル

- スキル本体は `shared/skills/` に集約
  - `common/`: 共通スキル（個人用・会社用の両方で使う）
  - `claude-only/` / `codex-only/` / `antigravity-only/` / `pi-only/`: CLI 専用スキル
  - `work/`: 会社アカウントでも使うことを明示したスキル
- `claude/skills`、`codex/skills`、`gemini/config/skills`、`pi/skills` は相対シンボリックリンクで参照（`pi/skills` は macbook のみ `~/.pi/agent/skills` へリンク）
- Antigravity のグローバルスキルは `~/.gemini/config/skills/<skill-folder>/SKILL.md` として解決される
- リンク更新は `task sync-skills` で実行
- GitHub で配布されている外部スキル（yomiyasu など）は `gh skill install <owner/repo> <skill> --dir shared/skills/common` で取り込み、`task sync-skills` でリンクする
  - 出典は gh skill が SKILL.md の frontmatter（`metadata.github-*`）に記録する。中身は手で直さない
  - 更新は `task skill-outdated` で確認し、`task skill-update` で差し替えてから差分を読んでコミットする
  - 差し替えた時点で全 CLI に効く（リンク先を直接書き換えるため）

接続先とプラグインの同期は、[MCP](mcp/README.md) と [プラグイン](plugins/README.md) を参照。
