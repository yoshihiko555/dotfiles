-- smart-splits.nvim: Neovim ↔ tmux シームレスペイン移動/リサイズ
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    require("smart-splits").setup({
      -- tmux をマルチプレクサとして使用
      default_mux = "tmux",
    })

    -- Alt+h/j/k/l: ペイン移動（tmux の smart-splits.conf と連携）
    vim.keymap.set("n", "<A-h>", require("smart-splits").move_cursor_left, { desc = "Move to left pane" })
    vim.keymap.set("n", "<A-j>", require("smart-splits").move_cursor_down, { desc = "Move to below pane" })
    vim.keymap.set("n", "<A-k>", require("smart-splits").move_cursor_up, { desc = "Move to above pane" })
    vim.keymap.set("n", "<A-l>", require("smart-splits").move_cursor_right, { desc = "Move to right pane" })

    -- Alt+Shift+H/J/K/L: ペインリサイズ（tmux の smart-splits.conf と連携）
    vim.keymap.set("n", "<A-S-h>", require("smart-splits").resize_left, { desc = "Resize left" })
    vim.keymap.set("n", "<A-S-j>", require("smart-splits").resize_down, { desc = "Resize down" })
    vim.keymap.set("n", "<A-S-k>", require("smart-splits").resize_up, { desc = "Resize up" })
    vim.keymap.set("n", "<A-S-l>", require("smart-splits").resize_right, { desc = "Resize right" })
  end,
}
