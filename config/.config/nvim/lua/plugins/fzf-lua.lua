return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = { "FzfLua" },
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "ファイルを検索" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "文字列を検索" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "バッファを検索" },
    { "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "ヘルプを検索" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "最近のファイルを検索" },
    { "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "診断を検索" },
    { "<leader>ls", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "ファイル内のシンボルを検索" },
    { "<leader>lS", "<cmd>FzfLua lsp_workspace_symbols<cr>", desc = "全体のシンボルを検索" },
    { "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "コミットを検索" },
    { "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "変更ファイルを表示" },
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
