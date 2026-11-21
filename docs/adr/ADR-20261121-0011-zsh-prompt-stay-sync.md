# ADR-20261121-0011: プロンプトは starship の同期描画のまま使い、Enter ごとの待ちを減らす変更は入れない

- ステータス: 採用
- 決定日: 2026-11-21
- 関連: [ADR-20260928-0006](ADR-20260928-0006-zsh-startup-tuning.md)（前提。その「未確定事項」の command_lag の残りをここで決める）

## 背景

ADR-20260928-0006 で zsh の起動を詰めたあと、Enter から次のプロンプトまでの待ち（zsh-bench の command_lag）が目安の 10ms を超えたまま残った。
原因は starship がプロンプトを同期で描くことで、とくに git の状態の取得が重い。
starship の `git_status` を外すか、powerlevel10k（p10k）に移るかは未確定にしていた。

2026-11-21 に、MacBook（/bin/zsh 5.9、starship 1.27.0）で測り直した。

- zsh-bench（テスト用の 1 万ファイルの git リポジトリ）: first_prompt_lag 133ms、first_command_lag 138ms、command_lag 77ms、input_lag 1.3ms。
  前の 3 つは ADR-20260928-0006 の「検証」の最終行（131 / 135 / 76ms）から変わっていない
- 普段使うリポジトリ 6 つ（追跡ファイル 300〜3,500）で `starship prompt` を 15 回ずつ実行した中央値は 27〜36ms だった。
  git の外では 9ms で、これが starship を起動するだけの時間になる
- 対話 zsh で precmd フックを 1 つずつ計ると、starship 以外（mise・herdr・OSC 133 のマーク）は合計 1.3ms だった。
  OSC 133 は、プロンプト・入力・出力の境目を端末に知らせる semantic prompt マークで、`shell/zsh/prompt-marks.zsh` が出している。
  待ちのほぼすべてが starship の描画である

## 選択肢

### A. 何もしない（採用）

- 普段のリポジトリでの待ちは 30ms 前後で、残りの選択肢はどれも、表示を失うか、まだ実装が固まっていないか、保守がほぼ止まっている

### B. starship のまま、描画の中身を減らす（不採用）

- `git_status` を外すと、普段のリポジトリで 16ms 前後になる（背景と同じ条件で計測）
- Node のリポジトリ 2 つでは、`git_status` だけを外しても 34〜36ms のままだった。言語のバージョン表示も外して、15〜16ms になった（背景と同じ条件で計測）
- starship を起動するだけで 9ms かかるので、どちらを外しても目安の 10ms には届かない。縮む幅に対して、変更あり・ahead などの表示を失う代償が大きい

### C. starship のまま非同期にする（不採用）

- starship 1.27.0 の zsh 初期化は、プロンプトを表示するたびに同期で `starship prompt` を実行する（[src/init/starship.zsh](https://github.com/starship/starship/blob/master/src/init/starship.zsh)）。
  非同期の要望 [#301](https://github.com/starship/starship/issues/301) は 2019-09 に出され、2026-11-21 時点で open のままである
- 非同期で描く `starship prompt --stream` の PR [#7772](https://github.com/starship/starship/pull/7772) は、2026-11-21 時点で open である
- 2026-11-21 に GitHub のリポジトリ検索・コード検索と Web 検索で探した範囲では、保守されているプラグインは見つからず、個人の dotfiles にある断片だけだった
- 自作すると、OSC 133 のマークが壊れるおそれがある。
  Ghostty のシェル統合は、`zle -F` から非同期にプロンプトを書き換えるとマークが消えうるとコード中で注意している（[ghostty-integration](https://github.com/ghostty-org/ghostty/blob/main/src/shell-integration/zsh/ghostty-integration)）。
  `shell/zsh/prompt-marks.zsh` も precmd でマークを PROMPT に足しているので、書き換えの方式に合わせて直す必要がある

### D. 非同期に対応したプロンプトへ移る（不採用）

- p10k は README の冒頭で、サポートは非常に限定的で新機能は足さず、ほとんどのバグを直さないと宣言している（[README](https://github.com/romkatv/powerlevel10k#readme)）。
  ただし 2026-11-19 に v1.21.0 を出している
- p10k が OSC 133 のマークを出すのは既定では iTerm2 のシェル統合を入れた端末だけで、Ghostty では `POWERLEVEL9K_TERM_SHELL_INTEGRATION` の設定が要る（[internal/p10k.zsh](https://github.com/romkatv/powerlevel10k/blob/master/internal/p10k.zsh)）。
  `zle reset-prompt` で入力行がちらつく issue [#2959](https://github.com/romkatv/powerlevel10k/issues/2959) も 2026-11-21 時点で open である
- spaceship と pure は、2026-11-21 時点でも新しい版が出ている（spaceship v4.22.6 が 2026-10-21、pure v1.28.4 が 2026-10-07。`gh api repos/<owner>/<repo>/releases/latest` で確認）。
  ただし、どれに移っても見た目を作り直し、hermes へ広げる作業が伴う。30ms 前後の待ちを消すために払う手間として釣り合わない

## 決定

**プロンプトは starship の同期描画のまま使い、Enter ごとの待ちを減らす変更は入れない。**

1. starship の表示項目（git の状態・言語のバージョン）は減らさない
2. プロンプトの非同期化（自作を含む）と、ほかのプロンプトへの移行はしない

## 検証

- 判断の前提は、普段のリポジトリでの描画が 27〜36ms で、待ちのほぼすべてが starship の描画であることだった。背景の計測で確かめた

## 影響

- command_lag は目安の 10ms を超えたまま残る。1 万ファイル級のリポジトリでは 77ms 前後になる
- 言語のバージョン表示は外部コマンドを呼ぶので、その起動が遅いとプロンプトも待たされる。
  待ちの上限は starship の設定にあり、値と理由は設定ファイルのコメントに書いてある。
  この遅れがどれくらいの頻度で起きるかは未確認である

## 決定しないこと

- starship の非同期化（C）: PR #7772 を含む starship のリリースが出た時点で採否を決める
- 描画の中身を減らすか（B）: Enter のあとの待ちを体感するようになった時点か、node の初回起動の遅れが日常的に起きるようになった時点で決める。
  git の fsmonitor（ファイルの変更を監視する常駐プロセス）による `git_status` の短縮は未計測で、そのときに合わせて測る
- ほかのプロンプトへの移行（D）: 1 万ファイル級のリポジトリで普段から作業するようになった時点で決める

## 参照

- starship の非同期化の要望と実装: [#301](https://github.com/starship/starship/issues/301)、[#7772](https://github.com/starship/starship/pull/7772)
- p10k: [README](https://github.com/romkatv/powerlevel10k#readme)、[v1.21.0](https://github.com/romkatv/powerlevel10k/releases/tag/v1.21.0)、[#2959](https://github.com/romkatv/powerlevel10k/issues/2959)
