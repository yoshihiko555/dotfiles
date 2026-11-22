-- 行番号
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

-- インデント
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- 検索
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- 表示
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true

-- 編集ペインを離れたらカーソル行の目印を隠し、戻ったときに復元する
local cursorline_group = vim.api.nvim_create_augroup("ActiveWindowCursorline", { clear = true })
vim.api.nvim_create_autocmd("WinLeave", {
  group = cursorline_group,
  callback = function()
    if vim.bo.buftype == "" and vim.wo.cursorline then
      vim.w.restore_cursorline = true
      vim.wo.cursorline = false
    end
  end,
})
vim.api.nvim_create_autocmd("WinEnter", {
  group = cursorline_group,
  callback = function()
    if vim.w.restore_cursorline then
      vim.wo.cursorline = true
      vim.w.restore_cursorline = nil
    end
  end,
})

-- 画面分割
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ファイル管理
vim.opt.undofile = true
vim.opt.swapfile = false

-- その他
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = "menuone,noselect"
vim.opt.clipboard = "unnamedplus"
vim.opt.autoread = true

-- 外部ツール(Claude Code等)によるファイル変更を自動検知
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("AutoReload", { clear = true }),
  command = "silent! checktime",
})
