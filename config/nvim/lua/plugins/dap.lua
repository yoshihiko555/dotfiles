return {
  "rcarriga/nvim-dap-ui",
  -- 共通キー、または言語プラグインの依存として、最初の実行前に UI も初期化する。
  -- nvim-dap-python の rockspec が nvim-dap を起動時読み込みで追加するため、遅延を明示する。
  dependencies = { { "mfussenegger/nvim-dap", lazy = true }, "nvim-neotest/nvim-nio" },
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
  -- 言語ごとの登録は dap-<言語>.lua がここへ追加する。
  opts = {
    -- 構成の type → アダプターを登録する言語プラグイン
    adapter_plugins = {},
    -- 構成の type → アダプター（プラグインを使わない言語）
    adapters = {},
  },
  config = function(_, opts)
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup()

    for adapter_type, adapter in pairs(opts.adapters) do
      dap.adapters[adapter_type] = adapter
    end

    -- 言語プラグインは FileType で読み込むため、他のバッファで launch.json の構成を選ぶと
    -- アダプターが無い。最初の実行時に読み込み、プラグインが登録したアダプターへ渡す。
    -- 言語プラグインは dap-ui に依存するので、この仮関数が先に登録される。
    for adapter_type, plugin in pairs(opts.adapter_plugins) do
      local function load_adapter(callback, config)
        require("lazy").load({ plugins = { plugin } })
        local adapter = dap.adapters[adapter_type]
        if adapter == nil or adapter == load_adapter then
          vim.notify(
            plugin .. " を読み込めませんでした。:Lazy で状態を確認してください。",
            vim.log.levels.ERROR
          )
        elseif type(adapter) == "function" then
          adapter(callback, config)
        else
          callback(adapter)
        end
      end
      dap.adapters[adapter_type] = dap.adapters[adapter_type] or load_adapter
    end

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
