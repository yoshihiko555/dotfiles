# ADR-003: lualine.nvimの最小構成での導入

- **Phase**: 1
- **Status**: accepted
- **Date**: 2026-03-02

## Context

ステータスラインを導入し、現在のモード・gitブランチ・LSP診断情報などを常時表示したい。

## Decision

**lualine.nvim** をデフォルト構成 + 最小限のカスタマイズで導入する。

設定:
- `theme = "auto"`: tokyonight moonを自動検出
- `globalstatus = true`: 画面下部に統一ステータスライン
- `event = "VeryLazy"`: 遅延読み込みで起動速度に影響なし
- nvim-web-devicons を依存に含める（アイコン表示用）

セクション構成はデフォルトのまま（mode / branch / diff / diagnostics / filename / encoding / filetype / progress / location）。

## Alternatives

- **mini.statusline**: より軽量だがカスタマイズ性が低い
- **セクション構成のカスタマイズ**: デフォルトが十分な情報量を持つため、現時点では不要と判断

## Consequences

- デフォルト構成のため設定コードが最小限（11行）
- gitsigns導入後にdiff sourceを差し替えることでパフォーマンス向上が可能
- LSP diagnosticsは追加設定なしで自動表示される
