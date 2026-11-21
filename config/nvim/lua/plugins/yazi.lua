return {
  "mikavilpas/yazi.nvim",
  version = "*",
  cmd = "Yazi",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>-", "<cmd>Yazi<cr>", desc = "現在のファイルの場所を Yazi で開く" },
  },
  opts = {},
}
