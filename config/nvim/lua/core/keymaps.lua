-- 一般キーマップ（非LSP）
-- LSPキーマップは plugins/lsp.lua の LspAttach autocmd で管理

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- 検索ハイライトをすぐ消して視認性を保つ
map("n", "<Esc>", "<cmd>nohlsearch<cr>", "検索ハイライトを消す")
map("i", "jj", "<Esc>", "ノーマルモードへ")

-- 空行挿入（挿入モードに入らずに前後へ空行を足す）
map("n", "]<Space>", "<cmd>call append(line('.'), '')<cr>", "下に空行を挿入")
map("n", "[<Space>", "<cmd>call append(line('.') - 1, '')<cr>", "上に空行を挿入")

-- ウィンドウ移動は smart-splits.nvim で管理 (plugins/smart-splits.lua)
-- Alt+h/j/k/l で Neovim ↔ tmux シームレス移動

-- バッファ操作
map("n", "<leader>bn", "<cmd>bnext<cr>", "次のバッファへ")
map("n", "<leader>bp", "<cmd>bprevious<cr>", "前のバッファへ")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "バッファを閉じる")

-- タブ操作（<leader>t は表示切替グループで使用済みのため <leader>T を使う）
map("n", "<leader>Tn", "<cmd>tabnew<cr>", "新しいタブ")
map("n", "<leader>Tl", "<cmd>tabnext<cr>", "次のタブへ")
map("n", "<leader>Th", "<cmd>tabprevious<cr>", "前のタブへ")
map("n", "<leader>Td", "<cmd>tabclose<cr>", "タブを閉じる")
map("n", "<leader>To", "<cmd>tabonly<cr>", "ほかのタブをすべて閉じる")

-- Quickfix / location list 操作
map("n", "]q", "<cmd>cnext<cr>", "次のQuickfixへ")
map("n", "[q", "<cmd>cprev<cr>", "前のQuickfixへ")
map("n", "<leader>xq", "<cmd>copen<cr>", "Quickfixを開く")
map("n", "<leader>xc", "<cmd>cclose<cr>", "Quickfixを閉じる")
map("n", "<leader>xl", "<cmd>lopen<cr>", "Location Listを開く")
map("n", "<leader>xL", "<cmd>lclose<cr>", "Location Listを閉じる")
map("n", "<leader>xd", function()
  vim.diagnostic.setqflist({ open = true })
end, "診断をQuickfixに表示")
