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
    vim.keymap.set("n", "<A-h>", require("smart-splits").move_cursor_left, { desc = "左のペインへ" })
    vim.keymap.set("n", "<A-j>", require("smart-splits").move_cursor_down, { desc = "下のペインへ" })
    vim.keymap.set("n", "<A-k>", require("smart-splits").move_cursor_up, { desc = "上のペインへ" })
    vim.keymap.set("n", "<A-l>", require("smart-splits").move_cursor_right, { desc = "右のペインへ" })

    -- Alt+Shift+H/J/K/L: ペインリサイズ（tmux の smart-splits.conf と連携）
    vim.keymap.set("n", "<A-S-h>", require("smart-splits").resize_left, { desc = "左へ広げる" })
    vim.keymap.set("n", "<A-S-j>", require("smart-splits").resize_down, { desc = "下へ広げる" })
    vim.keymap.set("n", "<A-S-k>", require("smart-splits").resize_up, { desc = "上へ広げる" })
    vim.keymap.set("n", "<A-S-l>", require("smart-splits").resize_right, { desc = "右へ広げる" })
  end,
}
