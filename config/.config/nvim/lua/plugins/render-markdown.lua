return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Markdown表示を切替" },
  },
  opts = {
    heading = {
      enabled = true,
      sign = false,
    },
    code = {
      enabled = true,
      sign = false,
      width = "block",
      right_pad = 1,
      -- mermaid は mermaid-nvim が Unicode art に描き替えるため、
      -- ここでコードブロック装飾をすると二重描画になる
      disable = { "mermaid" },
    },
    checkbox = {
      enabled = true,
    },
    bullet = {
      enabled = true,
    },
  },
}
