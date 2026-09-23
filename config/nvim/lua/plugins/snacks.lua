return {
  "folke/snacks.nvim",
  -- herdr 配下のみ有効（tmux では残像・位置ずれが出る）
  cond = vim.env.HERDR_ENV ~= nil and vim.env.HERDR_ENV ~= "",
  lazy = false,
  priority = 1000,
  opts = {
    image = {
      enabled = true,
      -- inline 非対応の端末では自動で float になる
      doc = { enabled = true, inline = true, float = true },
      math = { enabled = false },
    },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)

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

    -- 緊急用（他ペインの画像も消える）
    vim.api.nvim_create_user_command("ImageClear", function()
      snacks.image.doc.hover_close()
      snacks.image.terminal.request({ a = "d", d = "a" })
      snacks.image.placement.clean()
      vim.cmd("redraw!")
    end, { desc = "端末に残った画像を消去" })
  end,
}
