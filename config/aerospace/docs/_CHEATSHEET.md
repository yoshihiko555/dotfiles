# AeroSpace チートシート

## ワークスペース構成

| キー | WS | モニター | アプリ |
|---|---|---|---|
| `ctrl-1` | M1 | メインDELL | Google Chrome |
| `ctrl-2` | M2 | メインDELL | Dia |
| `ctrl-3` | M3 | メインDELL | WezTerm |
| `ctrl-9` | M4 | メインDELL | （空き枠。Hermes の画面共有等） |
| `ctrl-4` | S1 | サブDELL | Notion |
| `ctrl-5` | S2 | サブDELL | Zed / VS Code / TablePlus |
| `ctrl-6` | S3 | サブDELL | システム設定 / Activity Monitor / CotEditor |
| `ctrl-7` | B1 | Mac本体 | Slack / Discord / Teams |
| `ctrl-8` | B2 | Mac本体 | Mail / Notion Calendar |

配置方針は M 系＝常時見るもの、S 系＝参照・開発・雑務、B 系＝コミュニケーション。
キーは M → S → B の並び順どおりに `ctrl-1`〜`8` を割り当てている。
M4 だけは空き枠のため末尾の `ctrl-9` に置いている。
雑アプリは当初 Mac 本体側の B3 に置いていたが、本体の画面が小さく確認しづらいため
サブ DELL の S3 へ移し、B3 は廃止した（2026-09-02）。

上記アプリは起動時に `on-window-detected` ルールで自動配置される。
ルールに無いアプリは、その時フォーカス中のワークスペースに留まる（catch-all は意図的に置いていない）。

## オーバーレイ系アプリの追従

Aqua Voice の音声入力オーバーレイは、`exec-on-workspace-change` から
`scripts/follow-overlay.sh` を呼んでフォーカス中のワークスペースへ追従させている。

AeroSpace には sticky window（全ワークスペース表示）が無く（GitHub Issue #2、未実装）、
`layout floating` はタイリングエンジンから外すだけでワークスペース束縛は解けないため
（2026-09-02 実測）、この回避策が必要。追従対象は `follow-overlay.sh` の
`FOLLOW_APP_IDS` に bundle ID を足して増やせる。

## キーバインド一覧

### ワークスペース操作

| 操作 | キー |
|---|---|
| ワークスペース切り替え | `ctrl-1` 〜 `9` |
| 同じモニター内で次のWSへ | `ctrl-→` |
| 同じモニター内で前のWSへ | `ctrl-←` |
| アクティブなウィンドウを別WSに移動 | `ctrl-alt-1` 〜 `9` |

`ctrl-←` / `ctrl-→` は macOS の「スペースを左右に移動」の操作感を再現したもの（2026-09-02 追加）。
巡回対象は**フォーカス中のモニターに割り当てられた WS だけ**で、端まで行くと反対側へ回り込む。

| フォーカス中のモニター | 巡回順 |
|---|---|
| メインDELL | M1 → M2 → M3 → M4 →（M1へ戻る） |
| サブDELL | S1 → S2 → S3 →（S1へ戻る） |
| Mac本体 | B1 → B2 →（B1へ戻る） |

AeroSpace 標準の `workspace next|prev` は全 9 WS をアルファベット順
（B1→B2→M1→…→S3）に回るため、3 回押すごとにフォーカスが別モニターへ飛ぶ。
そこで `workspace --stdin` に `list-workspaces --monitor focused` の出力を渡す
`scripts/workspace-cycle.sh` を経由させている。BTT のスワイプも同じスクリプトを呼ぶ。

macOS 側の `ctrl-←` / `ctrl-→`（Mission Control のスペース移動）は
symbolichotkeys 79 / 81 を無効化済みのため衝突しない。
Karabiner の `ctrl-b` / `ctrl-f` → `←` / `→` 変換は ctrl を落として素の矢印を送るので、
ターミナルでの `ctrl-b` / `ctrl-f` がここに誤爆することもない。

移動先の割り当ては `ctrl-N`（切替）と同じ並び。`ctrl-alt-9` で空き枠の M4 へ送れる。
フォーカスは元のワークスペースに留まる（`--focus-follows-window` を意図的に付けていない）。
ウィンドウだけ退避して今の画面で作業を続ける想定のため、モニター移動（`shift-alt-←/→`）
とは方針が異なる。

### ウィンドウ操作

