return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  version = false,
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- パーサーのインストール（インストール済みならスキップ）
    require("nvim-treesitter").install({
      -- 対象言語
      "go", "gomod", "gosum",
      "typescript", "tsx", "javascript", "jsdoc",
      "python",
      "lua", "luadoc",
      -- 設定ファイル系
      "json", "jsonc", "yaml", "toml",
      "markdown", "markdown_inline",
      "html", "css",
      "bash",
      -- Neovim設定用
      "vim", "vimdoc", "query",
      -- その他
      "regex", "diff", "xml",
      "c", -- treesitter自体が依存
    })

    -- ハイライト & インデントを有効化
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter-features", { clear = true }),
      pattern = "*",
      callback = function(ev)
        local ok = pcall(vim.treesitter.start, ev.buf)
        if not ok then return end
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
