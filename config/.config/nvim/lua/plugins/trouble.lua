return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
    { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
    { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP references/definitions" },
  },
  opts = {},
}
