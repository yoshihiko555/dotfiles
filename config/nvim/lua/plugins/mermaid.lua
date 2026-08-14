-- mermaid ブロックをバッファ内に Unicode art で展開する
--
-- 画像インライン表示（image.nvim 系）を採らない理由:
--   tmux が Kitty graphics protocol を未サポートで、allow-passthrough による
--   回避は大きい図の二重描画やペイン分割時の画像漏れが既知。常時 tmux 運用では
--   実用にならないため、端末非依存な Unicode art を主軸にする。
-- 複雑な図の精査は markdown-preview.nvim（<leader>mp）のブラウザ表示に逃がす。
return {
  "searleser97/mermaid-nvim",
  ft = { "markdown" },
  keys = {
    { "<leader>mm", "<cmd>MermaidToggleAll<cr>", desc = "mermaid表示を一括切替", ft = "markdown" },
    { "<leader>mf", "<cmd>MermaidFloat<cr>", desc = "mermaidを拡大表示", ft = "markdown" },
  },
  init = function()
    local group = vim.api.nvim_create_augroup("mermaid-markdown", { clear = true })

    -- mermaid-nvim は図の virtual lines を Comment 決め打ちで描く
    -- （renderer.lua:118、設定で変更できない）。Moon の Comment #636da6 は背景 #222436 に対して
    -- コントラスト比 3.11:1 しかなく、図が背景に溶ける。
    --
    -- 文字を blue に上げたうえで、bg_dark の背景を敷いて 7.01:1 にする。
    -- 背景を敷くのは数値のためだけではない。ghostty 側で背景画像（opacity 0.2）と blur を
    -- 使っており、それが図の下に透けて実効コントラストを下げているのを遮断する狙いがある。
    -- termaid の出力は各行が最大幅までスペースで揃っているので、敷いても矩形になる
    -- （前後の空行だけはラッパー側でトリムしている）。
    --
    -- Comment 自体は変えない（他ファイルタイプのコメントまで変えてしまう）。
    -- 適用は下の winhighlight で markdown ウィンドウに限定する。
    local function set_diagram_hl()
      -- パレット API 経由で取るので style（moon/storm/night）を変えても追従する
      local ok, colors = pcall(function()
        return require("tokyonight.colors").setup()
      end)
      if ok and colors.blue then
        vim.api.nvim_set_hl(0, "MermaidDiagram", { fg = colors.blue, bg = colors.bg_dark })
      else
        -- tokyonight 以外に乗り換えたときは本文と同じ明るさに倒す（溶けるよりは濃い方が安全）
        vim.api.nvim_set_hl(0, "MermaidDiagram", { link = "Normal" })
      end
    end

    set_diagram_hl()
    vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_diagram_hl })

    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
      group = group,
      callback = function(ev)
        if vim.bo[ev.buf].filetype ~= "markdown" then
          -- markdown 用ウィンドウに別ファイルを開いたときに設定が残らないようにする
          if vim.wo.winhighlight == "Comment:MermaidDiagram" then
            vim.wo.winhighlight = ""
          end
          return
        end
        -- 背の高い図は virtual lines が数十行になるため、行内スクロールを有効にする
        vim.opt_local.smoothscroll = true
        vim.wo.winhighlight = "Comment:MermaidDiagram"
      end,
    })
  end,
  opts = {
    -- termaid を直接呼ばず、bin/mermaid-render で前処理してから渡す。
    -- termaid は <br/> と subgraph ID["ラベル"] を解釈できず、そのままだと
    -- ラベルが途中で切れて subgraph の構造ごと崩れる（詳細はラッパー内のコメント）。
    -- termaid 本体は mise 管理（config/mise/config.toml の "pipx:termaid"）。
    cmd = { vim.fn.stdpath("config") .. "/bin/mermaid-render" },
    enabled = true,
    -- 拡大表示は全画面のほうが横に長い図を追いやすい
    preview_mode = "tab",
    on_error = "virtual_text",
    inline_render_delay_ms = 300,
  },
}
