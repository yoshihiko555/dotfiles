# ADR-20260923-0002: ブラウザの要素を AI に渡す経路を terminal-browser に寄せる

- ステータス: 採用
- 決定日: 2026-09-23
- 関連: [ADR-20260922-0001](ADR-20260922-0001-herdr-migration-trial.md)
  （terminal-browser の導入と、Ghostty 限定で実用という条件）

## 背景

ORCA の内部ブラウザにある「画面の要素を選び、コメントを付けて AI に渡す」機能のオマージュを
作りたかった。ブラウザと AI の間で回したいのは次の 3 つ。

1. 人間が要素を指して、AI に渡す
2. AI が求めに応じてスクリーンショットや DOM を取る
3. AI がページを操作する

2026-09-22 時点では、1 を Dia 用の自作拡張 ui-context
（`~/ghq/github.com/yoshihiko555/browser-extensions/ui-context/`、`/ui-context` スキル）で、
2 と 3 を「Dia を別プロファイル + CDP 付きで起動し agent-browser をつなぐ」で進めていた
（Notion タスク「agent-browser を Dia の CDP に接続する」）。
ADR-20260922-0001 でも「この用途はターミナルかどうかと関係ない」として、
ターミナルブラウザの役目には含めていなかった。

その後 terminal-browser を常用することになったため、同じことを terminal-browser でできないか
調べ直した。

## 選択肢

### A. Dia + agent-browser（CDP）+ ui-context 拡張を続ける

- ui-context は切り抜き画像と computed style まで取れる
- Dia を別プロファイルで起動する必要があり、ログイン状態は付いてこない
- 開発確認のたびに Dia へ切り替えることになる

### B. terminal-browser に自作のピッカーを CDP で注入する（`tbpick` 案）

- terminal-browser は Electron 製で、Chrome 拡張は読めない。ページにスクリプトを足す
  ユーザー設定もない（`register-app` は新規タブのパレット用）
- CDP ポートは `terminal-browser ls --json` で取れるので、ui-context と同じ形式で
  キャプチャを書き出すことはできる

### C. terminal-browser の組み込み機能を使う（採用）

terminal-browser 0.11.1 にはすでに次の 2 つが入っている。

- **`Ctrl+G`（ページメニューの「send to agent」）**: react-grab の要素ピッカーが起動する。
  選んだ要素の文脈（HTML の抜粋、React の開発ビルドならコンポーネント名とソースの位置）が、
  同じタブにある coding agent のペインへ `> ...` の 1 行として入力され、フォーカスもそちらへ移る。
  Enter は押されないので、続けて指摘を書いて送る。herdr にも対応している
- **`terminal-browser action -- <command>`**: 開いているタブに対する agent-browser 互換の CLI
  （snapshot / click / fill / eval / screenshot など）

## 決定

**C を採用する。** ブラウザの要素を AI に渡す経路は、terminal-browser の組み込み機能で運用する。

- 2026-09-23 に localhost:3000（Next.js dev）で要素を選び、別のセッションの Claude Code が
  受け取って、必要な情報を追加で取りに行くところまで確認した
- 自作ピッカー（B）は作らない
- Notion タスク「agent-browser を Dia の CDP に接続する」は、目的を C で満たしたため完了とする

### C で失うもの

- ui-context の切り抜き画像と computed style が付かない
- 送られる内容は空白を詰めた 1 行になるので、長い HTML は読みにくい
- コメントはページ上ではなく、エージェントの入力欄に書く
- Ghostty + herdr クライアント 1 つという terminal-browser の実用条件
  （ADR-20260922-0001）にそのまま従う

## 影響

- dotfiles のファイル変更はない（使うのは terminal-browser 本体の機能だけ）
- ui-context 拡張と `/ui-context` スキルは削除せず残す。これ以上手は入れない
- `Ctrl+G` は herdr / Ghostty のキーバインドと衝突していない（2026-09-23 確認）

## 未確定事項

- 画像や computed style が必要になった場合は B（CDP で注入）を再検討する。
  置き場所は ui-context ではなく dotfiles の `config/terminal-browser/` とする
  （terminal-browser に依存する機能のため）
- terminal-browser 付属のスキルは ADR-20260922-0001 で外したまま。AI が
  `terminal-browser action` を使い分けられていないと感じたら、agent-browser スキルに一節を足す
