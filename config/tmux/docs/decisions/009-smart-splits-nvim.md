# ADR-009: smart-splits.nvim 導入 (Neovim ↔ tmux シームレス移動)

- **状態**: 承認・実施済み
- **日付**: 2026-03-17

## コンテキスト

WezTerm 時代は `actions.lua` の `split_nav()` で Neovim ↔ WezTerm のペイン移動を実装していた。
Phase 6 で WezTerm の `actions.lua` を削除したため、Alt+h/j/k/l で Neovim 内に移動すると
Neovim から tmux ペインへ戻れない状態だった。

tmux 側には `smart-splits.conf` が既にあり、Neovim プロセスを検出して Alt+h/j/k/l を
Neovim に送信する仕組みがある。しかし Neovim 側にそのキーを受け取って tmux に戻す
プラグインが未導入だった。

## 決定

[smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) を Neovim に導入。

### 構成

- **Neovim 側** (`plugins/smart-splits.lua`): tmux バックエンドで Alt+h/j/k/l 移動、Alt+Shift+H/J/K/L リサイズ
- **tmux 側** (`smart-splits.conf`): Neovim プロセス検出 → キーをパススルー

### キーバインド

| キー | Neovim 内 | tmux ペイン |
|------|----------|------------|
| Alt+h/j/k/l | Neovim split 間移動 or tmux ペインに移動 | tmux ペイン間移動 |
| Alt+Shift+H/J/K/L | Neovim split リサイズ or tmux ペインリサイズ | tmux ペインリサイズ |

### 変更内容

- `plugins/smart-splits.lua` 新規作成
- `core/keymaps.lua` の Ctrl+h/j/k/l ウィンドウ移動を削除（smart-splits に統一）

## 注意事項

### Lazy! sync による nvim-treesitter 更新事故

smart-splits インストール時に `Lazy! sync` を実行したところ、全プラグインが更新され
`nvim-treesitter` が `tree-sitter` CLI を要求するバージョンに変わりビルドエラーが発生した。

- **対処**: `lazy-lock.json` で `nvim-treesitter` を元のコミットに復元
- **教訓**: 新規プラグイン追加時は `Lazy! install` を使い、`Lazy! sync` は避ける
