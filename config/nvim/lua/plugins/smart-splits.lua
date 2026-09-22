-- smart-splits.nvim: Neovim ↔ tmux/herdr シームレスペイン移動/リサイズ
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    -- マルチプレクサは明示指定せず自動判定に任せる。
    -- smart-splits.nvim は起動時に環境変数を見て
    -- herdr(HERDR_ENV) → tmux(TERM_PROGRAM=="tmux") → zellij → wezterm → kitty
    -- の順に判定するため、普段の tmux セッションと試用中の herdr セッションが
    -- 混在していても、それぞれのペインで正しいバックエンドが自動選択される。
    -- 旧設定の `default_mux = "tmux"` は実際には存在しないキー（正しくは
    -- multiplexer_integration）で常に無視されており、tmux 側の越境移動は
    -- 元々この自動判定だけで動いていた。よって明示指定をやめても tmux 側の
    -- 挙動は変わらない。
    -- default_amount は「行・桁」の整数で、Neovim のウィンドウ（`:resize ±N`）と
    -- マルチプレクサのペインの両方にそのまま渡される。herdr の `pane resize --amount`
    -- だけは「タブ全体の幅に対する割合」を取る（実測: 幅246のタブで 0.01 → +3 桁）
    -- ので、以前は herdr のときだけ default_amount = 0.012 にしていた。
    -- しかしその値は Neovim 側にも渡り、`:vertical resize -0.012` は何もしない
    -- （実測: 幅 40 → 40。整数 3 なら 40 → 37）ため、ペインの端でない Neovim
    -- ウィンドウの Alt+Shift+HJKL リサイズが効かなくなっていた（2026-09-23 判明）。
    -- default_amount は整数のまま、herdr バックエンドに渡る直前で割合へ換算する。
    require("smart-splits").setup({
      default_amount = 3,
    })
    if vim.env.HERDR_ENV ~= nil and vim.env.HERDR_ENV ~= "" then
      -- 1 桁 ≒ 0.004（幅246のタブでの実測。herdr-smart-move の HERDR_RESIZE_FINE と同じ定数）
      local herdr_mux = require("smart-splits.mux.herdr")
      local resize_pane = herdr_mux.resize_pane
      herdr_mux.resize_pane = function(direction, amount)
        return resize_pane(direction, amount * 0.004)
      end
    end

    -- Alt+h/j/k/l: ペイン移動（tmux の smart-splits.conf と連携）
    vim.keymap.set("n", "<A-h>", require("smart-splits").move_cursor_left, { desc = "左のペインへ" })
    vim.keymap.set("n", "<A-j>", require("smart-splits").move_cursor_down, { desc = "下のペインへ" })
    vim.keymap.set("n", "<A-k>", require("smart-splits").move_cursor_up, { desc = "上のペインへ" })
    vim.keymap.set("n", "<A-l>", require("smart-splits").move_cursor_right, { desc = "右のペインへ" })

    -- Alt+Shift+H/J/K/L: ペインリサイズ（tmux の smart-splits.conf と連携）
    vim.keymap.set("n", "<A-S-h>", require("smart-splits").resize_left, { desc = "左へ広げる" })
    vim.keymap.set("n", "<A-S-j>", require("smart-splits").resize_down, { desc = "下へ広げる" })
    vim.keymap.set("n", "<A-S-k>", require("smart-splits").resize_up, { desc = "上へ広げる" })
    vim.keymap.set("n", "<A-S-l>", require("smart-splits").resize_right, { desc = "右へ広げる" })
  end,
}
