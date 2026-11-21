# Claude Code

## 会社アカウント

`ccw` は `CLAUDE_CONFIG_DIR=~/.claude-work` を付けて Claude Code を起動する。
設定ファイル（`settings.json` / `CLAUDE.md` / `rules`）は個人用と同じく home-manager が
配線する。認証情報・履歴・plugin 状態は Git に含めない。

```bash
# 初回だけ実行
task claude-work-init

# 会社アカウントとして起動・ログイン
ccw
```

| 用途 | コマンド | 設定ディレクトリ |
|---|---|---|
| 個人用 | `claude` / `cc` | `~/.claude` |
| 会社用 | `ccw` | `~/.claude-work` |

> [!WARNING]
> 会社用で **hooks が動くかは未確認。** 詳細は下の「運用メモ」を参照。

<details>
<summary><b>運用メモ</b></summary>

- 配布物は `claude-work/` 配下（`settings.json` / `CLAUDE.md` / `rules`）。
  `statusline.py` / `claude_message.sh` / `hooks/` は `claude/` の実体を共有する。
- `settings.json` は個人用と同じ mutable 実ファイル方式。drift は `task status` で確認し、
  `task adopt-settings TARGET=claude-work` で repo へ回収する。
- `autoMode` は Claude Code が起動環境から自動生成し社内情報を含みうるため、repo には載せない。
  drift 比較から除外し、switch 時は実ファイル側の値をそのまま引き継ぐ。
- 会社用の認証情報、履歴、plugin 状態は Git に含めない。
- **hooks が動くかは未確認。** 以前は会社アカウントに管理設定
  `allowManagedHooksOnly: true` が配信され、`statusLine` /
  `fileSuggestion` / `subagentStatusLine` と hooks が managed 設定のものだけに絞られていた
  （[公式ドキュメント](https://code.claude.com/docs/en/hooks)）。2026-11-21 時点で
  `statusLine` は `ccw` でも動くことを確認した。hooks は確認していない。
- 会社用の drift 検出は `task status` と switch 時の警告の 2 経路として扱う
  （個人用は Stop hook を含めた 3 経路）。hooks が動くと確認できれば 3 経路になる。
- `shared/skills/common/` は個人用・会社用の両方で使ってよい共通スキル置き場。
- `shared/skills/work/` は会社用に追加したいスキル置き場。
- `task sync-claude-work-skills` は `shared/skills/common/*` と `shared/skills/work/*` を `~/.claude-work/skills/` にリンクする。

</details>

## プロファイル

`ccp <name>` は、`claude/profiles/<name>/` の設定を重ねて Claude Code を起動する。
`ccp` だけ（または 1 つ目がオプション）なら fzf で profile を選び、残りの引数は `claude` に渡す。
設定ディレクトリは分けないので、ログイン・履歴・MCP 登録は profile をまたいで共有する。
statusline の先頭の箱は、色でアカウント（個人は青・仕事は橙）を、文字で profile（profile なしは `dev`）を表す。

| 起動 | 用途 | 読み込むもの |
|---|---|---|
| profile なし（`cc` など） | 開発（既定） | すべて |
| `ccp daily` | 普段使い | 開発向けの規則（`shared/agents/dev.md`）を外し、`prompt.md` を足す |

profile を足すときは `claude/profiles/<name>/` を作り、次のどちらか、または両方を置く。

- `prompt.md`: `--append-system-prompt-file` で足す指示。`@import` は展開されないので、本文を直接書く。
- `settings.json`: `--settings` で重ねる設定。`claudeMdExcludes`（CLAUDE.md の除外）・`skillOverrides`（個人スキル）・`enabledPlugins` が使える。`skillOverrides` はプラグインのスキルには効かないので、プラグインごと外す。

読み込まれたものは `ccp <name> -p /context` で確認できる。会社用（`ccw`）との組み合わせは未対応。

[共通ルールとスキル](../shared/README.md) · [turn-receipt](plugins/turn-receipt/README.md) · [ADR 索引](docs/adr/DECISIONS.md)
