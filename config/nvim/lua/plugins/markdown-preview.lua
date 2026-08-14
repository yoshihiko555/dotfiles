return {
  "selimacerbas/markdown-preview.nvim",
  ft = { "markdown", "mermaid" },
  dependencies = { "selimacerbas/live-server.nvim" },
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "プレビューを開始" },
    { "<leader>mP", "<cmd>MarkdownPreviewStop<cr>", desc = "プレビューを停止" },
  },
  opts = {
    -- multi: nvimインスタンスごとに専用サーバー＆専用タブ（並列プレビュー向け）
    -- takeover だと固定ポート8421の共有1タブになり、2台目以降は無反応になる
    instance_mode = "multi",
    -- 0 = OSが空きポートを払い出す（ephemeral 49152-65535）。
    -- 「0番から昇順」ではなく空きを保証する割当なので、3000番台等と衝突しない。
    -- 固定ポートは EADDRINUSE 時に自動リトライされず失敗するため避ける。
    port = 0,
    open_browser = true,
    debounce_ms = 300,
    scroll_sync = true,
    mermaid_renderer = "js",
  },
}
