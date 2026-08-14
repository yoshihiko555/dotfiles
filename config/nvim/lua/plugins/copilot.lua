return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<C-y>",
          dismiss = "<C-e>",
          next = false,
          prev = false,
          accept_word = false,
          accept_line = false,
        },
      },
      panel = {
        enabled = false,
      },
      filetypes = {
        markdown = true,
        yaml = true,
        ["."] = false,
      },
    })
  end,
}
