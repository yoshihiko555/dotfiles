# Phase 1: lualine.nvim

## 背景

ステータスラインを導入し、モード・ブランチ・診断情報などを常時表示する。

## 選定

lualine.nvim一択。Neovimステータスラインの事実上の標準。

## デフォルトセクション構成

```
| A(mode) | B(branch, diff, diagnostics) | C(filename)    X(encoding, fileformat, filetype) | Y(progress) | Z(location) |
```

デフォルトで十分な情報量。カスタマイズは必要になったときに行う方針。

## 設定ポイント

- `theme = "auto"`: tokyonightが先に読み込まれるため自動検出される
- `globalstatus = true`: 画面下部に1本のステータスラインを表示
- `event = "VeryLazy"`: 起動時間に影響しない遅延読み込み
- nvim-web-devicons: アイコン表示に必要（Nerd Font前提）

## 将来の拡張

- gitsigns導入後: diff sourceをgitsignsに差し替えるとパフォーマンス向上
- LSP: diagnosticsコンポーネントがnvim_diagnosticを自動で使うため追加設定不要
