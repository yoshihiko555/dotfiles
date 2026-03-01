local warned = {}

local function ensure_executable(bin)
  if vim.fn.executable(bin) == 1 then
    return true
  end

  if not warned[bin] then
    warned[bin] = true
    vim.notify(("LSP binary not found: %s"):format(bin), vim.log.levels.WARN)
  end

  return false
end

local function find_root(bufnr, markers)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local uv = vim.uv or vim.loop
  if bufname == "" then
    return uv.cwd()
  end

  local found = vim.fs.find(markers, { upward = true, path = bufname })[1]
  if found then
    return vim.fs.dirname(found)
  end

  return vim.fs.dirname(bufname)
end

local servers = {
  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
  },
  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  },
  tsserver = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
    init_options = {
      hostInfo = "neovim",
    },
  },
}

local start_group = vim.api.nvim_create_augroup("user-lsp-start", { clear = true })
for name, server in pairs(servers) do
  vim.api.nvim_create_autocmd("FileType", {
    group = start_group,
    pattern = server.filetypes,
    callback = function(args)
      if not ensure_executable(server.cmd[1]) then
        return
      end

      vim.lsp.start({
        name = name,
        cmd = server.cmd,
        root_dir = find_root(args.buf, server.root_markers),
        init_options = server.init_options,
        single_file_support = true,
      }, {
        bufnr = args.buf,
      })
    end,
  })
end

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
})

local keymap_group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = keymap_group,
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gr", vim.lsp.buf.references, "Show references")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
  end,
})
