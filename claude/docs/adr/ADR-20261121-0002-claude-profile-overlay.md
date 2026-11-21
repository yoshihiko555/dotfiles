# ADR-20261121-0002: Claude Code の profile は、設定ディレクトリを分けず、起動時に設定と指示を重ねて切り替える

- ステータス: 採用
- 決定日: 2026-11-21
- 関連: [ADR-20261121-0012](../../../docs/adr/ADR-20261121-0012-agent-rules-dev-split.md)（前提。普段使いの profile が外す開発向けの規則を、別ファイルに分けた）

## 背景

Claude Code の全セッションに、ブランチ運用・PR・テスト・依存管理といった開発向けの規則が読み込まれている。
全セッションに載る規則は、当てはまらない場面でも従われる。
2026-11-21 には、`CHANGELOG.md` の無いリポジトリでもエージェントが changelog を書こうとしたため、規則に条件を足した（ecf68ac）。
調べもの・相談・文章作成といった普段使いのセッションにも開発向けの規則が載っており、利用者は用途に合わせて読み込む規則を切り替えたいと判断した。
普段使いのセッションで開発向けの規則が実際に害になった事例は、未確認である。

参照の記事は、環境変数 `CLAUDE_CONFIG_DIR` で設定ディレクトリを用途ごとに切り替える方式を紹介している。

- `CLAUDE_CONFIG_DIR` を変えると、`~/.claude` 配下と `~/.claude.json` がすべてそのディレクトリへ移る（[公式 claude-directory](https://code.claude.com/docs/en/claude-directory.md)）。
  ログイン・セッション履歴・MCP の登録・プロジェクトの trust・plugins・memory が、用途ごとに分かれる
- この dotfiles は、会社アカウント用に `CLAUDE_CONFIG_DIR=~/.claude-work`（`ccw`）で 2 つ目の設定ディレクトリを持っている。
  そのために、次のものを個別に用意している。
  - settings.json の apply / adopt: `scripts/apply-managed-settings.sh`、`scripts/adopt-managed-settings.sh`
  - 使用量の集計 `ccu`: `shell/zsh/ccusage.zsh`
  - skills の同期: `taskfiles/skills.yml` の `sync-claude-work-skills`
  - home-manager の配線: `config/nix/hosts/macbook/dotfiles.nix`
- 一方で、`~/.claude-work` に追従していない仕組みもある。
  - plugins と MCP を配る `plugin-manage` / `mcp-sync`（`shared/plugins/README.md`・`shared/mcp/README.md`）
  - ai-inventory の `collect.sh`: `~/.claude` だけを数え、`~/.claude-work` は数えない
- 名前付きで設定を切り替える機能は、公式ドキュメント（settings・cli-reference）に載っていない（2026-11-21 に確認）
- 2026-11-21 に MacBook の Claude Code 2.1.330 で、`claude -p /context` を使い次を確かめた
  - `--settings` で渡した `claudeMdExcludes`・`skillOverrides`・`enabledPlugins` は、そのセッションの読み込みを変え、`~/.claude/settings.json` には書き戻らない
  - `skillOverrides` は個人スキルにだけ効き、プラグインのスキルには効かない
  - `--append-system-prompt-file` の内容は、システムプロンプトの末尾に足されてモデルに届く。`@import` は展開されない

## 選択肢

### A. 用途ごとに `CLAUDE_CONFIG_DIR` を分ける（不採用）

- ログインや履歴まで用途ごとに分かれ、`ccw` と同じ周辺の対応が profile を足すたびに要る。dotfiles で保守する量が profile の数だけ増える

### B. 起動時に設定と指示を重ねる（採用）

- 設定ディレクトリは 1 つのままで、ログイン・履歴・MCP の登録は共有する
- profile 1 つにつき、重ねる設定と足す指示のファイルだけを持てばよい

## 決定

**Claude Code の profile は、設定ディレクトリを分けず、起動時に設定と指示を重ねて切り替える。**

1. profile を付けない起動を開発用の既定とし、profile は既定と違う用途にだけ作る
2. 最初の profile は普段使いとし、開発向けの規則を外して、普段使い向けの指示を足す
3. 起動中の profile が statusline で分かるようにする

## 検証

- 普段使いの profile では、Memory Files から開発向けの規則が外れ、スキルは既定の起動と同じ 101 件のままだった（2026-11-21、2.1.330、`-p /context`）
- 普段使いの profile で起動した Claude に profile 名を尋ねると、足した指示にある名前を答えた
- 起動関数が渡す引数と、誤った profile 名で起動しないことは `scripts/tests/test-ccprof.sh` で確かめる

## 影響

- 設定ディレクトリが 1 つなので、`--resume` の一覧には profile をまたいでセッションが並び、どの profile のものかは区別できないと考えられる（未確認）
- `--settings` と `--append-system-prompt-file` の効き方は Claude Code の版で変わりうる。版を上げたら `-p /context` で読み込みを確かめる
- profile の指示は `@import` できないので、本文を直接書く

## 決定しないこと

- 普段使いで外すスキル・プラグイン: 採用時（2026-11-21、2.1.330）は外さない。普段使いで開発向けのスキルが誤って起動するようになったら決める
- 普段使い向けの指示の中身: 普段使いの profile で、指示が足りない振る舞いや指示に反する振る舞いが出たら直す
- 開発用の profile: 既定の起動と違う開発用の構成が要るようになったら作る
- 会社用（`ccw`）との組み合わせ: 会社アカウントで普段使いの profile が要るようになったら決める

## 参照

- 記事「Claude CodeにProfile機能を導入する」（2026-09-03）: https://zenn.dev/explaza/articles/8ce3ed2bbec7c7