| 操作 | キー | 備考 |
|---|---|---|
| 隣のモニターへ移動 | `shift-alt-←` | BetterTouchTool から移管（2026-09-02） |
| 前のモニターへ移動 | `shift-alt-→` | 同上 |
| ワークスペース全域に広げる | `alt-↑` | `fullscreen` トグル。BTT から移管（2026-09-02） |
| 分割方式を切替 | `ctrl-alt-a` | `tiles` ⇄ `accordion` トグル |

同じアプリの別ウィンドウ（Chrome のプロファイル別など）が分割表示されたときの使い分け:

- **一時的に片方だけ見たい** → `alt-↑`。ただし**同じワークスペース内の別ウィンドウに
  フォーカスを移すと自動解除される**（AeroSpace の仕様）。見比べながらの切り替えには向かない。
- **常に片方を広く使いたい** → `ctrl-alt-a` で accordion に切替。非アクティブ側が端に
  細く畳まれ、フォーカスを移すと入れ替わる。戻すときはもう一度 `ctrl-alt-a`。

BTT に残している機能（AeroSpace に相当コマンドが無い）:

| 操作 | キー | 理由 |
|---|---|---|
| 左半分に最大化 | `alt-←` | **相当コマンドが存在しない**。タイル型は絶対座標スナップの概念を持たない |
| 右半分に最大化 | `alt-→` | 同上 |

**BTT 側の `alt-↑`（最大化）は削除すること。** 両方生きていると二重に発火する。

BTT 版はフローティングウィンドウや AeroSpace 管理外のウィンドウにも効くため、
役割分担として残す方が安全。

### トラックパッドのスワイプ（BTT 側で設定）

仮想デスクトップ切り替えのスワイプ操作を AeroSpace へ移管する手順。
設定済み。以下は新規マシンで GUI から作り直すときの手順として残す
（BTT の設定自体は `config/btt/triggers.json` で管理下にあり、
`task btt-apply` で流し込める。`task btt-export` で回収する）。

1. BTT →「Trackpad」タブ → 対象デバイスを選択
2. 既存の `3 Finger Swipe Left` / `Right` を探す
   （旧設定は `Move Left a Space` / `Move Right a Space` を割り当てていた。
   native Space が 1 つになった今は何も起きない）
3. **ジェスチャは作り直さず、アクションだけ差し替える**。
   Action を `Execute Terminal Command (Async, non-blocking)` に変更し、以下を設定:

   | ジェスチャ | コマンド |
   |---|---|
   | 3 Finger Swipe Left | `/Users/yoshihiko/.config/aerospace/scripts/workspace-cycle.sh next` |
   | 3 Finger Swipe Right | `/Users/yoshihiko/.config/aerospace/scripts/workspace-cycle.sh prev` |

   指を左へ払う＝画面が左へ流れる＝次の WS、という macOS の慣習に合わせている
   （キーボードの `ctrl-→` と同じ向き）。

4. スワイプが効かない場合は macOS 標準ジェスチャと競合している。
   システム設定 → トラックパッド → その他のジェスチャ →
   「フルスクリーンアプリケーション間をスワイプ」を **4本指に変更 or オフ**。

スクリプトは PATH に依存しないよう `/opt/homebrew/bin/aerospace` を直接叩いている
（BTT から起動されるシェルは PATH が最小限のため）。

なお Karabiner が `ctrl-b/f/n/p` を方向キーへ変換している
（`optional: any` なので他の修飾キーと併用しても変換される）。
`alt-←` は `ctrl-alt-b` と押しても同じ。同様に `alt-↑` は `ctrl-alt-p` でも発火する。

### 未設定のウィンドウ操作

**AeroSpace は設定ファイルがあると `[mode.main.binding]` がデフォルトを完全に置き換える。**
書いていないバインドは存在しない。以下は AeroSpace 公式のデフォルトだが、
**このリポジトリでは意図的に設定していない**（2026-09-02 に判断）。

| 操作 | 公式デフォルト | 未設定の理由 |
|---|---|---|
| フォーカス移動 | `alt-h/j/k/l` | tmux の smart-splits ペイン移動と衝突 |
| ウィンドウ入れ替え | `alt-shift-h/j/k/l` | tmux のペインリサイズと衝突 |
| ワークスペース切替 | `alt-1`〜`9` | tmux のウィンドウ切替と衝突（`ctrl-1`〜`9` で代替） |
| WS の次/前へ | `alt-tab` 等 | `ctrl-←`/`ctrl-→` で実装済み（標準の `workspace next` はモニターを跨ぐため不採用） |
| フルスクリーン | `alt-f` | `alt-↑` で実装済み（`alt-f` は Karabiner が `ctrl-f`→`→` を横取りするため不採用） |
| フローティング切替 | `alt-shift-f` | （未検討） |
| リサイズモード | `alt-r` | （未検討） |
| レイアウト切替 | `alt-slash` / `alt-comma` | `ctrl-alt-a`（tiles ⇄ accordion）で実装済み |

