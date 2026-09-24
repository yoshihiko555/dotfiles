-- この設定の実体があるリポジトリ（dotfiles）のルート
local dotfiles_root = vim.fs.normalize(vim.fs.joinpath(vim.uv.fs_realpath(vim.fn.stdpath("config")), "..", ".."))

local function realpath(file)
  return vim.uv.fs_realpath(file) or file
end

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
      markdown = { "prettier" },
      css = { "prettier" },
      html = { "prettier" },
      python = { "ruff_format", "black", stop_after_first = true },
      lua = { "stylua" },
      -- dotfiles 内は treefmt の対象・除外・オプションに従い、外では各フォーマッタを使う
      yaml = { "dotfiles_treefmt", "prettier", stop_after_first = true },
      sh = { "dotfiles_treefmt", "shfmt", stop_after_first = true },
      bash = { "dotfiles_treefmt", "shfmt", stop_after_first = true },
      toml = { "dotfiles_treefmt", "taplo", stop_after_first = true },
      nix = { "dotfiles_treefmt", "nixfmt", stop_after_first = true },
    },
    formatters = {
      dotfiles_treefmt = {
        command = "dotfiles-treefmt",
        args = function(_, ctx)
          return { "--stdin", realpath(ctx.filename) }
        end,
        cwd = function()
          return dotfiles_root
        end,
        condition = function(_, ctx)
          return vim.startswith(realpath(ctx.filename), dotfiles_root .. "/")
        end,
      },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_fallback = true,
    },
  },
}
