# ADR-20261123-0001: takt のアカウントは、起動時に Claude・Codex それぞれ個人か会社かを対話で選んで切り替える

- ステータス: 採用
- 決定日: 2026-11-23
- 関連: なし

## 背景

takt は Claude と Codex を併用している。既定の provider は Claude（`claude-sdk`）で、tag `coding` / `test-planning` の実装系ステップだけを Codex に振っている（`takt/runtime.yaml`）。
Claude にも Codex にも個人と会社のアカウントがあり、CLI 単体では設定ディレクトリを環境変数で分けている。

- Claude: 会社用は `CLAUDE_CONFIG_DIR=~/.claude-work`（`ccw`、`shell/zsh/claude.zsh`）
- Codex: 会社用は `CODEX_HOME=~/.codex-work`（`cxw`、`shell/zsh/codex.zsh`）

この ADR の前（2026-11-23 まで）は、takt の切り替えは `taktw` だけだった。`taktw` は `CLAUDE_CONFIG_DIR` を渡すだけなので、Codex のステップは常に個人アカウントで動いていた（変更前の `shell/zsh/takt.zsh`）。
利用者は Codex のステップも会社と個人で切り替えたく、コマンドを使い分けるより起動時に選ぶ方を望んだ。

takt 0.76.1 のソースを読み、次を確かめた（2026-11-23）。

- provider の子プロセスには `process.env` がそのまま渡る（`dist/shared/utils/child-process-env.js` の `buildChildProcessEnv`、Codex は `dist/infra/codex/session-config.js`）
- Codex のホームは `CODEX_HOME` から決まる（`dist/infra/codex/home.js`）
- 環境変数で切り替えるので、同じ provider の中で個人と会社を混ぜることはできない。一方、Claude と Codex は別の変数なので、組み合わせは自由に選べる
- `takt manager` / `takt director` は、`~/.takt` につき 1 つの daemon で動く。動いている daemon は、版と CLI のパスが同じなら環境が違っても再利用される（`dist/features/daemon/lifecycle.js` の `ensureDaemon`）。
  何も確かめずに起動すると、選んだアカウントとは違う daemon に黙ってつながる

会社の ChatGPT ワークスペースは、OSS アプリから ChatGPT プランを使うことを組織設定で禁じている。2026-11-18 に pi から会社アカウントへのログインが拒否された（参照の 2d4a090 / ff5b004）。
takt は Codex を、OpenAI 公式の Codex SDK を通して公式の codex で動かす（`takt install codex` で `~/.takt/codex/` に入る `@openai/codex-sdk` 0.164.0。同梱の codex は `codex --version` で 0.164.0）。この経路が組織設定で許されているかは未確認である。

## 選択肢

### A. `taktw` を残し、組み合わせごとにコマンドを足す（不採用）

- Claude 2 通り × Codex 2 通りで、入口が最大 4 つになる。どれが何を切り替えるか覚える必要があり、利用者の望んだ「起動時に選ぶ」にならない

### B. 起動時に組み合わせを対話で選ぶ入口を 1 つ置く（採用）

- 入口が 1 つで済み、起動のたびに選んだ組み合わせが画面に出る
- 素の `takt` は手を加えずに残せる

## 決定

**takt のアカウントは、起動時に Claude・Codex それぞれ個人か会社かを対話で選ぶ入口（`takts`）で切り替える。**

1. 素の `takt` には手を加えない。親のシェルにどちらの指定も無ければ、Claude・Codex とも個人アカウントで動く。切り替えの入口は `takts` に一本化し、`taktw` は廃止する
2. `takts` は、Claude と Codex の組み合わせを 1 回の選択で決める。端末が無ければ起動しない
3. 会社アカウントは `ccw` / `cxw` と同じ設定ディレクトリを使う。会社 Codex の安全確認（個人用ホームを指していないか、認証用の環境変数の除去）は `cxw` と共用にする
4. 個人を選んだときも、親のシェルから継承した会社側の指定を外す
5. daemon を使うコマンドでは、動いている daemon のアカウントが選択と違うとき、または確認できないときに起動を止めて知らせる。実行中のタスクがありうるので、daemon は自動で止めない
6. OpenCode のステップは切り替えの対象にしない（アカウントが 1 つしかない）

## 検証

- 2026-11-23、MacBook、takt 0.76.1、codex-cli 0.164.0（takt が導入した SDK に同梱）で確かめた
  - 会社 Codex を選んだ状態で、Codex に振られる 1 ステップのワークフローが成功した
  - 記録は `~/.codex-work/sessions` に残り、`~/.codex` には残らなかった
  - 記録上の originator は `codex_sdk_ts` だった。今回拒否されなかっただけで、組織が SDK 経由を許していることの確認ではない
- fzf・takt・ps を差し替えたテストで、4 通りの組み合わせの環境変数、継承した値の除去、daemon の判定（一致・不一致・読めない）を確かめた。本物の daemon での判定は未確認
- 利用者が端末で `takts` を起動し、選択画面から takt を起動できた

## 影響

- 会社 Codex を選ぶと、Codex のステップは `codex-work/config.toml` の設定で動く
  - レートリミットで Codex へ退避したステップの reasoning effort も、こちらの設定に従う。退避先には provider と model しか書けず、effort は Codex 側の設定から決まるためである（`takt/config.yaml` の `rate_limit_fallback` のコメント）
  - MCP のマージ元とユーザースキルも会社側になる（MCP は `takt/runtime.yaml` の `mcp` 節のコメント、スキルは `dist/infra/codex/skill-config.js` が `CODEX_HOME` からホームを決める）
- 会社 Codex でも、trust が `codex-work/config.toml` に書き戻され、Git の差分になる
  - 2026-11-23 の検証で、検証用ディレクトリの trust が書き込まれた。このときは作業クローンを作らずに、そのディレクトリで実行した
  - 作業クローンでも起きるかは未確認。個人側の `codex/config.toml` には takt の作業クローンの trust が並んでいるため、同じ仕組みで起きると推定している
- `runtime.yaml` が実装系のステップから Notion を外しているのは、個人 Codex のプラグインで補える前提である（`takt/runtime.yaml` の `mcp.targets.tags` のコメント）。会社 Codex では、会社側で設定していなければ Notion を使えない
- 素の `takt` は、親のシェルの `CLAUDE_CONFIG_DIR` / `CODEX_HOME` をそのまま使う。`ccw` や `cxw` で動くセッションの中から起動すると、会社側で動くことがある
- daemon の判定は、ps でプロセスの環境変数を読めることに頼っている。2026-11-23 には、環境変数を読めないプロセスがあった（Claude Code の Bash から起動した sleep と zsh）。読めないときは止める
- 素の `takt manager` は daemon のアカウントを確かめない

## 決定しないこと

- 対話を使わない選択（引数や環境変数で選ぶ）: `takt watch` やスクリプトから会社アカウントで動かす必要が出たら決める
- 同じ provider の中でのアカウントの混在（例: Claude の計画は会社、Claude のレビューは個人）: 環境変数がプロセス単位で効くため、この方式ではできない。provider profile ごとに環境を渡せるかは未確認。必要になったら takt の設定項目を調べて決める
- 会社 Codex の SDK 経由が組織設定で拒否された場合の扱い: 拒否されたときに、`takts` から会社 Codex の選択肢を外すかを決める。回避策は取らない
- OpenCode の切り替え: OpenCode に会社アカウントを持ったときに決める

## 参照

- 2d4a090 / ff5b004: pi の会社アカウント用の設定と、その取り消し（組織設定でログインが拒否されたため）
- 手順と注意点: [takt の README](../../README.md#起動とアカウント切替)
