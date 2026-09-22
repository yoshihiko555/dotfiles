# ADR-20260922-0001: tmux + baton から herdr への移行を試用する

- ステータス: 試用中（最終判断: 2026-09-27 予定）
- 決定日: 2026-09-22
- 関連: なし（`docs/adr/` として最初の ADR）。tmux + baton の選定経緯は
  [config/tmux/docs/decisions/003-baton-vs-claude-squad.md](../../config/tmux/docs/decisions/003-baton-vs-claude-squad.md) /
  [007-ai-session-monitoring.md](../../config/tmux/docs/decisions/007-ai-session-monitoring.md) を参照
  （形式はこの ADR 群と異なる、tmux 領域内の決定ログ）

## 背景

2026-09-03 に一度 herdr を見送っていた。ただしそのときの検証は headless の机上検証にとどまり、
TUI を実際に触った上での判断ではなかった。

2026-09-22 の grilling セッションで方針を見直し、「効率が上がるかを実体験で判断する」と決めた。
判断軸は「移行の重さ」ではなく「効率の伸び」に置いた。現在の並列運用は Claude Code 4 : Codex 3 : takt 3
の内訳で、常時 10 本程度が動いている。

### 棚卸しの実測値（移行対象の規模）

移行を検討するにあたり、置き換え対象の規模を実測した。

| 対象 | 規模 |
|---|---|
| tmux | キーバインド 89 個、スクリプト 26 本 1,211 行、自作パッチ済みバイナリ |
| WezTerm | Cmd 系バインド 26 個（tmux への変換層） |
| baton | Go 7,639 行（テスト 10,536 行） |

## 選択肢

### A. 現状維持（tmux + baton をこのまま使い続ける）

- 移行コストはゼロ
- ただし 2026-09-03 の見送りは headless の机上検証にとどまっており、実体験に基づく判断が
  まだできていない

### B. 切替式で試用する（採用）

- 判断軸を「移行の重さ」ではなく「効率の伸び」に置き直し、実際に触って判断する
- `~/.config/use-herdr` の有無で WezTerm が読む層を切り替える。既定は tmux、巻き戻しは `rm` 1 回
- tmux + baton の設定・スクリプトは削除せずそのまま残す

## 決定

**B を採用。**

- **切り替え式**: `~/.config/use-herdr` の有無で WezTerm が読む層を切り替える。既定は tmux。
  巻き戻しは `rm` 1 回
- **設定は dotfiles 管理下**: `config/herdr/config.toml` と `config/herdr/bin/`（スクリプト 11 本）。
  `~/.config/herdr/` には herdr 自身が書くソケット・ログが同居するため、ディレクトリごとは
  張らずファイル単位で配布する
- herdr 本体は `homebrew.nix` に登録する（`cleanup = "zap"` で宣言外パッケージとして
  自動削除される運用のため）
- **hook あり前提**で運用する。ただし herdr の Claude hook は `session` のときだけ動き
  セッション ID を紐付けるだけで、**承認待ちの判定には関与しない**（判定は常に画面解析）。
  baton の hook とは役割が別物である

### herdr にできないこと（構造的な制約）

- **ペインを ID で直接フォーカスする API がない** — ペイン番号ジャンプ、初期化後の復帰、
  一括起動後の移動が再現できない
- **プロセスを見てキーを送り分ける仕組みがない** — takt の Shift+Enter が構造的に脆い
  （現時点では WezTerm 側の既定動作で通っている）
- **リンクをクリックで開けない** — `mouse_capture = false` にすれば開けるが、サイドバークリック・
  ドラッグコピー・境界リサイズを失う（実測済み）
- **baton の safe auto mode（ルール + Codex レビュアによる自動承認）が再現できない**
- **サイドバーの列を揃える設定がない**
- **ステータスバーのモード別の色分けがない**
- **マルチクライアント時にペイン背景が不透明になる**（herdr 0.9.1、2026-09-23 実測） —
  iPhone（Moshi）から同じセッションに attach したあと、WezTerm 側をクリックしてフォーカスを戻すと、
  それまで透過していたペインが実色で塗られ、WezTerm の背景画像が隠れる。herdr 自身のクロム
  （サイドバー・タブバー）は `panel_bg = "reset"` のまま透過が保たれるので、ペインだけが不透明になる。
  zoom / resize / フォーカス移動 / `OSC 111` では戻らない。**回避策は WezTerm 側で detach → 再 attach**
  （`prefix+q` → `herdr`）。WezTerm 設定・Claude Code・`config.toml` は無関係（すべて切り分け済み）

### 自作で埋めたもの（スクリプト 11 本）

tmux + baton で使っていた機能のうち herdr に無いものを、herdr 用スクリプト 11 本
（`config/herdr/bin/`）で自作した。

- 承認コンソール（baton の TUI 相当。`j`/`k` で移動、`w` で待ちのみ表示、`a` で承認、`d` で拒否、
  Enter でペインへ）
- GHQ picker
- N 分割レイアウト
- ペイン初期化
- チートシート
- 確認付きワークスペース終了
- Alt+HJKL の is_vim 判定
- タブ名の自動命名
- Loupedeck 一括起動
- リポジトリ名表示
- 見た目切替ヘルパー

### herdr スクリプトを書くときの制約（実測で判明。移行するなら全スクリプトに影響）

1. `type = "shell"` は **PATH を引き継がない**（`/opt/homebrew/bin` が無く exit 127）
2. **標準エラー出力がどこにも出ない**（popup も異常終了で即閉じる）
3. **macOS 標準の bash 3.2 が使われる**（`mapfile` が使えない）

## 検証

### 初日の足切り（4 条件すべて通過）

- Neovim の描画の乱れがないこと
- takt の点滅がないこと
- 承認待ちの idle 誤検出がないこと
- 10 並列でもサイドバーが読めること

### 挙動設定の検証（4 項目すべて問題なし）

tmux で依存していた以下の挙動設定に相当するものが、herdr でも問題なく動作することを確認した。

- `escape-time 0`
- True Color と Undercurl
- `focus-events on`
- `allow-passthrough on`

## 影響

- `config/herdr/config.toml` と `config/herdr/bin/`（スクリプト 11 本）を dotfiles 管理下に置いた
- herdr 本体は `homebrew.nix` に登録した
- 試用期間中は tmux + baton の設定・スクリプトを削除せずそのまま残す（切替式のため）
- hook は herdr 側（`session` のときのセッション ID 紐付けのみ）と baton 側（既存の 7 イベント）が
  並存する
- リモート（iPhone の Moshi からの接続）は 2026-09-23 に接続を確認した。ただし上記の
  マルチクライアント時の描画バグがあり、スマホを使ったあとは PC 側で attach し直す運用になる

## 撤退条件とロールバック

- 撤退条件: 2026-09-27（土）に「承認待ちの気づきの速さと検出精度で baton より明確に上、
  かつ操作数は同等以上」を満たすかで判断する。満たさない場合は不採用とする
- ロールバック手順:
  1. 即時: `~/.config/use-herdr` を `rm` すれば tmux + baton に戻る（1 回で完了）
  2. 不採用が確定した場合は追加で `config/herdr/`、`config/wezterm/config/*-herdr.lua`、
     `homebrew.nix` の herdr エントリ、baton の hook 7 イベントを削除する

## 未確定事項（将来の ADR で扱う）

- 2026-09-27 の最終判断そのもの（試用継続の結果、herdr を採用するか tmux + baton に留まるか）
- リモート（iPhone からの接続）の使い勝手の評価（接続自体は確認済み。描画バグは上記）
