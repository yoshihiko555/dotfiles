return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      go = { "golangcilint" },
      python = { "ruff" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      zsh = { "zsh" },
    }

    -- nvim-lint は cwd で `go env GOMOD` が見つからないとファイル単体を golangci-lint に渡す。
    -- go.work だけがあるモノレポの直下で開くとこれに当たり、同じパッケージの別ファイルの定義を
    -- undefined と誤検出するため、常にパッケージのディレクトリを渡す。
    local golangcilint = lint.linters.golangcilint
    if type(golangcilint) == "table" and type(golangcilint.args) == "table" then
      golangcilint.args[#golangcilint.args] = function()
        return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h")
      end
    end

    -- eslint はプロジェクトにローカル版と設定があるときだけ使う（ADR-20260924-0004）
    local eslint_fts = {
      javascript = true,
      javascriptreact = true,
      typescript = true,
      typescriptreact = true,
    }
    local eslint_configs = {
      "eslint.config.js",
      "eslint.config.mjs",
      "eslint.config.cjs",
      "eslint.config.ts",
      "eslint.config.mts",
      "eslint.config.cts",
      ".eslintrc.js",
      ".eslintrc.cjs",
      ".eslintrc.json",
      ".eslintrc.yml",
      ".eslintrc.yaml",
      ".eslintrc",
    }

    local function find_local_eslint(bufnr)
      local file = vim.api.nvim_buf_get_name(bufnr)
      if file == "" then
        return nil
      end
      local root = vim.fs.root(file, eslint_configs)
      if not root then
        return nil
      end
      for dir in vim.fs.parents(file) do
        local bin = vim.fs.joinpath(dir, "node_modules", ".bin", "eslint")
        if vim.uv.fs_stat(bin) then
          return root, bin
        end
      end
    end

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("user-lint", { clear = true }),
      callback = function(args)
        lint.try_lint()

        if eslint_fts[vim.bo[args.buf].filetype] then
          local root, bin = find_local_eslint(args.buf)
          if root then
            lint.try_lint("eslint", {
              cwd = root,
              wrap_linter = function(linter)
                linter.cmd = bin
                return linter
              end,
            })
          end
        end

        local file = vim.api.nvim_buf_get_name(args.buf)
        if vim.bo[args.buf].filetype == "yaml" and file:find("/%.github/workflows/") then
          lint.try_lint("actionlint")
        end
      end,
    })
  end,
}
