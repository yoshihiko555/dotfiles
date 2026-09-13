# Nix パッチ

このディレクトリの `*.patch` は上流未修正の問題に対する暫定修正。
上流で解決したら該当の override とパッチを取り除く。

---

## tmux の同期描画修正

`tmux-sync-clear.patch` は tmux 3.7c 向けの暫定修正。
`home/packages.nix` で MacBook の tmux のみに追加する。
元のパッチ・Unicode 対応・アロケータ等の Nix ビルド設定は引き継ぐ。

### 修正内容

takt / Ink が同期描画（DECSET 2026）の中で全画面消去を行うと、
tmux が本文の描画前に空画面を端末へ送信・確定することがある。
内部画面と描画待ちデータのクリアは実行し、同期中は端末への全画面消去を保留する。
同期終了時の既存の全画面再描画で、更新済みの内容を表示する。

2026-09-08 のローカル比較では、10ms / 150ms の同期区間を各8回検証し、
空画面の先行確定が未修正版16/16回、修正版0/16回になった。
これは人工出力の検証であり、実際の takt の目視確認や全操作の回帰検証とは区別する。

同日の Nix ビルドでも空画面の先行確定は0/16回だった。
takt 0.64.1 に同梱された TranscriptView / StatusLine / PromptInput を仮想端末で動かし、
80件の長い日本語履歴と推論中・ツール実行中・待機中の表示を模擬した比較では、
空画面のみを確定する同期出力が旧版34回、修正版0回。
日本語の追加入力とコピー（履歴）モードへの出入りも両版で確認した。
LLM は呼び出しておらず、実セッションの目視確認は未実施。

2026-09-09、稼働中サーバーが修正版の実行ファイルを使っていることを確認後、
ユーザーから実際の takt でも点滅しなくなったとの報告あり。

調査記録: https://app.notion.com/p/3d26d81aac5281028876f0d6de84e2fd

### 反映

1. `task nix-fmt` で整形し、`nxbd` で MacBook のビルドと世代差分を確認する。
2. ビルドした tmux を別ソケットで起動し、takt の長い会話・推論・ツール実行と、
   日本語表示・スクロールを確認する。既存サーバーにテスト入力を送らない。
   エージェントによる検証は仮想端末内で行い、ユーザーのタブ・ウィンドウ・
   フォーカスを変更しない。表示の複製や確認用GUIタブも勝手に開かない。
3. 検証後に `nxs` でインストールする。
4. 既存セッションの作業終了後に、普段の tmux サーバーを修正版で起動し直す。
   インストールや設定再読み込みだけでは、起動済みサーバーのコードは変わらない。
   作業中の既定サーバーに `kill-server` を実行しない。
   再起動後の `default` は通常の WezTerm 起動処理に作成させる。
   `tmux new-session -s default` だけで先に作ると baton が起動しない。
   WezTerm の `new-session -A` は既存セッションへ接続するだけなので、
   その状態で WezTerm を開き直しても baton は起動しない。
   空の `default` を作ってしまった場合は、そのシェルで `baton` を実行する。

### 更新・撤回

nixpkgs の tmux 更新時にはパッチ適用と同じ描画条件を再検証する。
上流で解決した場合は `home/packages.nix` の override とパッチを取り除く。
撤回も再ビルド・インストールとサーバー再起動が必要。

---

## takt のレポートフェーズでプロセスが落ちる問題

`takt-report-phase-stream-guard.patch` は takt 0.65.0 向けの暫定修正。
`hosts/macbook/packages.nix` の `taktPackage` で `postInstall` から適用する。
ビルド済みの `dist/*.js` を対象にするため `patches =` ではなく `postInstall` で当てる。

### 症状

ワークフローの Phase 2（レポート生成）でモデルがツール呼び出しを出すと、
次のエラーでワークフロープロセスごと異常終了する。該当ステップだけの失敗にならず、
リトライもされないため、同じ箇所で何度も止まる。

```
ReportPhaseToolCallError: Report phase does not allow tool calls, but provider emitted tool "Bash".
    at detectReportPhaseToolCall (dist/core/workflow/report-phase-runner.js:280:16)
    at Object.onStream (dist/core/workflow/report-phase-runner.js:309:30)
    at flushLines (dist/infra/claude-headless/headless-spawn.js:147:29)
    at Socket.<anonymous> (dist/infra/claude-headless/headless-spawn.js:163:13)
```

2026-09-13、learno の T15（学習ログ実装）で 4 イテレーション連続して同じ箇所で停止し、
ワークフローが完走しなかった。タスク指示書にツール禁止を明記しても再発した
（Phase 2 の `allowedTools` は空配列だが、モデルが tool_use ブロックを出すこと自体は防げない）。

### 原因

`report-phase-runner.js` の `onStream` コールバックは、ツール呼び出しを検出すると
`ReportPhaseToolCallError` を throw する。これは `headless-spawn.js` の
`child.stdout.on('data')` ハンドラから `flushLines()` 経由で同期的に投げられるため、
`runHeadlessCli` の `new Promise(...)` の外（イベントループの別ティック）で発生し、
uncaught exception になる。

上流 0.65.0 の `runSingleReportAttempt` には
`if (error instanceof ReportPhaseToolCallError) return { kind: 'retryable_failure', ... }`
という分岐があるが、throw が EventEmitter 経由で `try/catch` を飛び越えるため**到達しない**。
0.64.1 でも同じ構造で、バージョンを上げても解消しない。

### 修正内容

`stdout` の `data` ハンドラと `close` ハンドラの `flushLines()` 呼び出しを `try/catch` で包み、
捕まえた例外を既存の `rejectOnce(error, true)` に渡す。
第 2 引数 `terminateChild` を `true` にして、レポートを書き終えていない Claude CLI の
子プロセスを SIGTERM で止める。

これで例外が Promise の reject として伝播する。`client.js` はこれを catch して
`status: 'error'` のレスポンスに変換し、`classifyRetryableFailure` が `provider_error` と
分類するため、レポートフェーズは新しいセッションでのリトライ → フォールバックの
既存経路に乗る。リトライが尽きた場合も `ReportPhaseGenerationError` で当該ステップが
失敗するだけで、ワークフロープロセスは落ちない。

`failureReason` は `tool_call` ではなく `provider_error` になるが、
`requiresFreshPhase1` が `false` のままなので Phase 1 の再実行は発生しない。

### 検証

パッチ適用後の `headless-spawn.js` が `node --check` を通ることを確認済み。
適用は `patch -p1 --dry-run` で fuzz なしに当たることを確認している。

### 注意

このパッチはクラッシュを止めるだけで、**Phase 2 でモデルがツールを呼ぶ確率は変わらない**。
レポートに書く値は Phase 1 の最終応答に列挙させる、というペルソナ側の設計が別途必要。

### 更新・撤回

takt を更新したら `patch --dry-run` が通るかを確認する。
`dist/*.js` はビルド生成物なので、上流のリファクタで前後の行が変わると当たらなくなる。
上流で解決した場合は `hosts/macbook/packages.nix` の `taktPackage` とこのパッチを取り除く。

上流 issue: 未報告（報告したら URL をここに追記する）
