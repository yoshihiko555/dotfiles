return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = {
      presets = {
        g = false,
      },
    },
    spec = {
      { "<leader>c", group = "コード" },
      { "<leader>m", group = "Markdown" },
      { "<leader>f", group = "検索" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "LSP" },
      { "<leader>b", group = "バッファ" },
      { "<leader>h", group = "Git差分" },
      { "<leader>t", group = "表示切替" },
      { "<leader>x", group = "診断・リスト" },
      { "<leader>w", proxy = "<c-w>", group = "ウィンドウ" },
    },
  },
  keys = {
    {
      "<leader>?",
      function() require("which-key").show({ global = false }) end,
      desc = "現在のキーマップを表示",
    },
  },
}
