# ADR-20260924-0001: 自作 mod turn-receipt を dotfiles のローカル marketplace で常用する

- ステータス: 採用
- 決定日: 2026-09-24

## 背景

2026-09-23 に Claude Mods（function hooks）を調べ、グローバル設定には入れず保留とした。
候補として yash-gadodia/claude-mods の `receipt` を 1 セッションだけ試す予定だった。
receipt はターンのフッターに編集・実行の件数を出し、編集したのに実行していないターンを警告する。

ソースを読んだ時点で、この環境では狙いどおりに働かないことが分かった。

- 「実行」はテストランナー（vitest / jest / pytest / tsc、`go test`、npm 系の test / build など）しか数えない。
  dotfiles で使う `task nix-check`、`nix build`、`bash -n`、編集したスクリプトの直接実行は数えられず、
  編集したターンはほぼ毎回 `⚠ no run` になる
- 実行せずに完了を宣言したかどうかは英語の単語（fixed / verified など）だけで判定する。
  応答は日本語なので、ほぼ発火しない

そこで上流の試用はやめ、考え方を借りて自作する。

## 選択肢（管理形態）

### A. dotfiles 内に置き、ローカルディレクトリの marketplace として登録する（採用）

- ローカルディレクトリの marketplace のプラグインはコピーされず、起動のたびに今のファイルが読み込まれる。
  push や更新の操作がいらない
- マシン間の配布は dotfiles に乗る。Claude の設定を配るのは macbook だけなので、絶対パスで困らない
- 版の固定や公開はできない

### B. 別リポジトリを作り、GitHub の marketplace として配る

- 公開、マシンごとの版の固定、リポジトリ単位の CI ができる
- `plugin.json` に `version` を書かなければ、push するだけで次の起動時に自動更新で届く
- 開発中は `--plugin-dir` で別に起動する必要があり、見る場所も 2 つになる

## 決定

**A を採用する。** 当面は自作が 1 本で、使うのは自分だけ。mod は early access で API の変更に合わせた
修正が多いと見込まれ、直せばすぐ反映される A と相性が良い。
B へはディレクトリと `marketplace.json` を移し、settings の登録先を GitHub に変えるだけで移れる。

あわせて次を決めた。

- **`CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` を個人用 settings の `env` に入れ、全体で有効にする。**
  2026-09-23 に却下した理由（今後入れるプラグインの mod まで全部読み込まれる）は残るが、受け入れる。
  プラグイン単位で許可する設定は見当たらず、自作 mod の常用にはこのフラグが要る。
  導入時点で、インストール済みのプラグインに mod を持つもの（`hooks.json` の `modules`）はない
- **上流 receipt（コミット `f4c1c751f679`、MIT）を元にし、上流の更新は追従しない。**
  判定の中核を書き換えるので、上流の変更はほぼそのまま取り込めない。LICENSE と由来は
  `claude/plugins/turn-receipt/` に残す
- **「実行」は、読み取り系とファイル・git の操作以外のすべての Bash とする。**
  検証コマンドの一覧に足す案もあったが、一覧にない確かめ方（編集したスクリプトの直接実行など）で
  誤警告が出る。`git` はサブコマンドを問わず実行に数えない。`sed -i`・`tee`・`cp` などは編集として数え、
  実行には数えない（Bash だけで編集したターンでも警告が出るように）
- **日本語の完了宣言も軽く検知する。** 「直しました」「修正しました」「修正済み」「テストも通りました」など。
  「確認しました」は読んで確かめただけの場合と区別できないので対象にしない
- **subagent のツール呼び出しも、そのターンの件数に含める。** 任せた編集・検証もそのターンの実績とみなす。
  ターンの締め（`turn.complete`）は main のものだけを見る
- **`plugin.json` に `version` を書かない。** ローカルディレクトリでは関係ないが、B へ移したときに
  バージョンを上げないと更新が届かなくなる罠を避ける。`claude plugin validate` の警告は意図どおり
- 会社用（claude-work）には入れない。個人用で数日使ってから判断する

## 影響

- `claude/plugins/.claude-plugin/marketplace.json`: marketplace `dotfiles` を新設
- `claude/plugins/turn-receipt/`: mod 本体、テスト、LICENSE、README
- `claude/settings.json`: `env.CLAUDE_CODE_ENABLE_FUNCTION_HOOKS`、`extraKnownMarketplaces.dotfiles`
  （`source: directory`）、`enabledPlugins["turn-receipt@dotfiles"]`
- settings の宣言だけでは marketplace が登録されるだけで、プラグインはインストールされない。
  新しいマシンでは switch の後に `claude plugin install turn-receipt@dotfiles` を 1 回実行する。
  switch より前に実行すると実ファイルの settings.json が書き換わり、drift として switch にスキップされる

## 検証

- `claude plugin test`: 上流の 16 件に 5 件を足した 21 件が通る。判定をわざと壊すと 6 件が落ちる
- `claude plugin validate`: 通る（`version` なしの警告のみ）
- 実セッションで `/turn-receipt status` が応答することを確認（2026-09-24）

## 未確定事項

- 数日使い、誤警告の多さと日本語の完了宣言の誤検知（「修正しましたが、まだ動きません」なども拾う）を見直す
- claude-work へ広げるか
- 公開や複数のプラグインが必要になったら B へ移す
- Mods の API が変わって壊れたら直す。Claude Code の更新後に `claude plugin test` で確かめる
