return {
  "selimacerbas/markdown-preview.nvim",
  ft = { "markdown", "mermaid" },
  dependencies = { "selimacerbas/live-server.nvim" },
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "プレビューを開始" },
    { "<leader>mP", "<cmd>MarkdownPreviewStop<cr>", desc = "プレビューを停止" },
  },
  opts = {
    port = 8421,
    open_browser = true,
    debounce_ms = 300,
    scroll_sync = true,
    mermaid_renderer = "js",
  },
}
