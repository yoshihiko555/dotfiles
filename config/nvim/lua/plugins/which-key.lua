-- lualine.lua で定義した <leader>1〜9 は 1 行にまとめて表示する
local buffer_jump_spec = { { "<leader>1", desc = "番号のバッファへ" } }
for i = 2, 9 do
  table.insert(buffer_jump_spec, { "<leader>" .. i, hidden = true })
end

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = {
      presets = {
        g = false,
      },
    },
    replace = {
      key = {
        -- 既定の整形（上書きされるため残す）
        function(key)
          return require("which-key.view").format(key)
        end,
        -- <leader> の一覧でだけ 1 を 1-9 と表示する（内部 API のため失敗時は素通し）
        function(key)
          if key ~= "1" then
            return key
          end
          local ok, prefix = pcall(function()
            return require("which-key.state").state.node.keys
          end)
          return (ok and prefix == vim.fn.keytrans(vim.g.mapleader)) and "1-9" or key
        end,
      },
    },
    spec = {
      { "<leader>a", group = "AI" },
      { "<leader>c", group = "コード" },
      { "<leader>d", group = "デバッグ" },
      { "<leader>m", group = "Markdown" },
      { "<leader>f", group = "検索" },
      { "<leader>g", group = "Git" },
      { "<leader>l", group = "LSP" },
      { "<leader>b", group = "バッファ" },
      { "<leader>h", group = "Git差分" },
      { "<leader>t", group = "タブ" },
      { "<leader>u", group = "表示切替" },
      { "<leader>x", group = "診断・リスト" },
      { "<leader>w", proxy = "<c-w>", group = "ウィンドウ" },
      buffer_jump_spec,
      { "<c-w>", group = "ウィンドウ" },
      { "<c-w>+", desc = "高さを増やす" },
      { "<c-w>-", desc = "高さを減らす" },
      { "<c-w><", desc = "幅を減らす" },
      { "<c-w>=", desc = "サイズを均等にする" },
      { "<c-w>>", desc = "幅を増やす" },
      { "<c-w>T", desc = "新しいタブへ移動" },
      { "<c-w>_", desc = "高さを最大にする" },
      { "<c-w>d", desc = "カーソル位置の診断を表示" },
      { "<c-w><c-d>", desc = "カーソル位置の診断を表示" },
      { "<c-w>h", desc = "左のウィンドウへ" },
      { "<c-w>j", desc = "下のウィンドウへ" },
      { "<c-w>k", desc = "上のウィンドウへ" },
      { "<c-w>l", desc = "右のウィンドウへ" },
      { "<c-w>o", desc = "ほかをすべて閉じる" },
      { "<c-w>c", desc = "ウィンドウを閉じる" },
      { "<c-w>q", desc = "ウィンドウを閉じる" },
      { "<c-w>s", desc = "上下に分割" },
      { "<c-w>v", desc = "左右に分割" },
      { "<c-w>w", desc = "次のウィンドウへ" },
      { "<c-w>x", desc = "次と入れ替える" },
      { "<c-w>|", desc = "幅を最大にする" },
      { "<c-w>H", desc = "ウィンドウを左端へ" },
      { "<c-w>J", desc = "ウィンドウを下端へ" },
      { "<c-w>K", desc = "ウィンドウを上端へ" },
      { "<c-w>L", desc = "ウィンドウを右端へ" },
      { "z", group = "折りたたみ・表示位置" },
      { "z<CR>", desc = "この行を上端へ（行頭に移動）" },
      { "z=", desc = "スペル修正候補を表示" },
      { "zA", desc = "カーソル下の折りたたみを入れ子ごと開閉" },
      { "zC", desc = "カーソル下の折りたたみを入れ子ごと閉じる" },
      { "zD", desc = "カーソル下の折りたたみを入れ子ごと削除" },
      { "zE", desc = "ファイル内の折りたたみをすべて削除" },
      { "zH", desc = "半画面ぶん左へスクロール" },
      { "zL", desc = "半画面ぶん右へスクロール" },
      { "zM", desc = "すべての折りたたみを閉じる" },
      { "zO", desc = "カーソル下の折りたたみを入れ子ごと開く" },
      { "zR", desc = "すべての折りたたみを開く" },
      { "za", desc = "カーソル下の折りたたみを開閉" },
      { "zb", desc = "この行を下端へ" },
      { "zc", desc = "カーソル下の折りたたみを閉じる" },
      { "zd", desc = "カーソル下の折りたたみを削除" },
      { "ze", desc = "カーソル位置を右端へ" },
      { "zf", desc = "折りたたみを作成", mode = { "n", "x" } },
      { "zg", desc = "単語をスペル辞書に追加" },
      { "zi", desc = "折りたたみのオン/オフ" },
      { "zm", desc = "折りたたみを 1 段増やす" },
      { "zo", desc = "カーソル下の折りたたみを開く" },
      { "zr", desc = "折りたたみを 1 段減らす" },
      { "zs", desc = "カーソル位置を左端へ" },
      { "zt", desc = "この行を上端へ" },
      { "zv", desc = "カーソル行が見えるまで開く" },
      { "zw", desc = "単語をスペル誤りとして登録" },
      { "zx", desc = "折りたたみを再計算" },
      { "zz", desc = "この行を中央へ" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "現在のキーマップを表示",
    },
  },
}
