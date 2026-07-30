-- Claude CLI (claude -p) に質問を投げ、回答をフロートウィンドウに表示する自作ミニプラグイン
-- 一問一答が基本。cwd を Neovim 設定ディレクトリにして Read/Grep/Glob を許可し、
-- 実際の設定ファイルを踏まえた回答を得る。追い質問は --continue で直前の会話を継続する。

local M = {}

local MODEL = "sonnet"
local TIMEOUT_MS = 3 * 60 * 1000

local SYSTEM_PROMPT = table.concat({
  "あなたは Neovim の操作・設定に関するアシスタントです。",
  "カレントディレクトリはユーザーの Neovim 設定ディレクトリです。",
  "必要に応じて Read / Grep / Glob で実際の設定ファイルを確認してから、日本語で簡潔に回答してください。",
  "設定変更を提案する場合は対象ファイルのパスを明記してください。",
}, "\n")

local state = {
  running = false,
  last_answer = nil, ---@type string[]|nil
}

-- 回答表示用フロート。markdown のレンダリングは render-markdown.nvim に任せる
local function open_output_win()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "markdown"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " Claude (" .. MODEL .. ") ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
  return buf
end

local function set_lines(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function run(prompt, continue_conv)
  if state.running then
    vim.notify("Claude への問い合わせが実行中です", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("claude") ~= 1 then
    vim.notify("claude コマンドが見つかりません（PATH を確認してください）", vim.log.levels.ERROR)
    return
  end

  local cmd = {
    "claude",
    "-p",
    "--model",
    MODEL,
    "--allowed-tools",
    "Read,Grep,Glob",
    -- MCP サーバーを読み込まず起動を速くする
    "--strict-mcp-config",
    "--append-system-prompt",
    SYSTEM_PROMPT,
  }
  if continue_conv then
    table.insert(cmd, "--continue")
  end

  local buf = open_output_win()
  local header = { "# " .. prompt, "" }
  local started = vim.uv.hrtime()
  local function waiting_lines()
    local sec = math.floor((vim.uv.hrtime() - started) / 1e9)
    return { header[1], "", string.format("⏳ Claude (%s) に問い合わせ中… %ds", MODEL, sec) }
  end
  set_lines(buf, waiting_lines())

  local timer = vim.uv.new_timer()
  timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if state.running and vim.api.nvim_buf_is_valid(buf) then
        set_lines(buf, waiting_lines())
      end
    end)
  )

  state.running = true
  vim.system(cmd, {
    -- プロンプトがフラグとして誤解釈されないよう stdin で渡す
    stdin = prompt,
    cwd = vim.fn.stdpath("config"),
    timeout = TIMEOUT_MS,
  }, vim.schedule_wrap(function(out)
    state.running = false
    timer:stop()
    timer:close()

    local lines
    if out.code == 0 then
      lines = vim.list_extend(vim.list_slice(header), vim.split(vim.trim(out.stdout or ""), "\n"))
      state.last_answer = lines
    else
      lines = vim.list_extend(vim.list_slice(header), {
        "**エラー** (exit code: " .. tostring(out.code) .. ")",
        "",
      })
      vim.list_extend(lines, vim.split(vim.trim(out.stderr or "") .. "\n" .. vim.trim(out.stdout or ""), "\n"))
      if out.signal == 15 then
        table.insert(lines, "")
        table.insert(lines, "タイムアウトした可能性があります（" .. TIMEOUT_MS / 1000 .. "秒）")
      end
    end

    if vim.api.nvim_buf_is_valid(buf) then
      set_lines(buf, lines)
    else
      -- 待っている間にウィンドウを閉じていた場合
      vim.notify("Claude の回答を受信しました（<leader>al で表示）", vim.log.levels.INFO)
    end
  end))
end

-- 1行入力用フロート。<CR> で送信、ノーマルモードの <Esc> でキャンセル
local function open_input(title, on_submit)
  local width = math.min(80, math.floor(vim.o.columns * 0.7))
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = math.floor(vim.o.lines * 0.35),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
  })
  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function submit()
    local line = vim.trim(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
    vim.cmd.stopinsert()
    close()
    if line ~= "" then
      on_submit(line)
    end
  end
  vim.keymap.set({ "i", "n" }, "<CR>", submit, { buffer = buf })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf })
  vim.cmd.startinsert()
end

function M.ask()
  open_input(" Claude に質問 ", function(prompt)
    run(prompt, false)
  end)
end

function M.ask_continue()
  open_input(" Claude に追い質問（直前の会話を継続） ", function(prompt)
    run(prompt, true)
  end)
end

function M.show_last()
  if not state.last_answer then
    vim.notify("表示できる回答がまだありません", vim.log.levels.INFO)
    return
  end
  set_lines(open_output_win(), state.last_answer)
end

function M.setup()
  vim.api.nvim_create_user_command("ClaudeAsk", function(opts)
    if opts.args ~= "" then
      run(opts.args, false)
    else
      M.ask()
    end
  end, { nargs = "*", desc = "Claude に質問する" })
  vim.api.nvim_create_user_command("ClaudeAskContinue", function(opts)
    if opts.args ~= "" then
      run(opts.args, true)
    else
      M.ask_continue()
    end
  end, { nargs = "*", desc = "Claude に追い質問する（会話継続）" })
  vim.api.nvim_create_user_command("ClaudeAskLast", M.show_last, { desc = "Claude の直前の回答を再表示" })

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { noremap = true, silent = true, desc = desc })
  end
  map("<leader>aa", M.ask, "Claudeに質問")
  map("<leader>ac", M.ask_continue, "Claudeに追い質問（会話継続）")
  map("<leader>al", M.show_last, "Claudeの直前の回答を再表示")
end

return M
