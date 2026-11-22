return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "moon",
    on_highlights = function(highlights, colors)
      local blend = require("tokyonight.util").blend
      highlights.CursorLineNr = { fg = colors.bg_dark, bg = blend(colors.blue, 0.82, colors.bg), bold = true }
      highlights.CursorLineSign = { bg = colors.blue7 }
      highlights.CursorLine = { bg = blend(colors.blue, 0.15, colors.bg) }
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
