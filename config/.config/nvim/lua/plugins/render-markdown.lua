return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
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
    },
    checkbox = {
      enabled = true,
    },
    bullet = {
      enabled = true,
    },
  },
}
