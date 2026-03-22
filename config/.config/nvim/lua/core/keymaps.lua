-- 一般キーマップ（非LSP）
-- LSPキーマップは plugins/lsp.lua の LspAttach autocmd で管理

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- 検索ハイライトをすぐ消して視認性を保つ
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("i", "jj", "<Esc>", "Exit insert mode")

-- ウィンドウ移動は smart-splits.nvim で管理 (plugins/smart-splits.lua)
-- Alt+h/j/k/l で Neovim ↔ tmux シームレス移動

-- バッファ操作
map("n", "<leader>bn", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>bp", "<cmd>bprevious<cr>", "Previous buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")

-- Quickfix / location list 操作
map("n", "]q", "<cmd>cnext<cr>", "Next quickfix")
map("n", "[q", "<cmd>cprev<cr>", "Previous quickfix")
map("n", "<leader>xq", "<cmd>copen<cr>", "Quickfix open")
map("n", "<leader>xc", "<cmd>cclose<cr>", "Quickfix close")
map("n", "<leader>xl", "<cmd>lopen<cr>", "Location list open")
map("n", "<leader>xL", "<cmd>lclose<cr>", "Location list close")
map("n", "<leader>xd", function()
  vim.diagnostic.setqflist({ open = true })
end, "Diagnostics to quickfix")
