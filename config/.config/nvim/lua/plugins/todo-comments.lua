return {
  "folke/todo-comments.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "]t", function() require("todo-comments").jump_next() end, desc = "次のTODOへ" },
    { "[t", function() require("todo-comments").jump_prev() end, desc = "前のTODOへ" },
    { "<leader>st", "<cmd>TodoFzfLua<cr>", desc = "TODOを検索" },
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
