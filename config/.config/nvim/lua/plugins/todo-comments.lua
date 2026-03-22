return {
  "folke/todo-comments.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
    { "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "Search TODOs" },
  },
  opts = {
    search = {
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--hidden",
        "--glob=!.git",
      },
    },
  },
}
