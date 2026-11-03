# ADR-20260302-0002: nvim-treesitter mainブランチの採用

- ステータス: 採用
- 決定日: 2026-03-02
- フェーズ: 1

## 背景

シンタックスハイライトを正規表現ベースからAST（構文木）ベースに強化するため、nvim-treesitterを導入する。
nvim-treesitterはmainブランチで全面書き直しが行われ、旧masterブランチとはAPIが互換性を持たない。

## 決定

**nvim-treesitter の mainブランチ** を採用する。

理由:
- Neovim 0.11.5を使用しており、mainブランチの最低要件（0.11+）を満たしている
- masterブランチは凍結済みで今後更新されない
- mainブランチはNeovim組み込みの `vim.treesitter` APIを直接使用する設計で、将来性がある
- コンパニオンプラグイン（textobjects, context）はPhase 2以降で段階的に追加する

## 選択肢

- **masterブランチ（旧API）**: 設定が簡潔だが凍結済み。長期運用に不向き
- **treesitter未導入**: Neovim組み込みの正規表現ハイライトのみ。色分けの精度が低い

## 影響

- `require('nvim-treesitter.configs').setup()` ではなく `require('nvim-treesitter').setup()` + FileType autocmdでの設定が必要
- Cコンパイラが必要（パーサーのローカルコンパイル）
- 今後のNeovimアップデートに追従しやすい
