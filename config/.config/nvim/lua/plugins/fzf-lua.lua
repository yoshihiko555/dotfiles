return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Find by Grep" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Find Buffers" },
    { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Find Help" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Find Recent" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Find Diagnostics" },
    { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Find Symbols" },
    { "<leader>fw", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "Find Workspace Symbols" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git Commits" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git Status" },
  },
  opts = {
    "default-title",
    winopts = {
      height = 0.85,
      width = 0.80,
      preview = {
        layout = "flex",
      },
    },
  },
}
