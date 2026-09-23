local buffer_jump_keys = {}
for i = 1, 9 do
  table.insert(buffer_jump_keys, {
    "<leader>" .. i,
    "<cmd>LualineBuffersJump! " .. i .. "<cr>",
    desc = i .. " 番のバッファへ",
  })
end

return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = buffer_jump_keys,
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
    },
    -- 上部に開いているバッファ（左）とタブ（右、2 つ以上のときだけ）を並べる
    tabline = {
      lualine_a = { { "buffers", mode = 2 } },
      lualine_z = {
        {
          "tabs",
          -- バッファと区別するため、ファイル名は出さず番号と :LualineRenameTab の名前だけにする
          mode = 1,
          fmt = function(name, tab)
            local ok, custom = pcall(vim.api.nvim_tabpage_get_var, tab.tabId, "tabname")
            local label = (ok and custom ~= "") and (tab.tabnr .. " " .. name) or tostring(tab.tabnr)
            return tab.tabnr == 1 and ("󰓩 " .. label) or label
          end,
          tabs_color = { active = "lualine_a_terminal", inactive = "lualine_b_terminal" },
          cond = function() return vim.fn.tabpagenr("$") > 1 end,
        },
      },
    },
  },
}
