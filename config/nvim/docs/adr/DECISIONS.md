# Neovim Plugin Decisions

プラグイン導入・運用に関する意思決定ログ。

| ID | タイトル | Status | Date | 判断軸 | カテゴリ |
|----|---------|--------|------|--------|---------|
| ADR-20260302-001 | カラースキームの選定 | accepted | 2026-03-02 | WezTerm統一 / プラグイン対応数 / エコシステム相性 | UI |
| ADR-20260302-002 | nvim-treesitter mainブランチの採用 | accepted | 2026-03-02 | 将来性 / Neovim 0.11対応 / メンテナンス状況 | Syntax |
| ADR-20260302-003 | lualine.nvimの最小構成での導入 | accepted | 2026-03-02 | デフォルト品質 / 起動速度 / 拡張性 | UI |
| ADR-20260302-004 | ファジーファインダーにfzf-luaを採用 | accepted | 2026-03-02 | 検索速度 / 依存ゼロ / fzf既存 | Navigation |
| ADR-20260302-005 | which-key.nvimの導入 | accepted | 2026-03-02 | 学習補助 / キーマップ整理基盤 | UX |
| ADR-20260302-006 | ファイルエクスプローラーにneo-tree.nvimを採用 | accepted | 2026-03-02 | tokyonight統一 / Git連携内蔵 / VSCode親和性 | Navigation |
| ADR-20260303-007 | バッファ内Markdownレンダリングにrender-markdown.nvimを採用 | accepted | 2026-03-03 | tokyonightネイティブ / LazyVim公式 / Anti-conceal | Markdown |
| ADR-20260303-008 | Mermaid対応ブラウザプレビューにselimacerbas/markdown-preview.nvimを採用 | accepted | 2026-03-03 | npm不要 / Mermaid自動SVG / WezTerm互換 | Markdown |
| ADR-20260313-009 | Gitガターサインにgitsigns.nvimを採用 | accepted | 2026-03-13 | 全部入り / 依存ゼロ / デファクト標準 | Git |
| ADR-20260313-010 | Diff Viewerにcodediff.nvimを採用、lazygitとの役割分担 | accepted | 2026-03-13 | 文字レベルdiff / 活発メンテ / lazygit併用 | Git |
| ADR-20260915-011 | 画像確認にパスコピーとAlfredを使い、Snacksの画像表示を休止 | accepted | 2026-09-15 | 残像・位置ずれ / 操作の快適さ / 端末構成維持 | UX |
| ADR-20260920-012 | 共通 DAP 基盤と Go のデバッグ構成を分離して導入する | accepted | 2026-09-20 | 共通とプロジェクトの分離 / Nix 管理 / Go から段階導入 | Debug |
| ADR-20260924-013 | バッファとタブの一覧を lualine の tabline で表示し、タブを作業画面として扱う | accepted | 2026-09-24 | プラグイン追加なし / 役割の区別 / 打鍵数 | Navigation |
