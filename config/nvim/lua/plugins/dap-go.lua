return {
  "leoluz/nvim-dap-go",
  ft = "go",
  -- Go の FileType 時に共通操作と UI を読み込み、その後 Go 構成を登録する。
  dependencies = { "rcarriga/nvim-dap-ui" },
  keys = {
    { "<leader>dt", function() require("dap-go").debug_test() end, ft = "go", desc = "付近のGoテストをデバッグ" },
    { "<leader>dT", function() require("dap-go").debug_last_test() end, ft = "go", desc = "前回のGoテストを再実行" },
  },
  opts = {
    -- 成功したテストの t.Log も DAP REPL で確認する。
    tests = { verbose = true },
  },
  config = function(_, opts)
    require("dap-go").setup(opts)

    -- Delve は利用ホストの Nix で管理。通常編集では存在を要求しない。
    -- キー以外（:DapContinue や launch.json）からの開始にも同じ案内を出す。
    local dap = require("dap")
    dap.listeners.on_config["dotfiles-delve"] = function(config)
      if config.type == "go" and vim.fn.executable("dlv") == 0 then
        vim.notify(
          "Delve (dlv) が見つかりません。Nix の delve を適用して Neovim を再起動してください。:help dap と docs/cheatsheet/debugging.md を参照。",
          vim.log.levels.ERROR
        )
        return vim.tbl_extend("force", config, { program = dap.ABORT })
      end
      return config
    end
  end,
}
