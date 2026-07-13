return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Neovim標準のLSPキーマップを解除し、<leader>l 配下へ統一
      local default_lsp_keymaps = {
        { { "n", "x" }, "gra" },
        { "n", "gri" },
        { "n", "grn" },
        { "n", "grr" },
        { "n", "grt" },
        { "n", "grx" },
        { "n", "gO" },
        { "i", "<C-s>" },
      }
      for _, keymap in ipairs(default_lsp_keymaps) do
        pcall(vim.keymap.del, keymap[1], keymap[2])
      end

      -- capabilities (cmp-nvim-lsp 統合)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
      end

      -- mason-lspconfig: ensure_installed + automatic_enable
      require("mason-lspconfig").setup({
        ensure_installed = {
          "gopls",
          "pyright",
          "ts_ls",
          "lua_ls",
        },
        automatic_enable = true,
      })

      -- サーバー固有設定を vim.lsp.config() で登録
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      vim.lsp.config("gopls", {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
          },
        },
      })

      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        init_options = {
          hostInfo = "neovim",
        },
      })

      vim.lsp.config("pyright", {
        capabilities = capabilities,
      })

      -- diagnostics 表示設定
      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        virtual_text = {
          prefix = "●",
          spacing = 2,
        },
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

      -- LSP keymaps (LspAttach で設定)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          pcall(vim.keymap.del, "n", "K", { buf = bufnr })

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
          end

          local fzf_lsp = function(picker, fallback)
            return function()
              local ok, fzf_lua = pcall(require, "fzf-lua")
              if ok then
                fzf_lua[picker]({ jump1 = false })
              else
                fallback()
              end
            end
          end

          map("n", "<leader>ld", fzf_lsp("lsp_definitions", vim.lsp.buf.definition), "定義を表示")
          map("n", "<leader>lD", fzf_lsp("lsp_declarations", vim.lsp.buf.declaration), "宣言を表示")
          map("n", "<leader>lr", fzf_lsp("lsp_references", vim.lsp.buf.references), "参照箇所を表示")
          map("n", "<leader>li", fzf_lsp("lsp_implementations", vim.lsp.buf.implementation), "実装を表示")
          map("n", "<leader>lt", fzf_lsp("lsp_typedefs", vim.lsp.buf.type_definition), "型定義を表示")
          map("n", "<leader>lh", function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, "型情報を表示")
          map("n", "<leader>lf", function()
            local ok, fzf_lua = pcall(require, "fzf-lua")
            if ok then
              fzf_lua.lsp_finder()
            else
              vim.notify("fzf-luaを読み込めません", vim.log.levels.WARN)
            end
          end, "LSP一覧を表示")
          map("n", "<leader>ln", vim.lsp.buf.rename, "名前を変更")
          map({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "修正候補を表示")
          map("n", "<leader>lc", vim.lsp.codelens.run, "コードレンズを実行")
          map("n", "<leader>lp", vim.lsp.buf.signature_help, "引数情報を表示")
          map("n", "<leader>le", vim.diagnostic.open_float, "行の診断を表示")
          map("n", "<leader>lk", vim.diagnostic.goto_prev, "前の診断へ")
          map("n", "<leader>lj", vim.diagnostic.goto_next, "次の診断へ")
        end,
      })
    end,
  },
}
