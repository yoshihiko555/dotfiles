# AeroSpace チートシート

## ワークスペース構成

| キー | WS | モニター | アプリ |
|---|---|---|---|
| `ctrl-1` | M1 | メイン | Google Chrome |
| `ctrl-2` | M2 | メイン | Dia |
| `ctrl-3` | M3 | メイン | WezTerm |
| `ctrl-4` | S1 | サブ | Notion |
| `ctrl-5` | S2 | サブ | VS Code |
| `ctrl-6` | B1 | Mac本体 | その他 |
| `ctrl-7` | B2 | Mac本体 | Claude Code Desktop + Activity Monitor 等 |

上記アプリは起動時に `on-window-detected` ルールで自動配置される。

## キーバインド一覧

### ワークスペース操作

| 操作 | キー |
|---|---|
| ワークスペース切り替え | `ctrl-1` 〜 `7` |
| ウィンドウを別WSに移動 | `ctrl-alt-1` 〜 `7` |

### ウィンドウ操作

| 操作 | キー |
|---|---|
| フォーカス移動 | `alt-h/j/k/l` (左/下/上/右) |
| ウィンドウ入れ替え | `alt-shift-h/j/k/l` |
| フルスクリーン | `alt-f` |
| フローティング切り替え | `alt-shift-f` |

### レイアウト

| 操作 | キー |
|---|---|
| tiles 切り替え (水平↔垂直) | `alt-/` |
| accordion 切り替え | `alt-,` |

- **tiles**: ウィンドウを分割して並べる。同一WS内に複数ウィンドウがある場合に有効
- **accordion**: 1つをフル表示し、`alt-h/l` で前後のウィンドウに切り替え

### リサイズモード

1. `alt-r` でリサイズモードに入る
2. `h/j/k/l` でサイズ調整（50px単位）
3. `esc` or `enter` で通常モードに戻る

## レイアウトプリセット

シェルスクリプトでアプリ配置を一括切り替え。

| キー | プリセット | 内容 |
|---|---|---|
| `ctrl-shift-1` | デフォルト | Chrome→M1、B1にその他まとめ |
| `ctrl-shift-2` | 開発モード | Chrome→B1、B2にClaude Code Desktop+Activity Monitor |

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

## モニター固定（未設定）

ワークスペースを特定モニターに固定するには:

```bash
# モニター番号の確認
aerospace list-monitors
```

`aerospace.toml` 末尾のコメントを外して設定:

```toml
[workspace-to-monitor-force-assignment]
M1 = 1
M2 = 1
M3 = 1
S1 = 2
S2 = 2
B1 = 'secondary'
B2 = 'secondary'
```

## 設定ファイルの場所

```
~/.config/aerospace/
├── aerospace.toml       # メイン設定
├── layouts/
│   ├── default.sh       # プリセット1: デフォルト
│   └── dev.sh           # プリセット2: 開発モード
└── docs/
    └── CHEATSHEET.md    # このファイル
```

dotfiles では `config/.config/aerospace/` で管理。`task restow-config` で反映。
