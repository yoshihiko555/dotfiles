return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      desc = "ファイルを整形",
    },
  },
  opts = {
    formatters_by_ft = {
      go = { "goimports", "gofmt" },
      -- prettierd は使わない（ローカル版が無いと同梱の prettier を使い、版が揃わない）
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      python = { "ruff_format", "black", stop_after_first = true },
      lua = { "stylua" },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = true,
    },
  },
}
