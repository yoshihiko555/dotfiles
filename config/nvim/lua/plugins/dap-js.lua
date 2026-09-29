-- TypeScript / JavaScript は js-debug（Nix の vscode-js-debug）に直接つなぎ、専用プラグインは使わない。
-- js-debug はホスト未指定だと ::1 で待ち受けるため、双方に 127.0.0.1 を指定する。
local js_debug = {
  type = "server",
  host = "127.0.0.1",
  port = "${port}",
  executable = { command = "js-debug", args = { "${port}", "127.0.0.1" } },
}

-- VSCode の launch.json は pwa- なしの type も使う。js-debug へは pwa- 付きで渡す。
local function alias(pwa_type)
  return function(callback, config)
    config.type = pwa_type
    callback(js_debug)
  end
end

-- 単体の js-debug は node-terminal を起動できないため、シェル経由の pwa-node 起動に読み替える。
-- 子プロセスの Node へは js-debug が自動で接続する（Next.js の `npm run dev` など）。
local function node_terminal(callback, config)
  config.type = "pwa-node"
  config.runtimeExecutable = "sh"
  config.runtimeArgs = { "-c", config.command }
  config.command = nil
  -- VSCode と同じく、省略時はワークスペース（launch.json を読んだ作業ディレクトリ）で実行する。
  config.cwd = config.cwd or vim.fn.getcwd()
  callback(js_debug)
end

return {
  "rcarriga/nvim-dap-ui",
  opts = {
    adapters = {
      ["pwa-node"] = js_debug,
      ["pwa-chrome"] = js_debug,
      ["node-terminal"] = node_terminal,
      node = alias("pwa-node"),
      chrome = alias("pwa-chrome"),
    },
  },
}
