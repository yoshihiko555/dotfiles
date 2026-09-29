return {
  {
    "rcarriga/nvim-dap-ui",
    opts = { adapter_plugins = { go = "nvim-dap-go" } },
  },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    -- Go の FileType 時に共通操作と UI を読み込み、その後 Go 構成を登録する。
    dependencies = { "rcarriga/nvim-dap-ui" },
    keys = {
      {
        "<leader>dt",
        function()
          require("dap-go").debug_test()
        end,
        ft = "go",
        desc = "付近のGoテストをデバッグ",
      },
      {
        "<leader>dT",
        function()
          require("dap-go").debug_last_test()
        end,
        ft = "go",
        desc = "前回のGoテストを再実行",
      },
    },
    opts = {
      -- 成功したテストの t.Log も DAP REPL で確認する。
      tests = { verbose = true },
    },
    config = function(_, opts)
      require("dap-go").setup(opts)
      local dap = require("dap")

      -- nvim-dap-go は port 指定の構成でもローカルで `dlv dap -l <host>:<port>` を起動し、
      -- 接続先が使用中のポートなので exit 1 の通知が出る。remote attach は直接つなぐ。
      -- Delve は利用ホストの Nix で管理。通常編集では存在を要求せず、実行時に案内する。
      local delve_adapter = dap.adapters.go
      dap.adapters.go = function(callback, config)
        if config.request == "attach" and config.mode == "remote" and config.port ~= nil then
          callback({ type = "server", host = config.host or "127.0.0.1", port = config.port })
        elseif vim.fn.executable("dlv") == 0 then
          vim.notify(
            "Delve (dlv) が見つかりません。Nix の delve を適用して Neovim を再起動してください。:help dap と docs/cheatsheet/debugging.md を参照。",
            vim.log.levels.ERROR
          )
        else
          delve_adapter(callback, config)
        end
      end
    end,
  },
}