AeroSpace はキーを Accessibility API でグローバルに横取りするため、alt 系を取ると
WezTerm 上の tmux が使えなくなる。tmux 側の定義は `config/tmux/conf/smart-splits.conf`
と `config/tmux/conf/session.conf` を参照。

`ctrl-alt-*` は tmux / WezTerm / Karabiner のいずれも未使用のため、
ウィンドウ移動（`ctrl-alt-1`〜`9`）とレイアウト切替（`ctrl-alt-a`）に割り当てた（2026-09-02）。
ただし Karabiner が横取りする `b` / `f` / `h` / `n` / `p` / `q` / `space` は
`ctrl-alt-*` でも変換されるため使えない。

## レイアウトプリセット

シェルスクリプトでアプリ配置を一括切り替え。

| キー | プリセット | 内容 |
|---|---|---|
| `ctrl-shift-1` | デフォルト | `on-window-detected` と同じ対応表を既存ウィンドウへ一括適用 |
| `ctrl-shift-2` | 開発モード | Chrome を M4 へ退避し、M1 に Zed / VS Code を置く（TablePlus は S2 のまま） |

開発モードはメインモニターの使い方だけを変える。B 系（コミュニケーション）は共通。

### プリセットの追加方法

1. `~/.config/aerospace/layouts/` にスクリプトを作成（`default.sh` をコピーして編集）
2. `aerospace.toml` にキーバインドを追加:
   ```toml
   ctrl-shift-3 = 'exec-and-forget ~/.config/aerospace/layouts/my-layout.sh'
   ```

### スクリプトで使える主なコマンド

```bash
# 全ウィンドウ一覧
aerospace list-windows --all --format '%{window-id} %{app-bundle-id}'

# ウィンドウをWSに移動
aerospace move-node-to-workspace --window-id <ID> <WS>

# ワークスペース切り替え
aerospace workspace <WS>

# レイアウト変更
aerospace layout tiles horizontal
```

## モニター固定（設定済み）

```toml
[workspace-to-monitor-force-assignment]
M1 = 2  # DELL U2720QM（メイン）
M2 = 2
M3 = 2
M4 = 2
S1 = 3  # DELL G2422HS（サブ）
S2 = 3
S3 = 3
B1 = 1  # Built-in Retina Display（本体）
B2 = 1
```

モニター番号は `aerospace list-monitors` で確認できる。

## 設定ファイルの場所

```
~/.config/aerospace/
├── aerospace.toml       # メイン設定
├── layouts/
│   ├── default.sh       # プリセット1: デフォルト
│   └── dev.sh           # プリセット2: 開発モード
├── scripts/
│   ├── follow-overlay.sh   # オーバーレイ追従（exec-on-workspace-change）
│   └── workspace-cycle.sh  # モニター内WS巡回（ctrl-←/→ と BTT スワイプ）
└── docs/
    └── _CHEATSHEET.md   # このファイル
```

dotfiles では `config/aerospace/` で管理。out-of-store link のため編集は即時反映される。

## 新しい Mac での前提設定

`nxs` で `config/nix/hosts/macbook/aerospace.nix` を反映すると、次を設定する。

- 「ディスプレイごとに個別の操作スペース」を OFF
- Mission Control の「ウインドウをアプリケーションごとにグループ化」を ON
- AeroSpace と衝突する `ctrl-←` / `ctrl-→` と `ctrl-1`〜`7` を無効化

「ディスプレイごとに個別の操作スペース」は、設定値を反映したあとにログアウトが必要。

native Space の枚数は nix-darwin に対応する option がなく、内部 plist も接続履歴を含む
動的データなので宣言管理しない。新しい Mac では Mission Control を開き、上端に表示される
デスクトップのうち不要なものを閉じて **1 枚だけ**にする。

反映後の値は次で確認する。

```sh
# どちらも 1 なら期待どおり
defaults read com.apple.spaces spans-displays
defaults read com.apple.dock expose-group-apps

# 対象 ID がすべて 0 なら期待どおり
defaults export com.apple.symbolichotkeys - \
  | plutil -convert json -o - -- - \
  | jq '.AppleSymbolicHotKeys | with_entries(
      select(.key == "79" or .key == "81" or
             ((.key | tonumber) >= 118 and (.key | tonumber) <= 124))
    ) | map_values(.enabled)'
```
