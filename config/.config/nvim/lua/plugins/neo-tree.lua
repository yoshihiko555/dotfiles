return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = { "Neotree" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },
    { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Explorer (reveal)" },
  },
  init = function()
    vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
      pattern = "*",
      callback = function()
        local manager = package.loaded["neo-tree.sources.manager"]
        if not manager then
          return
        end

        local state = manager.get_state("filesystem")
        local renderer = require("neo-tree.ui.renderer")
        if state and state.tree and renderer.window_exists(state) then
          require("neo-tree.sources.filesystem.commands").refresh(state)
        end
      end,
    })
  end,
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    git_status = {
      window = {
        position = "float",
      },
    },
    window = {
      width = 35,
      mappings = {
        ["<space>"] = "none",
      },
    },
  },
}
