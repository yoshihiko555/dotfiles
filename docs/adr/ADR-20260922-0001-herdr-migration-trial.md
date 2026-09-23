# ADR-20260922-0001: tmux + baton から herdr へ移行する（試用を経て採用）

- ステータス: 採用（2026-09-23 確定。当初の判断予定日 2026-09-27 から前倒し）
- 決定日: 2026-09-22（試用開始） / 2026-09-23（採用確定）
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
- タブ名の自動命名（2026-09-23 にプラグインへ置き換え。下記の節を参照）
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

### tmux 時代に諦めていたものの解禁（2026-09-23 実測）

tmux が Kitty graphics protocol に未対応だったために見送っていた 2 件が、herdr では動く
ことを確認した。採用判断の材料として記録する。

**herdr の Kitty graphics の扱い**（`kitty_graphics` を有効化していない既定状態で実測）

| 経路 | 素の WezTerm | herdr の中 |
| --- | --- | --- |
| Kitty direct placement (`a=T`) | 描画 | 描画 |
| unicode placeholder (`U=1`) | 豆腐が並ぶ | herdr が消費して描画されない |
| iTerm2 inline image | 描画 | herdr が破棄して描画されない |

placeholder 文字と iTerm2 の APC が外側へ届かないことから、herdr は tmux の
`allow-passthrough`（素通し）とは違い、Ghostty コアでパースして処理していると判断できる。
分割・タブ切替・zoom・ID 指定削除のいずれでも二重描画や隣ペインへの漏れは再現しなかった。
なお `terminal.kitty_graphics` フラグは `pane.graphics.*` ソケット API 用で、pty 由来の
Kitty graphics はフラグ無効のまま処理される。WezTerm 側は virtual placement のみ未対応。

**解禁されたもの**

- **Neovim の画像表示**: `snacks.nvim` の image モジュール（実装済み・`cond = false` で休止中
  だった）を `~/.config/use-herdr` の有無で有効化。markdown の画像はカーソルが乗ると自動で
  フロート表示される。本文への inline 埋め込みのみ WezTerm の placeholder 未対応で不可
- **ターミナル内 Web ブラウザ**: Chawan は**見送り**、terminal-browser は**Ghostty 限定で実用**（下記 2 節）

**ターミナルブラウザを見送った理由（2026-09-23）**

Chawan（`cha`）で検証した。以前 Chromium 系（carbonyl / browsh 相当）で「重い」と感じて
断念した経緯があったが、Chawan は独自エンジンで Chromium を積まないため重さは出ず、
画像も herdr 上で表示できた（上流ドキュメントも「tmux は Kitty image protocol 非対応、
ハックへの対応予定なし」と明言しており、tmux のままでは不可能だった）。

しかし自分のプロダクト（Next.js）を開くと、アイコンがすべて `[img]` プレースホルダーに
なり文字に食い込んだ。原因は `<img>` が 0 個で、アイコン 29 個がすべて inline `<svg>`
だったため。Chawan の `nanosvg` デコーダは `<img src="x.svg">` 用で、HTML に直接
埋め込まれた `<svg>` 要素は描画されない。Wikipedia のような文書寄りのページは問題なく
読めるが、モダンな Web アプリの UI 確認には使えない。

そもそも求めていた「画面の要素を選んで AI に渡す」は CDP（Chrome DevTools Protocol）が
本質であり、ターミナルかどうかは関係ない。この用途は agent-browser と Dia 自作拡張
（ui-context）で別途進めているため、ターミナルブラウザは不要と判断した。
（この用途は 2026-09-23 に terminal-browser へ寄せた。[ADR-20260923-0002](ADR-20260923-0002-terminal-browser-element-to-agent.md)）

画像表示の解禁自体は herdr の採否とは独立に成立する（tmux に戻せば自動で無効に戻る）。

### terminal-browser は Ghostty 限定で実用（2026-09-23）

