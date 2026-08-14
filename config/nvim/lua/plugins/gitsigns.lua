return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "┃" },
      change       = { text = "┃" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
      untracked    = { text = "┆" },
    },
    signs_staged_enable = true,
    current_line_blame = false,
    current_line_blame_opts = {
      delay = 500,
    },
    on_attach = function(bufnr)
      local gs = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, { desc = "次の変更箇所へ" })

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, { desc = "前の変更箇所へ" })

      -- Actions
      map("n", "<leader>hs", gs.stage_hunk, { desc = "変更箇所をステージ" })
      map("n", "<leader>hr", gs.reset_hunk, { desc = "変更箇所を戻す" })

      map("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "選択範囲をステージ" })

      map("v", "<leader>hr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "選択範囲を戻す" })

      map("n", "<leader>hS", gs.stage_buffer, { desc = "ファイル全体をステージ" })
      map("n", "<leader>hR", gs.reset_buffer, { desc = "ファイル全体を戻す" })
      map("n", "<leader>hp", gs.preview_hunk, { desc = "変更箇所をプレビュー" })
      map("n", "<leader>hi", gs.preview_hunk_inline, { desc = "変更箇所を行内表示" })

      map("n", "<leader>hb", function()
        gs.blame_line({ full = true })
      end, { desc = "行の変更者を表示" })

      map("n", "<leader>hd", gs.diffthis, { desc = "差分を表示" })

      -- Toggles
      map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "行の変更者を切替" })
      map("n", "<leader>tw", gs.toggle_word_diff, { desc = "単語差分を切替" })

      -- Text object
      map({ "o", "x" }, "ih", gs.select_hunk, { desc = "変更箇所を選択" })
    end,
  },
}
