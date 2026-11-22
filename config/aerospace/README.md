# AeroSpace の設定

MacBook と外部ディスプレイ 2 台のウィンドウ配置を管理する。アプリの配置先、キー操作、3 本指スワイプ、自動整列の早見表は [操作チートシート](docs/CHEATSHEET.md) にある。
[Home Manager の設定](../nix/hosts/macbook/dotfiles.nix) がこのディレクトリを `~/.config/aerospace/` にリンクしている。

## ワークスペースの配置方針

メイン DELL（U2720QM、モニター 2）にはブラウザや端末など常時見るものを置く。サブ DELL（G2422HS、3）は参照・開発・雑務、Mac 本体（1）はチャット・メールと常駐ツールに使う。ディスプレイをつなぎ直したときは `aerospace list-monitors` で番号を確認できる。

- M4 は画面共有などに使う空き枠。配置ルールのないアプリやダイアログは、開いたワークスペースに留める。
- 雑務用アプリは小さい本体画面からサブ DELL に移した。Finder が開発中の画面に溜まるのを防ぐため S3 を Finder 専用にし、雑務用に S4、OrbStack 用に B3 を割り当てた。既存の数字キーを保つため、S4 と B3 には空いていたキーを使っている。
- 既存ウィンドウは起動時に通常配置に揃え、その後は個別に移動する。以前の開発用レイアウトと手動の配置プリセットはこの運用に合わせて廃止した。

### 配置を変更するとき

[aerospace.toml](aerospace.toml) の `on-window-detected` がアプリ別の配置先を決める。ワークスペースを増やすときは、空でも残す `persistent-workspaces`、モニターを指定する `workspace-to-monitor-force-assignment`、切り替えキーの `mode.main.binding` も確認する。

| いつ動くか | ファイル | 動作・変更箇所 |
|---|---|---|
| AeroSpace 起動時 | [layouts/default.sh](layouts/default.sh) | TOML の配置ルールを既存ウィンドウにも適用し、最後に M1 を表示する。アプリの対応表は TOML で管理する |
| 新規ウィンドウ検出時 | [scripts/auto-grid.sh](scripts/auto-grid.sh) | アプリ別の移動と floating 化の反映を待ち、移動先のタイルを整列する。途中の再描画を抑えるため、整列コマンドを 1 回の `aerospace eval` にまとめる |
| キー・スワイプでの巡回時 | [scripts/workspace-cycle.sh](scripts/workspace-cycle.sh) | `list-workspaces --monitor focused` の結果を `workspace --stdin` に渡し、同じモニター内を循環する。BTT からも動くよう CLI は絶対パスで呼ぶ |
| ワークスペース切り替え時 | [scripts/follow-overlay.sh](scripts/follow-overlay.sh) | Aqua Voice のオーバーレイを移動先へ追従させる。floating 化しても所属ワークスペースは残るため。追従対象は `FOLLOW_APP_IDS` に bundle ID を追加する |

起動時の一括配置は `if.app-id` が完全一致する移動ルールを読む。追加条件付きのルールや floating 化だけのルールは対象外で、目的のワークスペースにいるウィンドウは動かさない。パーサーに合わせ、ルールは 1 キー 1 行・シングルクォートで記述する。

起動時の配置と自動整列は、リポジトリのルートから実機のウィンドウを動かさずに検証できる。

```sh
python3 -m unittest discover -s config/aerospace/tests
```

配置を手元で確認するときに使う CLI の例。

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

### キー割り当ての理由

AeroSpace のキーはアプリをまたいで効く。端末で使う `alt-h/j/k/l`、`alt-shift-h/j/k/l`、`alt-数字` は空けてある。[tmux のペイン操作](../tmux/conf/smart-splits.conf)・[tmux のウィンドウ切り替え](../tmux/conf/session.conf)

ウィンドウを別ワークスペースへ送るときは、元の画面で作業を続けられるようフォーカスを残す。隣のモニターへ移すときは、同じウィンドウを続けて動かせるようフォーカスも移す。レイアウト切り替えは `ctrl-alt-a`。キーを追加するときは、修飾キーと併用しても働く [Karabiner の変換](../karabiner/karabiner.json) も確認する。例えば `ctrl-alt-p` は `alt-↑` になる。

## 新しい MacBook での設定

1. `nxs` で [macOS 側の設定](../nix/hosts/macbook/aerospace.nix) を反映する。「ディスプレイごとに個別の操作スペース」はオフ、Mission Control の「ウインドウをアプリケーションごとにグループ化」はオンになる。macOS の `ctrl-←/→` と `ctrl-1`〜`7` は無効になり、AeroSpace で使える。
2. ログアウトして再ログインし、ディスプレイの操作スペース設定を反映する。
3. Mission Control で不要なデスクトップを閉じ、macOS の操作スペースを 1 枚にする。枚数は手動で管理する。

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

### BetterTouchTool のスワイプを復元する

[BTT の初回設定](../nix/docs/BOOTSTRAP.md#bettertouchtool-の設定) を済ませ、リポジトリのルートで `task btt-apply` を実行すると、[保存済みのトリガー](../btt/triggers.json) から 3 本指スワイプを復元できる。GUI で変更した内容は `task btt-export` で回収する。

手動で復元する場合は、BTT の「Trackpad」で既存の左右の 3 本指スワイプを選ぶ。アクションを「ターミナルコマンドを実行（非同期、ノンブロッキング）」にし、左には `/Users/yoshihiko/.config/aerospace/scripts/workspace-cycle.sh next`、右には同じパスの `prev` を指定する。macOS のジェスチャと競合する場合は、システム設定の「トラックパッド → その他のジェスチャ」で「フルスクリーンアプリケーション間をスワイプ」を 4 本指かオフにする。

保存済みの BTT 設定では、旧モニター移動、最大化、左右半分への配置トリガーは無効。モニター移動と全画面表示は AeroSpace のキーで操作する。
