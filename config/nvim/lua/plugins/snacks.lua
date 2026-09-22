return {
  "folke/snacks.nvim",
  -- WezTerm + tmux では残像・位置ずれがあるため無効。herdr のときだけ有効にする。
  -- herdr は Kitty graphics を素通しせず自前で処理しており、2026-09-23 の実測で
  -- 分割・タブ切替・zoom・ID 指定削除のいずれでも崩れ/残像が出ないことを確認した。
  -- 判定は WezTerm 層 (config/wezterm/wezterm.lua) と同じ ~/.config/use-herdr の有無。
  cond = vim.fn.filereadable(vim.fn.expand("~/.config/use-herdr")) == 1,
  lazy = false,
  priority = 1000,
  opts = {
    image = {
      enabled = true,
      -- markdown の画像はカーソルが乗ったら自動でフロート表示する。
      -- inline（本文に画像を埋め込む）は unicode placeholder 対応端末でのみ有効で、
      -- snacks の端末表では wezterm は placeholders = false。よって WezTerm では
      -- 自動的に float へフォールバックする（Ghostty / kitty に移れば inline が効く）。
      doc = { enabled = true, inline = true, float = true },
      math = { enabled = false },
    },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)

    -- markdown のプレビューは doc.enabled = true による自動 hover に任せる。
    -- 手動プレビュー (<leader>mi) と、その後始末の全画像削除は 2026-09-23 に撤去した。
    -- tmux の残像対策だったが、herdr では ID 指定削除が効くため不要で、
    -- 全消しは他ペインの画像まで巻き込むため自動 hover とは併用できない。
    local group = vim.api.nvim_create_augroup("image-preview-close", { clear = true })

    -- 画像ファイルはカーソル移動では閉じず、表示先を離れたときに消す。
    local hidden_images = {}
    local focused = true
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost", "ExitPre" }, {
      group = group,
      callback = function(ev)
        if ev.event == "FocusLost" then focused = false end
        local buf = ev.buf
        if vim.bo[buf].filetype ~= "image" or hidden_images[buf] then return end
        hidden_images[buf] = true
        -- 配置を破棄して、上流の遅延更新による再描画も止める。
        snacks.image.placement.clean(buf)
        snacks.image.terminal.request({ a = "d", d = "a" })
        vim.cmd("redraw!")
      end,
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FocusGained" }, {
      group = group,
      callback = function(ev)
        if ev.event == "FocusGained" then focused = true end
        local buf = ev.buf
        vim.schedule(function()
          if not focused or not hidden_images[buf] then return end
          if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf then return end
          if vim.bo[buf].filetype ~= "image" then return end
          hidden_images[buf] = nil
          snacks.image.buf.attach(buf)
        end)
      end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
      group = group,
      callback = function(ev) hidden_images[ev.buf] = nil end,
    })

    -- 緊急用。全消しなので、ほかのペインの画像も消える。
    vim.api.nvim_create_user_command("ImageClear", function()
      snacks.image.doc.hover_close()
      snacks.image.terminal.request({ a = "d", d = "a" })
      snacks.image.placement.clean()
      vim.cmd("redraw!")
    end, { desc = "端末に残った画像を消去" })
  end,
}
