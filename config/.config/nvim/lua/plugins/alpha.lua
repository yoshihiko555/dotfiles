return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  enabled = function()
    return vim.fn.argc() == 0
  end,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local ok_alpha, alpha = pcall(require, "alpha")
    local ok_dashboard, dashboard = pcall(require, "alpha.themes.dashboard")
    if not (ok_alpha and ok_dashboard) then
      return
    end

    vim.api.nvim_set_hl(0, "AlphaHeaderEdgerunners", { fg = "#00F0FF", bold = true })
    vim.api.nvim_set_hl(0, "AlphaButtonsEdgerunners", { fg = "#FFD400", bold = true })
    vim.api.nvim_set_hl(0, "AlphaFooterEdgerunners", { fg = "#FF4D9D", italic = true })

    dashboard.section.header.val = {
      " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
      " ",
      "        N E O V I M   //   N I G H T   C I T Y   M O D E",
    }

    dashboard.section.buttons.val = {
      dashboard.button("e", "  NEW JOB", "<cmd>ene | startinsert<cr>"),
      dashboard.button("f", "󰱼  FIND CONTRACT", "<cmd>FzfLua files<cr>"),
      dashboard.button("r", "  LAST RUNS", "<cmd>FzfLua oldfiles<cr>"),
      dashboard.button("g", "󱎸  BRAINDANCE SEARCH", "<cmd>FzfLua live_grep<cr>"),
      dashboard.button("x", "  OPEN WAREHOUSE", "<cmd>Neotree toggle<cr>"),
      dashboard.button("i", "  EDIT CYBERDECK", "<cmd>e $MYVIMRC<cr>"),
      dashboard.button("q", "  JACK OUT", "<cmd>qa<cr>"),
    }

    dashboard.section.footer.val = {
      "WAKE UP, DEV. WE HAVE A CONFIG TO REWRITE.",
    }

    dashboard.section.header.opts.hl = "AlphaHeaderEdgerunners"
    dashboard.section.buttons.opts.hl = "AlphaButtonsEdgerunners"
    dashboard.section.footer.opts.hl = "AlphaFooterEdgerunners"

    alpha.setup(dashboard.opts)
  end,
}
