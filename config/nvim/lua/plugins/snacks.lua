local preview_active = false

return {
  "folke/snacks.nvim",
  -- WezTerm + tmux で残像・位置ずれがあるため休止。再試用時は true に戻す。
  cond = false,
  lazy = false,
  priority = 1000,
  opts = {
    image = {
      enabled = true,
      -- WezTerm + tmux では手動フロートで試す。既存の Mermaid 表示とも分離する。
      doc = { enabled = false, inline = false, float = true },
      math = { enabled = false },
    },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)

    local function clear_preview()
      -- フロートを閉じる際の WinLeave による再入を防ぐ。
      preview_active = false
      snacks.image.doc.hover_close()
      -- WezTerm + tmux では ID 指定の削除で残像が残るため、表示中の画像を消す。
      -- ImageClear と同じ消去要求。ほかのペインの画像も消える場合がある。
      snacks.image.terminal.request({ a = "d", d = "a" })
      vim.cmd("redraw!")
    end

    -- 手動プレビューは移動時に閉じる。上流の hover 再評価だけに任せない。
    local group = vim.api.nvim_create_augroup("image-preview-close", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave", "WinLeave", "FocusLost" }, {
      group = group,
      callback = function()
        if preview_active then
          clear_preview()
        end
      end,
    })

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

    vim.api.nvim_create_user_command("ImageClear", function()
      clear_preview()
      snacks.image.placement.clean()
    end, { desc = "端末に残った画像を消去" })
  end,
  keys = {
    {
      "<leader>mi",
      function()
        preview_active = true
        require("snacks").image.hover()
      end,
      desc = "カーソル位置の画像をプレビュー",
      ft = "markdown",
    },
  },
}
