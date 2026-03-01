# Phase 1: nvim-treesitter

## 背景

シンタックスハイライトを正規表現ベースからAST（構文木）ベースに強化する。
対象言語: Go, TypeScript, Python, Lua + 各種設定ファイル形式。

## 重要: mainブランチの破壊的変更

nvim-treesitter は `main` ブランチで全面書き直しが行われた。

| | master（旧） | main（新） |
|---|---|---|
| 対応Neovim | 0.9+ | **0.11+** |
| 設定API | `require('nvim-treesitter.configs').setup()` | `require('nvim-treesitter').setup()` + `vim.treesitter` API |
| モジュール | highlight, indent, incremental_selection | **モジュール廃止**。Neovim組み込みAPIを直接使用 |
| メンテナンス | **凍結** | 活発 |

→ Neovim 0.11.5 を使用しているため **main ブランチ** を採用する。

## コンパニオンプラグイン

| プラグイン | 用途 | 推奨度 |
|-----------|------|--------|
| nvim-treesitter-textobjects | 構文ベースのテキストオブジェクト（関数/クラス単位の選択） | 高（Phase 2で導入検討） |
| nvim-treesitter-context | スクロール時に親関数/クラスを画面上部に固定 | 中 |
| nvim-ts-autotag | HTML/JSXタグの自動閉じ | TSX使用時に検討 |

## 検証結果

- `main` ブランチ + Neovim 0.11.5 で動作確認済み
- Cコンパイラ必須（パーサーをローカルコンパイルするため）
- `build = ":TSUpdate"` でlazy.nvim更新時に自動再コンパイル

## 結論

main ブランチを採用。コンパニオンプラグインはPhase 2以降で段階的に追加する。
