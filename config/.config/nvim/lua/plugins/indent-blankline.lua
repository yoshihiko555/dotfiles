return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    -- ガイド線の色を tokyonight moon の背景に合わせて視認できる程度に
    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#545c7e" })
    vim.api.nvim_set_hl(0, "IblScope", { fg = "#65bcff" })

    require("ibl").setup({
      indent = {
        char = "│",
      },
      scope = {
        show_start = false,
        show_end = false,
      },
    })
  end,
}