Chawan を見送った直後に [zenbu-labs/terminal-browser](https://github.com/zenbu-labs/terminal-browser)
0.11.1 を評価した。Chawan が独自エンジンで inline `<svg>` を描けなかったのに対し、こちらは
**Electron のオフスクリーンレンダリングで本物の Chromium を動かし、そのピクセルを Kitty graphics で
ペインに描く**方式のため、描画は実ブラウザと同一で Chawan の敗因は起きない。

**実測（60 秒連続スクロール、2 秒 × 30 サンプル。localhost:3000 = Next.js dev、ペイン約 4.4K×2.7K）**

| | WezTerm | **Ghostty** |
| --- | --- | --- |
| 端末プロセス CPU 中央値 | 115.4% | **11.2%** |
| 端末プロセス CPU ピーク | 128.8% | **39.7%** |
| herdr client CPU 中央値 | 31.5% | **3.1%** |
| herdr server CPU 中央値 | 2.9% | 2.7% |
| 端末 RSS 推移 | 3306M → 4452M | **366M → 409M** |
| herdr client RSS 推移 | 1851M → 1799M | **11M 横ばい** |

WezTerm はスクロール中に CPU 約 1.5 コア（端末 115% + client 31.5%）を専有する。Ghostty は合計 15% 未満で、
upstream issue #65 に載っている参考値（Ghostty 15% / herdr 3% / browser 6%）とほぼ一致する。つまり
Ghostty 側が開発元の想定する健全な経路であり、WezTerm 側が異常という関係になる。

**差の正体は direct-kitty ストリームの寿命**

terminal-browser は herdr の中では Kitty のエスケープを自分で書かず、herdr のソケット
（`pane.graphics.info` / `pane.graphics.stream`）経由で direct-kitty 転送を要求する。

| 端末 | `pane.graphics.stream` の挙動 |
| --- | --- |
| WezTerm | 開いたストリームは**例外なく約 3 秒で `stream_closed`**（18:50:50→53 / 19:02:11→14 UTC）。4 回の起動のうち 2 回は要求自体が飛ばなかった（条件は未特定） |
| Ghostty | 19:20:56 に開始し 83 秒以上**開いたまま継続** |

ストリームが死ぬとフレームは PTY 経由のフォールバックを流れる。0.11.1 のフォールバックは
**無制限版**（流量を制限する PR #65 は未マージ）で、これが重さの正体。

確定したのは「どこで起きるか」であって「なぜ閉じるか」ではない。WezTerm が Kitty の確認応答
（`Gi=<id>,p=1;OK`）を 3 秒以内に返していないのか、herdr の WezTerm プロファイルの問題か、
terminal-browser 側の扱いかは切り分けていない。なお WezTerm の `enable_kitty_graphics` は
config に明示指定がないが既定で有効であり、描画自体はできていた。

**実用条件は 2 つ**

1. 外側の端末を Ghostty にすること
2. herdr のクライアントを 1 つに保つこと — Ghostty でも、クライアント構成が変わった瞬間
   （別クライアントの接続 / 離脱）にストリームが閉じる挙動を観測した。#65 も「Mosh クライアントが
   後から attach すると direct-kitty が下りなくなる」と書いており、**Moshi で iPhone / Mac mini から
   2 台目を繋いだ時点で Ghostty でもフォールバックに落ちる**。しかもブラウザは再ネゴシエーションせず、
   開き直すまで重いまま

**端末そのものの素の性能差は小さい**

26MB / 20 万行の色付きテキストを 3 回流す描画ベンチ（同一 herdr ペイン）では、経過秒が
WezTerm 0.59 / Ghostty 0.56（差 5%）、端末 CPU 秒が 0.74 / 0.40、起動直後の RSS が 316MB / 213MB。
**普段遣いのテキスト描画で体感差はない。** 差が出るのは Kitty graphics の経路だけであり、
Ghostty へ移る見返りは「terminal-browser が使えること」であって「端末が速くなること」ではない。

**否定した仮説**

1. herdr のクライアントが 2 つ繋がっていた（脱出路として開いた Ghostty で誤ってアタッチしていた）
   → 解消しても変化なし
2. herdr サーバが `[experimental]` 追加より前から稼働していた → フラグは効いている
   （無効ならストリーム自体が始まらない）
3. screenpipe の CPU 占有（launchd agent が 1 コアを 2 日間 98% 占有していた）→ 停止しても解消せず。
   むしろ WezTerm が空いた分を使い切り 33.8% → 115.4% へ上昇した
4. メモリ不足（32GB）→ swap 0 バイト、swapouts 0、`memory_pressure` の free 60%。不足ではない

### 常用端末を WezTerm から Ghostty へ移行する（2026-09-23 決定）

terminal-browser の実用条件が「外側の端末が Ghostty であること」と確定したため、herdr 用の常用端末を
Ghostty に切り替える。tmux + baton への復帰経路は WezTerm のまま残す（WezTerm の cask・設定は削除しない）。

**移行動機は terminal-browser のみ。** テキスト描画の実測差は 5% で、端末を替えても普段の操作は速くならない。

**決定に至る確認（すべて実機）**

| 論点 | 結果 |
| --- | --- |
| WezTerm の herdr 用キーバインド 23 個 | Ghostty で全部再現。takt の Shift+Enter も既定挙動で通る |
| 見た目（フォント・太さ・背景画像） | 画素比較で一致（下記） |
| 長時間メモリ（Claude Code 起因のリーク報告） | 1.3.1 に修正が入っている。1 時間で 191→202MB。**1 週間観測を継続** |
| 他ホストとの統一 | macOS のみでよいと判断（Ghostty に Windows 版はないが WSL2 は対象外） |

**Ghostty 側の実装（`config/ghostty/`）**

- `herdr.conf`（新規、`config` から `config-file = ?herdr.conf` で読む）: WezTerm の `keybinds-herdr.lua` と同じ対応表。
  Ghostty に Lua は無いので `text:` アクションで prefix（Ctrl+Q = `\x11`）+ キーのバイト列を直接送る
  - Alt 修飾は kitty 形式の CSI u（`\x1b[49;3u` = Alt+1）で送る（動作確認済み）。ESC 前置（`\x1b1`）は
    下記の物理キー既定の陰に隠れて単体では未検証。herdr が外側の端末に kitty keyboard protocol を要求する
    ため ESC + 文字は Alt と解釈されない可能性が高い、という理由で CSI u を採った
  - **Ghostty の既定 `super+digit_N=goto_tab:N`（物理キー指定）が `cmd+N` の上書きより先にマッチする。**
    `cmd+digit_N=unbind` で先に外す必要がある
  - `macos-option-as-alt = true`（WezTerm の `send_composed_key_when_left_alt_is_pressed = false` 相当）
  - Ghostty 既定と挙動が違うもの: `shift+page_up/down` は既定が選択拡張なのでスクロールに戻す。
    `cmd+r` を `reload_config` に（Ghostty には設定の自動リロードが無い）
- フォント: UDEV Gothic 35NFLG Bold 15pt、`adjust-cell-height = 20%`（line_height 1.2）、フォールバック 5 書体。
  `font-thicken = false`（Ghostty だけ太く見えていた原因）
- 背景画像: WezTerm の `hsb.brightness = 0.2` を Ghostty で再現する設定は無い。画像を事前に暗くして不透明で敷く。
  変換式は両端末を並べたスクリーンショットの同一領域を画素比較して求めた: **`out = 0.50 × src − 6`**（sRGB）。
  WezTerm の brightness はリニア光で掛かるため sRGB 上では ×0.5 相当になる。実際の `background.png` は
  この式より明るい（平均 28,37,47 vs 式どおり 17,28,40）。`background-image-position = top-left`
  （WezTerm の既定 `horizontal_align = Left` と同じ範囲を見せる）。`window-colorspace = display-p3`
  （`srgb` だと R だけ 3 割暗く出た: 月の領域で 43,77,98 vs 30,78,100。再起動後に一致を目視確認）
- **窓の透過は使わない**（`background-opacity = 1`）。0.7 にすると Ghostty は背景画像にも透過をかけ、
  下のデスクトップのブラーが全面に乗って白茶ける
- 起動: `initial-command = /bin/zsh -lic herdr`（WezTerm の gui-startup 相当）
- **`herdr.conf` は Ghostty の全ウィンドウに効く。** WezTerm は herdr 用の設定を別ディレクトリ
  （`~/.config/wezterm-herdr`）に分けていたが、Ghostty には条件分岐が無い。Cmd+N で開いた素のシェルでも
  Cmd+W / D / T / S / 1〜9 は herdr 向けのバイト列を送る（閉じるのはウィンドウのボタンか Cmd+Q）。
  素のシェルは herdr の `prefix+t` ポップアップで足りると判断して許容
- 通知: `desktop-notifications = false`（Codex の osascript 通知との二重化防止、WezTerm の NeverShow 相当）、
  ベルは `bell-features = audio` + `Purr.aiff`（WezTerm の afplay 相当）
- AeroSpace: `com.mitchellh.ghostty` を WezTerm と同じ M3 枠へ（`aerospace.toml` と `layouts/{default,dev}.sh`）
- terminal-browser が初回起動の `setup` で `~/.claude` `~/.codex` `~/.agents` `~/.gemini` の `skills/` に自動で張った
  スキルの symlink（`Caskroom/0.11.1/` への絶対パス）は外した。操作 CLI は agent-browser 互換で、スキルの中身は
  「ペインを割って人間の隣に出す」以外 agent-browser の写しのため、導線を 2 本にしない。必要になれば
  agent-browser スキル側に一節を足す。再導入は `terminal-browser setup`

**Ghostty に相当が無いもの**

- WezTerm のコピーモード（`Ctrl+Shift+X`、key_table 30 個）— herdr のコピーモードを使っており不要と確認
- 文字・絵文字ピッカー（`Ctrl+Shift+U`）— macOS の Ctrl+Cmd+Space で代替
- 設定の自動リロード — `Cmd+R` 手動

**観測（1 週間、2026-09-30 まで）**

launchd agent `local.ghostty-mem-watch`（`~/Library/LaunchAgents/`、dotfiles 管理外・一時的）が 10 分ごとに
Ghostty の RSS を `~/.local/state/ghostty-mem.log` へ追記する。通常負荷（Claude ペイン 4〜8 本）で
1 日以内に 2GB を超えたら移行を取り消す。観測が終わったら
`launchctl bootout gui/$(id -u)/local.ghostty-mem-watch && rm ~/Library/LaunchAgents/local.ghostty-mem-watch.plist`。

**ロールバック**: WezTerm で herdr を起動してアタッチするだけ（WezTerm 自体は tmux で起動する）。
Ghostty 側の設定は残しても害はない。

### タブ名の自動命名をプラグインへ置き換えた（2026-09-23）

自作スクリプト `herdr-rename-tab-auto`（`prefix+y` で全タブを付け直す）を、外部プラグイン
[qu8n/herdr-automatic-rename](https://github.com/qu8n/herdr-automatic-rename) v0.11.1 に置き換えた。
押すのが手間、というのが動機。

**なぜ自作を続けなかったか**

herdr には「ペインのフォアグラウンドプロセスが変わった」イベントが存在しない。自作スクリプトを
イベント駆動にしても lazygit や nvim の起動には追従できず、追従できるのはプラグインが提供する
zsh フック（preexec / precmd）だけ。自作をイベント駆動化すると、ループ防止（自分の rename が
`tab.renamed` を再発火する）・ロック（10 並列時の `pane.agent_status_changed` 連射）・
シェルフックの 3 つを実装することになる。

**設定**（`config/herdr/automatic-rename/config.sh`）

| 設定 | 値 | 理由 |
| --- | --- | --- |
| `AGENT_TITLES` | `0` | 既定はフォーカス中ペインのタスク名を出すが、1 タブに claude を 2〜8 本並べる運用ではペイン移動のたびにタブ名が変わる |
| `AUTO_INDEX_WORKSPACES` | `0` | `switch_workspace` 未設定で番号ジャンプを使っておらず、`herdr-agent-console` の ws 列が自前で番号を出しているため二重になる |

タブ側の番号（`AUTO_INDEX` は既定 1 のまま）は残した。`switch_tab = "alt+1..9"` に WezTerm が
Cmd+1..9 を転送しているのに、タブバーには飛び先が出ていなかったため。API の `.number` は
歯抜けで（実測で 2 番目のタブが 13）、飛び先の役には立たない。

**運用上の罠（実測）**

- `clear` アクションは番号を剥がすだけでなく、**全タブを「手動リネーム扱い」として state に記録する**。
  そのまま再有効化すると自動命名が効かない。復旧は `~/.local/state/herdr-automatic-rename/` の削除
- `herdr-rename-tab-auto` を実行すると `tab.renamed` が発火し、プラグインが同じ判定をして
  全タブを opt-out させる。**併用不可**。そのため `prefix+y` はスクリプト実行から
  `plugin_action`（`reset`）へ付け替えた
- プラグインの設定は `$HERDR_PLUGIN_CONFIG_DIR` ではなく固定パス
  `~/.config/herdr-automatic-rename/config.sh` を読む（シェルフックが herdr の外で動くため、
  両者が共有できる場所が必要という設計）

**プラグイン本体は Nix 管理外**

`herdr plugin install qu8n/herdr-automatic-rename` が
`~/.config/herdr/plugins/github/herdr-automatic-rename-<hash>/` へ clone し、
`~/.config/herdr/plugins.json` に絶対パスと content hash を焼き込んだ登録簿を生成する。
このためリポジトリで管理できない（更新も同じコマンドで、自動更新はなく commit 固定）。

新しいマシンで `hxs` しただけでは**タブ名が一切付かない**状態になる。zsh フックは glob が
空振りして無言で素通りし、`prefix+y` は plugin_action の解決に失敗する。再現手順は上記の
install コマンドを打つこと。Nix の activation script で冪等に叩く案は、ネットワーク依存を
activation に持ち込むうえ herdr 自体が採否判断前であるため、2026-09-27 の判断後に持ち越した。
→ 採用確定後の 2026-09-23 に実装した（下記「影響」）。ネットワーク依存は、失敗しても switch を止めず
次の switch で再試行する作りで受け入れた。

スクリプト `herdr-rename-tab-auto` は退路として残し、キー割り当てのみ外していた（採用確定後の 2026-09-23 に削除）。

## 採用の確定（2026-09-23）

常用は **Ghostty + herdr** で確定した。WezTerm はサブ端末として残し、常に tmux + baton で起動する。

- 判断基準（承認待ちの気づきの速さと検出精度で baton より明確に上、かつ操作数は同等以上）を満たした
- Ghostty への移行で、herdr + Ghostty でしかできないこと（terminal-browser、Kitty graphics による
  nvim の画像表示）が揃い、決め手になった

## 影響

- `config/herdr/config.toml` と `config/herdr/bin/`（スクリプト 11 本）を dotfiles 管理下に置いた
- herdr 本体は `homebrew.nix` に登録した
- `config/nvim/lua/plugins/snacks.lua` の image を `~/.config/use-herdr` の有無で有効化した
  （tmux 時代の残像対策だった全画像削除と手動プレビューは撤去）
- タブ名の自動命名を herdr-automatic-rename プラグインへ移した。`config/herdr/automatic-rename/`
  （設定）と `shell/zsh/herdr.zsh`（zsh フック）を追加し、`prefix+y` を `plugin_action` へ
  付け替えた。プラグイン本体だけは Nix 管理外
- terminal-browser を評価するため、`config/herdr/config.toml` に `[experimental] kitty_graphics = true` を
  追加し、`hosts/macbook/homebrew.nix` の `homebrew.casks` に `terminal-browser` を宣言した
  （`cleanup = "zap"` のため宣言しないと switch のたびに消える）。見送る場合は両方を削除する
- 常用端末を Ghostty に切り替えた。`config/ghostty/`（`config` / `herdr.conf` / `background.png`）と
  `config/aerospace/`（Ghostty のワークスペース割当）を変更。WezTerm の設定・cask は tmux 復帰経路として残す
- WezTerm はサブ端末として常に tmux で起動する形に戻し、`~/.config/use-herdr` の切り替えと
  `*-herdr.lua` を削除した。snacks.image の判定は `HERDR_ENV` へ移した（2026-09-23）
- Ghostty の設定を整理した（2026-09-23）。herdr.conf に上書きされていたキー、不透明の窓では効かない
  blur 系、既定値と同じ設定、Cmd+N の素のシェルでしか意味の無い分割移動・スクロール設定を削除。
  窓を透過させない理由と font-thicken の件は上記「常用端末を WezTerm から Ghostty へ移行する」節に残る
- herdr の設定を整理した（2026-09-23）。既定値と同じ設定と無効化済みの mouse_capture を削除し、
  config.toml と bin/ のコメントを簡潔にした（経緯はこの ADR に残る）。退路だった herdr-rename-tab-auto と
  見比べ用の herdr-pane-style を削除
- 通知を「画面内トースト（`delivery = "herdr"`、`prefix+o` で通知元へ移動）+ OS のバナーは
  [dot/herdr-terminal-notifier](https://github.com/dot/herdr-terminal-notifier) プラグイン」の構成にした（2026-09-23）。
  プラグインは herdr アイコンの通知アプリ（terminal-notifier 2.0.0 の作り直し）を同梱し、クリックで該当ペインへ移動する。
  導入前にスクリプト全体と同梱アプリ（リンク先ライブラリ・文字列を本家 2.0.0 と照合）を確認し、commit を固定した。
  通知音は herdr 本体に任せ、プラグイン側は鳴らさない（`config/herdr/terminal-notifier/config.env`）
- herdr プラグイン本体を Nix の switch で揃えるようにした（2026-09-23）。固定リスト `config/herdr/plugins.txt`
  （owner/repo と commit SHA）を `scripts/herdr-plugins-sync.sh` が `home.activation.herdrPlugins` から適用する。
  herdr サーバーが動いていなくても install できることを実測済み。追加・更新のみで、削除は手作業
- macOS の通知バナーは、screenpipe が画面を収録している間は出ない（「ミラーリング中または共有中に通知を許可」が
  オフのため。収録が画面共有とみなされる）。許可はオフのまま運用し、screenpipe は 2026-09-23 に停止した
- 採用確定に伴い、Alfred の `container`（shell）/ `taskfile`（ターミナル実行）/ `Open-VS-or-IT`（wez）を
  tmux・WezTerm から herdr のワークスペース + Ghostty へ向けた（2026-09-23）
- tmux + baton の設定・スクリプトは WezTerm のサブ経路として残す
- Claude Code の baton hook（7 イベント）と `claude/hooks/baton-hook.sh` は削除した（2026-09-23）。
  hook は herdr 側（`session` のときのセッション ID 紐付けのみ）だけになり、WezTerm + tmux で
  Claude を動かしても baton には状態（🤔/✋/💤）が出ない
- リモート（iPhone の Moshi からの接続）は 2026-09-23 に接続を確認した。ただし上記の
  マルチクライアント時の描画バグがあり、スマホを使ったあとは PC 側で attach し直す運用になる

## 撤退条件とロールバック

- 撤退条件: 2026-09-23 に採用を確定したため、試用としての撤退判断は終了。
  以下は将来 herdr をやめる場合の手順として残す
- ロールバック手順:
  1. 即時: WezTerm を起動すれば tmux + baton で使える。ただし状態検出には baton hook の復元が要る
     （`claude/hooks/baton-hook.sh` と `claude/settings.json` / `claude-work/settings.json` の
     7 イベントを git 履歴から戻す）
  2. herdr をやめる場合は追加で `config/herdr/`、`config/ghostty/herdr.conf`（と `config` の読み込み行・
     `initial-command`）、Alfred の `container` / `taskfile` / `Open-VS-or-IT` の herdr 呼び出し（git 履歴の tmux 版へ戻す）、`homebrew.nix` の herdr エントリ、herdr の SessionStart hook を削除する
  3. herdr-automatic-rename を入れたまま撤退する場合は、先に `clear` アクションで
     番号を剥がしてから `herdr plugin uninstall herdr-automatic-rename` する
     （順序を逆にすると renames が番号付けフックを再発火する）。
     `~/.local/state/herdr-automatic-rename/` も削除する
  4. プラグインを外すときは `config/herdr/plugins.txt` から行を消してから `herdr plugin uninstall <id>` する
     （同期スクリプトは削除しないため）。herdr-terminal-notifier は加えて `dotfiles.nix` の config.env の配線を消し、
     システム設定 → 通知 の「herdr」を削除する

## 未確定事項（将来の ADR で扱う）

- herdr の中では、Claude / Codex の hook（`claude_message.sh` / `codex_message.sh`）の OS 通知と
  herdr-terminal-notifier の通知が二重に出る。hook 側を `HERDR_ENV` があるときは出さない形にするか
- screenpipe を再開するか（再開すると通知バナーが出なくなる。Hermes の自動化提案の入力が止まっている）
- リモート（iPhone からの接続）の使い勝手の評価（接続自体は確認済み。描画バグは上記）
- Ghostty のメモリ長期観測の結果（2026-09-30 まで。上記「常用端末を WezTerm から Ghostty へ移行する」）
- Cmd+クリックのリンクオープンは Ghostty でも効かない（2026-09-23 実測）。ただし WezTerm でも同じで、
  herdr がマウスを捕捉しているため端末に届かない（`mouse_capture = false` は上記「できないこと」のとおり
  副作用が大きく無効化済み）。端末の差ではなく herdr の制約
