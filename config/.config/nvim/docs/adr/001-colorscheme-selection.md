# ADR-001: カラースキームの選定

- **Phase**: 1
- **Status**: accepted
- **Date**: 2026-03-02

## Context

Neovim移行の基盤として、カラースキームを選定する必要がある。
WezTermで既にtokyonight moonを使用しており、ターミナルとエディタの見た目を統一したい。

## Decision

**tokyonight.nvim** の `moon` バリアントを採用する。

理由:
- WezTermのテーマ（tokyonight moon）と統一できる
- プラグイン対応数が80+で最多
- folke製（lazy.nvim, which-key, trouble等の作者）でエコシステムとの相性が保証される
- Lualine組み込みテーマあり

## Alternatives

- **catppuccin/nvim**: エコシステム最大・メンテナンス最活発だが、WezTermのテーマと合わせる利点がtokyonightにある
- **kanagawa.nvim**: デザインは美しいが、メンテナンスがやや停滞（issue 90件）で長期運用に不安

## Consequences

- WezTermとNeovimで統一された見た目になる
- folke製プラグイン（which-key, trouble等）を今後導入する際にテーマの不整合が起きにくい
- 40+のターミナル向けextrasがあるため、今後ツールを増やしても統一しやすい
