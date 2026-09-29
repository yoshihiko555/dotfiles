return {
  {
    "rcarriga/nvim-dap-ui",
    opts = { adapter_plugins = { python = "nvim-dap-python", debugpy = "nvim-dap-python" } },
  },
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    -- Python の FileType 時に共通操作と UI を読み込み、その後 Python 構成を登録する。
    dependencies = { "rcarriga/nvim-dap-ui" },
    config = function()
      -- debugpy は Nix の debugpy-adapter を使う。実行する Python はプロジェクトの venv。
      require("dap-python").setup("debugpy-adapter")
    end,
  },
}
