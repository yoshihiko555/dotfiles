# カスタムキーバインド

**Leader: `Space`**

## 基本操作

| キー | モード | 説明 |
|------|--------|------|
| `jj` | Insert | Normal モードに戻る |
| `Esc` | Normal | 検索ハイライト解除 |
| `]<Space>` | Normal | カーソル行の下に空行を挿入（Insert に入らない） |
| `[<Space>` | Normal | カーソル行の上に空行を挿入（Insert に入らない） |

## ペイン移動 (smart-splits — Neovim ↔ tmux シームレス)

| キー | 説明 |
|------|------|
| `Alt+h` | 左ペイン |
| `Alt+j` | 下ペイン |
| `Alt+k` | 上ペイン |
| `Alt+l` | 右ペイン |

## ペインリサイズ (smart-splits)

| キー | 説明 |
|------|------|
| `Alt+Shift+H` | 左にリサイズ |
| `Alt+Shift+J` | 下にリサイズ |
| `Alt+Shift+K` | 上にリサイズ |
| `Alt+Shift+L` | 右にリサイズ |

## ウィンドウ操作 (`<leader>w` → `Ctrl+w` プロキシ)

which-key により `<leader>w` が `Ctrl+w` のプロキシとして動作:

| キー | 説明 |
|------|------|
| `<leader>ws` | 水平分割 (`:split`) |
| `<leader>wv` | 垂直分割 (`:vsplit`) |
| `<leader>wc` / `<leader>wq` | ウィンドウを閉じる |
| `<leader>wo` | 他のウィンドウをすべて閉じる |
| `<leader>ww` | 次のウィンドウへ移動 |
| `<leader>w=` | ウィンドウサイズを均等に |
| `<leader>w+` / `<leader>w-` | 高さを増減 |
| `<leader>w>` / `<leader>w<` | 幅を増減 |
| `<leader>wH/J/K/L` | ウィンドウを左/下/上/右に移動 |
| `<leader>wd` / `<leader>w<C-d>` | カーソル位置の診断を表示 |

## バッファ (`<leader>b`)

| キー | 説明 |
|------|------|
| `<leader>bn` | 次のバッファ |
| `<leader>bp` | 前のバッファ |
| `<leader>bd` | バッファ削除 |

## タブ (`<leader>T`)

`<leader>t` は表示切替グループで使用済みのため、タブ操作は大文字 `T` に割り当てている。

| キー | 説明 |
|------|------|
| `<leader>Tn` | 新しいタブ (`:tabnew`) |
| `<leader>Tl` | 次のタブ (`:tabnext`) |
| `<leader>Th` | 前のタブ (`:tabprevious`) |
| `<leader>Td` | タブを閉じる (`:tabclose`) |
| `<leader>To` | ほかのタブをすべて閉じる (`:tabonly`) |

標準操作も併用できる:

| キー / コマンド | 説明 |
|------|------|
| `gt` / `gT` | 次 / 前のタブ |
| `{n}gt` | n 番目のタブへ (例: `2gt`) |
| `:tabnew {file}` | 指定ファイルを新しいタブで開く |
| `:tabmove +1` / `:tabmove -1` | タブを右 / 左へ移動 |
| `<leader>wT` (`<C-w>T`) | 現在のウィンドウを新しいタブへ切り出す |
| `:tabs` | タブ一覧を表示 |

## ファイルエクスプローラ Neo-tree

| キー | 説明 |
|------|------|
| `<leader>e` | Neo-tree を開く / 閉じる |
| `<leader>E` | 現在のファイルを Neo-tree 上で表示 |
| `Y`（tree 内） | 選択したファイル・フォルダの絶対パスをクリップボードへコピー |

## ファイル検索 FzfLua (`<leader>f`)

| キー | 説明 |
|------|------|
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | Grep 検索 |
| `<leader>fb` | バッファ検索 |
| `<leader>fh` | Help 検索 |
| `<leader>fr` | 最近のファイル |
| `<leader>fd` | Diagnostics |

## Git (`<leader>g`)

| キー | 説明 |
|------|------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

## デバッグ (`<leader>d`)

| キー | モード | 説明 |
|------|--------|------|
| `<leader>db` | Normal | ブレークポイントを切り替え |
| `<leader>dB` | Normal | 条件付きブレークポイント（条件式を入力） |
| `<leader>dc` | Normal | デバッグ開始 / 続行 |
| `<leader>do` | Normal | ステップオーバー |
| `<leader>di` | Normal | ステップイン |
| `<leader>dO` | Normal | ステップアウト |
| `<leader>dq` | Normal | デバッグ終了・UI を閉じる |
| `<leader>du` | Normal | デバッグ UI を切り替え |
| `<leader>de` | Normal / Visual | カーソル位置 / 選択範囲の式を評価 |
| `<leader>dr` | Normal | DAP REPL を切り替え |
| `<leader>dt` | Normal（Go のみ） | カーソル付近の Go テストをデバッグ |
| `<leader>dT` | Normal（Go のみ） | 前回の Go テストを再実行 |

