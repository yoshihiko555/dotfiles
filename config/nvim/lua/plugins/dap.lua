return {
  "rcarriga/nvim-dap-ui",
  -- 共通キー、または dap-go の依存として、最初の実行前に UI も初期化する。
  dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  keys = {
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "ブレークポイントを切替",
    },
    {
      "<leader>dB",
      function()
        vim.ui.input({ prompt = "ブレークポイントの条件: " }, function(condition)
          if condition and condition ~= "" then
            require("dap").set_breakpoint(condition)
          end
        end)
      end,
      desc = "条件付きブレークポイント",
    },
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "デバッグ開始・続行",
    },
    {
      "<leader>do",
      function()
        require("dap").step_over()
      end,
      desc = "ステップオーバー",
    },
    {
      "<leader>di",
      function()
        require("dap").step_into()
      end,
      desc = "ステップイン",
    },
    {
      "<leader>dO",
      function()
        require("dap").step_out()
      end,
      desc = "ステップアウト",
    },
    {
      "<leader>dq",
      function()
        require("dap").terminate()
        -- 起動・接続失敗で終了イベントが届かない場合も閉じられる。
        require("dapui").close()
      end,
      desc = "デバッグ終了",
    },
    {
      "<leader>du",
      function()
        require("dapui").toggle()
      end,
      desc = "デバッグUIを切替",
    },
    {
      "<leader>de",
      function()
        require("dapui").eval()
      end,
      mode = { "n", "x" },
      desc = "式を評価",
    },
    {
      "<leader>dr",
      function()
        require("dap").repl.toggle()
      end,
      desc = "デバッグREPLを切替",
    },

    -- VSCode 互換。既存の <leader>d 系はそのまま残す。
    {
      "<F5>",
      function()
        require("dap").continue()
      end,
      desc = "デバッグ開始・続行",
    },
    {
      "<F9>",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "ブレークポイントを切替",
    },
    {
      "<F10>",
      function()
        require("dap").step_over()
      end,
      desc = "ステップオーバー",
    },
    {
      "<F11>",
      function()
        require("dap").step_into()
      end,
      desc = "ステップイン",
    },
    -- Shift+F11 は tmux 経由で <F23> に変換され届かないため、F12 を使う。
    {
      "<F12>",
      function()
        require("dap").step_out()
      end,
      desc = "ステップアウト",
    },
  },
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup()

    -- nvim-dap-go は Go の FileType で読み込むため、Go 以外のバッファで launch.json の
    -- Go 構成を選ぶとアダプターが無い。最初の実行時に読み込み、dap-go.lua が登録した
    -- 本来のアダプターへ渡す。dap-go は dap-ui に依存するので、この仮関数が先に登録される。
    local function load_go_adapter(callback, config)
      require("lazy").load({ plugins = { "nvim-dap-go" } })
      local adapter = dap.adapters.go
      if type(adapter) ~= "function" or adapter == load_go_adapter then
        vim.notify(
          "nvim-dap-go を読み込めませんでした。:Lazy で状態を確認してください。",
          vim.log.levels.ERROR
        )
        return
      end
      adapter(callback, config)
    end
    dap.adapters.go = dap.adapters.go or load_go_adapter

    dap.listeners.after.event_initialized["dotfiles-dapui"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dotfiles-dapui"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dotfiles-dapui"] = function()
      dapui.close()
    end
  end,
}
