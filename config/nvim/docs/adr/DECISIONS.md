# 意思決定ログ (DECISIONS)

Neovim のプラグイン導入・運用に関する意思決定の一覧。詳細は各 ADR ファイルを参照。
領域をまたぐ決定は [docs/adr/](../../../../docs/adr/DECISIONS.md) に置く。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20260302-0001](ADR-20260302-0001-colorscheme-tokyonight.md) | カラースキームの選定 | 採用 | 2026-03-02 | WezTerm統一 / プラグイン対応数 / エコシステム相性 | UI |
| [ADR-20260302-0002](ADR-20260302-0002-treesitter-main-branch.md) | nvim-treesitter mainブランチの採用 | 採用 | 2026-03-02 | 将来性 / Neovim 0.11対応 / メンテナンス状況 | Syntax |
| [ADR-20260302-0003](ADR-20260302-0003-lualine-minimal.md) | lualine.nvimの最小構成での導入 | 採用 | 2026-03-02 | デフォルト品質 / 起動速度 / 拡張性 | UI |
| [ADR-20260302-0004](ADR-20260302-0004-fzf-lua.md) | ファジーファインダーにfzf-luaを採用 | 採用 | 2026-03-02 | 検索速度 / 依存ゼロ / fzf既存 | Navigation |
| [ADR-20260302-0005](ADR-20260302-0005-which-key.md) | which-key.nvimの導入 | 採用 | 2026-03-02 | 学習補助 / キーマップ整理基盤 | UX |
| [ADR-20260302-0006](ADR-20260302-0006-neo-tree.md) | ファイルエクスプローラーにneo-tree.nvimを採用 | 採用 | 2026-03-02 | tokyonight統一 / Git連携内蔵 / VSCode親和性 | Navigation |
| [ADR-20260303-0007](ADR-20260303-0007-render-markdown.md) | バッファ内Markdownレンダリングにrender-markdown.nvimを採用 | 採用 | 2026-03-03 | tokyonightネイティブ / LazyVim公式 / Anti-conceal | Markdown |
| [ADR-20260303-0008](ADR-20260303-0008-markdown-preview-mermaid.md) | Mermaid対応ブラウザプレビューにselimacerbas/markdown-preview.nvimを採用 | 採用 | 2026-03-03 | npm不要 / Mermaid自動SVG / WezTerm互換 | Markdown |
| [ADR-20260313-0009](ADR-20260313-0009-gitsigns.md) | Git ガターサインに gitsigns.nvim を採用 | 採用 | 2026-03-13 | 全部入り / 依存ゼロ / デファクト標準 | Git |
| [ADR-20260313-0010](ADR-20260313-0010-codediff-and-lazygit.md) | Diff Viewer に codediff.nvim を採用、lazygit との役割分担 | 採用 | 2026-03-13 | 文字レベルdiff / 活発メンテ / lazygit併用 | Git |
| [ADR-20260915-0011](ADR-20260915-0011-image-preview-via-alfred.md) | 画像確認にパスコピーと Alfred を使い、Snacks の画像表示を休止 | 採用 | 2026-09-15 | 残像・位置ずれ / 操作の快適さ / 端末構成維持 | UX |
| [ADR-20260920-0012](ADR-20260920-0012-dap-base-and-go.md) | 共通 DAP 基盤と Go のデバッグ構成を分離して導入する | 採用 | 2026-09-20 | 共通とプロジェクトの分離 / Nix 管理 / Go から段階導入 | Debug |
| [ADR-20260924-0013](ADR-20260924-0013-lualine-tabline.md) | バッファとタブの一覧を lualine の tabline で表示し、タブを作業画面として扱う | 採用 | 2026-09-24 | プラグイン追加なし / 役割の区別 / 打鍵数 | Navigation |
| [ADR-20260929-0014](ADR-20260929-0014-dap-multilang.md) | 言語ごとの DAP アダプター登録を共通化し、Python と TypeScript / Next.js のデバッグを追加する | 採用 | 2026-09-29 | 言語ファイルへの閉じ込め / 遅延読み込みの維持 / Nix 管理 | Debug |