VSCode 互換の F キーも同じ操作に割り当てている。`<leader>d` 系と併用できる。

| キー | VSCode | 説明 |
|------|--------|------|
| `F5` | F5 | デバッグ開始 / 続行 |
| `F9` | F9 | ブレークポイントを切り替え |
| `F10` | F10 | ステップオーバー |
| `F11` | F11 | ステップイン |
| `F12` | Shift+F11 | ステップアウト |

ステップアウトだけ VSCode と異なる。tmux が Shift+F11 を `<F23>` に変換して
Neovim へ `<S-F11>` として届かないため、F12 を使う。

パッケージのテストは `<leader>dc` → `Debug test (go.mod)`。
プロジェクトルートを作業ディレクトリにして使う。
導入と操作例は [デバッグガイド](debugging.md) を参照。

## フォーマット

| キー | 説明 |
|------|------|
| `<leader>cf` | 現在のバッファをフォーマット |

保存時にも対応するフォーマッタ、または LSP によるフォーマットを自動実行する。

## 補完 nvim-cmp（Insert / Select モード）

| キー | 説明 |
|------|------|
| `Ctrl+Space` | 補完候補を表示 |
| `Enter` | 選択中の候補を確定 |
| `Tab` / `Shift+Tab` | 次/前の候補、またはスニペット位置へ移動 |
| `Ctrl+b` / `Ctrl+f` | 補完ドキュメントを上/下にスクロール |

## コメント・囲み文字

### Comment.nvim

| キー | モード | 説明 |
|------|--------|------|
| `gcc` | Normal | 現在行のコメントを toggle |
| `gbc` | Normal | 現在行のブロックコメントを toggle |
| `gc{motion}` | Normal | モーション範囲のコメントを toggle |
| `gc` / `gb` | Visual | 選択範囲の行/ブロックコメントを toggle |

### nvim-surround

| キー | モード | 説明 |
|------|--------|------|
| `ys{motion}{char}` | Normal | モーション範囲を囲む |
| `yss{char}` | Normal | 行全体を囲む |
| `ds{char}` | Normal | 囲み文字を削除 |
| `cs{old}{new}` | Normal | 囲み文字を変更 |
| `S{char}` | Visual | 選択範囲を囲む |

## Quickfix (`<leader>x`)

| キー | 説明 |
|------|------|
| `]q` / `[q` | 次/前の quickfix |
| `<leader>xq` | Quickfix 開く |
| `<leader>xc` | Quickfix 閉じる |
| `<leader>xl` | Location list 開く |
| `<leader>xL` | Location list 閉じる |
| `<leader>xd` | Diagnostics → quickfix |

## Trouble（診断一覧 — `<leader>x`）

| キー | 説明 |
|------|------|
| `<leader>xx` | Diagnostics（ワークスペース全体） |
| `<leader>xX` | Diagnostics（現在バッファのみ） |

## Markdown (`<leader>m`)

| キー | 説明 |
|------|------|
| `<leader>mp` | ブラウザプレビュー開始 |
| `<leader>mP` | ブラウザプレビュー停止 |
| `<leader>mr` | エディタ内レンダリング toggle |

Snacks の画像表示は herdr 配下（`HERDR_ENV` あり）でだけ有効。tmux 配下では残像・位置ずれが出るため読み込まない。

- Markdown は画像リンクにカーソルを乗せると自動でフロート表示する（inline 対応端末では本文に埋め込む）
- 画像ファイルは `:edit /path/to/image.png` で開くと表示する。別のバッファ・ウィンドウへ移ると消し、戻ると再表示する
- 画像変換には ImageMagick が必要。表示されない場合は `:checkhealth snacks` で確認する
- 残像が残った場合は `:ImageClear`（同じ端末に表示中のほかの画像も消える）

## Copilot (AI 補完 — Insert モード)

| キー | モード | 説明 |
|------|--------|------|
| `Ctrl+y` | Insert | Copilot 提案を accept |
| `Ctrl+e` | Insert | Copilot 提案を dismiss |

## TODO コメント

| キー | 説明 |
|------|------|
| `]t` / `[t` | 次/前の TODO へジャンプ |
| `<leader>st` | TODO を fzf-lua で横断検索 |

## その他

| キー | 説明 |
|------|------|
| `<leader>?` | バッファローカルキーマップ表示 (which-key) |
