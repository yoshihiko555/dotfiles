# ADR-20261121-0012: 開発向けの規則を共通の規則から別ファイルに分け、既定ではすべての CLI に読ませる

- ステータス: 採用
- 決定日: 2026-11-21
- 関連: [Claude ADR-20261121-0002](../../claude/docs/adr/ADR-20261121-0002-claude-profile-overlay.md)（この分割を使う側。普段使いの profile で開発向けの規則を外す）

## 背景

`shared/agents/core.md` は全 CLI 共通の規則で、Claude Code は `claude/CLAUDE.md` の `@import` で、Codex・Gemini・pi は `task sync-agents` が連結した AGENTS.md で読む。
core.md には、伝え方や判断の書き方と並んで、コーディング方針・依存管理（mise / uv）・テスト・Git 運用が入っていた。

Claude Code を調べものや文章作成に使う普段使いの profile では、開発向けの規則を外したい。
理由は [Claude ADR-20261121-0002](../../claude/docs/adr/ADR-20261121-0002-claude-profile-overlay.md) の「背景」に書いた。

- Claude Code は settings の `claudeMdExcludes` で、読み込むファイルをパスの glob で外せる（[公式 memory](https://code.claude.com/docs/en/memory.md) の「Exclude specific CLAUDE.md files」）。
  外せる単位はファイルなので、開発向けの規則だけを外すには別ファイルにする必要がある
- 2026-11-21 に MacBook の Claude Code 2.1.330 で、`--settings` で渡した `claudeMdExcludes` が `@import` 先のファイルも外すことを確かめた（`claude -p /context` の Memory Files で確認）
- 普段の起動（`cc` / `ccf` / `ccx` / `ccw`、takt、herdr からの起動）は profile の起動関数を通らない
- 開発で使う機会のほうが多い（利用者の見立て。用途別の回数は未確認）

## 選択肢

### A. 開発向けの規則を開発用の profile に移す（不採用）

- profile の起動関数を通らない普段の起動から、開発向けの規則が消える

### B. 別ファイルに分け、既定で読み込み、普段使いの profile だけで外す（採用）

- 普段の起動と Codex・Gemini・pi が読む規則は、分割前と変わらない
- 外すのは普段使いの profile の設定 1 行で済む

## 決定

**開発向けの規則を共通の規則から別ファイルに分け、既定ではすべての CLI に読ませる。**

1. 共通の規則には、用途を問わない規則（伝え方・判断の書き方・HTML の置き場・ファイル編集の作法）を置く
2. 開発向けの規則には、コーディング方針・依存管理・テスト・Git 運用を置く
3. Codex・Gemini・pi と、Claude Code の profile を付けない起動は、両方を読む。開発向けの規則を外すのは、Claude Code の普段使いの profile だけにする

## 検証

- 再生成した `codex/` `gemini/` `pi/` の AGENTS.md を行単位で並べ替えて分割前と比べ、違いは自動生成の注記 1 行だけだった
- Claude Code の profile を付けない起動では、Memory Files に共通・開発・Claude 固有の 3 ファイルが並び、合計 2.1k トークンで分割前と同じだった（2026-11-21、2.1.330、`claude -p /context`）

## 影響

- 規則を足すときに、どちらのファイルに置くかを決める必要がある。普段使いでも効かせたい規則は共通へ置く
- 「既存の振る舞いを壊さない」などのコーディング方針は開発側にあるので、普段使いの profile では効かない
- 会社用（`ccw`）の CLAUDE.md も両方を import する。会社用で 3 ファイルが読み込まれるかは未確認である

## 決定しないこと

- 分け目の見直し: 普段使いで開発向けの規則が要る場面が出たら、その節を共通へ移す
