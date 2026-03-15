local wezterm = require 'wezterm'
local act = wezterm.action
local context = require('config/context')

local M = {}

-- =============================================================================
-- smart-splits.nvim 統合（Neovim ↔ WezTerm シームレスペイン移動）
-- =============================================================================

local direction_keys = { h = 'Left', j = 'Down', k = 'Up', l = 'Right' }

--- Neovim が実行中かどうかを判定（smart-splits.nvim が設定するユーザー変数を参照）
local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == 'true'
end

--- smart-splits 対応のペイン移動/リサイズキーバインドを生成
--- @param resize_or_move 'resize' | 'move'
--- @param key string h/j/k/l
function M.split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META|SHIFT' or 'META',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'META|SHIFT' or 'META' },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

-- =============================================================================
-- overlay pane（split + zoom でフローティング相当）
-- =============================================================================

local function activate_split(pane, opts)
  local new_pane = pane:split(opts)
  new_pane:activate()
  return new_pane
end

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function shell_command_args(command)
  local shell = os.getenv('SHELL') or '/bin/zsh'
  -- login + interactive shell で起動し、PATH や alias を既存シェル設定に揃える
  return { shell, '-lic', command }
end

local function interactive_shell_command()
  local shell = os.getenv('SHELL') or '/bin/zsh'
  -- 一時シェルを閉じたら外側の login shell を 0 で終了させ、
  -- Ctrl+D 時にもペイン枠だけ残らないようにする
  return shell_quote(shell) .. ' -i; exit 0'
end

local function command_exists(command)
  local shell = os.getenv('SHELL') or '/bin/zsh'
  local probe = shell .. ' -lic ' .. shell_quote('command -v ' .. command .. ' >/dev/null 2>&1')
  local ok, _, code = os.execute(probe)
  if type(ok) == 'number' then
    return ok == 0
  end
  return ok == true and code == 0
end

--- overlay pane: split + zoom で全画面起動
--- コマンド終了 → ペイン自動消滅 → レイアウト復帰
local function open_overlay(command)
  return wezterm.action_callback(function(window, pane)
    local new_pane = pane:split({
      direction = 'Bottom',
      size = 0.5,
      cwd = context.get_cwd_path(pane),
      args = shell_command_args(command),
    })
    window:perform_action(act.SetPaneZoomState(true), new_pane)
  end)
end

M.overlay_lazygit = open_overlay('lazygit')
M.overlay_yazi = open_overlay('yazi')
M.overlay_claude = open_overlay('claude')
M.open_bottom_shell = open_overlay(interactive_shell_command())

-- =============================================================================
-- ワークスペース（プロジェクト単位のタブグループ）
-- =============================================================================

local dotfiles_root = wezterm.home_dir .. '/ghq/github.com/yoshihiko555/dotfiles'
local repo_list_script = dotfiles_root .. '/scripts/repo-list.sh'

--- ワークスペースが既に存在するか判定
local function workspace_exists(name)
  for _, ws in ipairs(wezterm.mux.get_workspace_names()) do
    if ws == name then return true end
  end
  return false
end

--- 指定 workspace に属する pane id を列挙
local function collect_workspace_pane_ids(name)
  local pane_ids = {}

  for _, mux_win in ipairs(wezterm.mux.all_windows()) do
    if mux_win:get_workspace() == name then
      for _, tab in ipairs(mux_win:tabs()) do
        for _, tab_pane in ipairs(tab:panes()) do
          table.insert(pane_ids, tab_pane:pane_id())
        end
      end
    end
  end

  return pane_ids
end

--- pane id を直接指定して安全に終了
local function kill_pane_by_id(pane_id)
  local success, _, stderr = wezterm.run_child_process({
    'wezterm', 'cli', 'kill-pane', '--pane-id', tostring(pane_id),
  })

  if success then
    return true
  end

  wezterm.log_warn('failed to kill pane ' .. tostring(pane_id) .. ': ' .. (stderr or 'unknown error'))
  return false
end

--- repo-list.sh の出力を InputSelector の choices に変換
local function build_project_choices()
  local success, stdout, stderr = wezterm.run_child_process({ 'bash', '-l', repo_list_script })
  if not success or not stdout then
    wezterm.log_warn('repo-list.sh failed: ' .. (stderr or 'unknown error'))
    return {}
  end

  local choices = {}
  -- worktree を先に表示
  local repos, worktrees = {}, {}
  for line in stdout:gmatch('[^\n]+') do
    local type_, label, path = line:match('^(%S+)\t([^\t]+)\t(.+)$')
    if label and path then
      if type_ == 'worktree' then
        table.insert(worktrees, { label = label, path = path })
      else
        table.insert(repos, { label = label, path = path })
      end
    end
  end

  -- ── Worktrees（アクティブな作業ブランチ）
  if #worktrees > 0 then
    table.insert(choices, {
      id = '',
      label = wezterm.format {
        { Foreground = { Color = '#f5a97f' } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = wezterm.nerdfonts.cod_git_merge .. ' Worktrees' },
        { Attribute = { Intensity = 'Normal' } },
        { Foreground = { Color = '#494d64' } },
        { Text = ' ' .. string.rep('─', 80) },
      },
    })
    for _, wt in ipairs(worktrees) do
      local repo, branch = wt.label:match('.-/([^/]+):(.+)$')
      local ws_name = (repo and branch) and (repo .. ':' .. branch) or wt.label
      table.insert(choices, {
        id = wt.path .. '\t' .. ws_name,
        label = wezterm.format {
          { Text = '    ' },
          { Foreground = { Color = '#cad3f5' } },
          { Attribute = { Intensity = 'Bold' } },
          { Text = branch or wt.label },
          { Attribute = { Intensity = 'Normal' } },
          { Foreground = { Color = '#6e738d' } },
          { Text = '  ' .. (repo or '') },
        },
      })
    end
  end

  -- ── Repositories
  if #repos > 0 then
    table.insert(choices, {
      id = '',
      label = wezterm.format {
        { Foreground = { Color = '#8bd5ca' } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = wezterm.nerdfonts.oct_repo .. ' Repositories' },
        { Attribute = { Intensity = 'Normal' } },
        { Foreground = { Color = '#494d64' } },
        { Text = ' ' .. string.rep('─', 80) },
      },
    })
    for _, r in ipairs(repos) do
      local repo = r.label:match('([^/]+)$') or r.label
      table.insert(choices, {
        id = r.path,
        label = wezterm.format {
          { Text = '    ' },
          { Foreground = { Color = '#8bd5ca' } },
          { Text = wezterm.nerdfonts.oct_repo .. ' ' },
          { Foreground = { Color = '#cad3f5' } },
          { Text = repo },
        },
      })
    end
  end

  return choices
end

--- Leader+p: プロジェクトを fuzzy 選択してワークスペースを作成/切替
M.select_project = wezterm.action_callback(function(window, pane)
  local choices = build_project_choices()
  if #choices == 0 then
    window:toast_notification('workspace', 'プロジェクトが見つかりません', nil, 3000)
    return
  end

  window:perform_action(act.InputSelector {
    title = 'Open Project',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, id, label)
      if not id or id == '' then return end

      -- worktree の場合は id が "path\tws_name" 形式
      local cwd, ws_name = id:match('^([^\t]+)\t(.+)$')
      if not cwd then
        -- 通常リポジトリ: id はパスのみ
        cwd = id
        ws_name = context.get_project_name_from_path(cwd)
      end

      win:perform_action(act.SwitchToWorkspace {
        name = ws_name,
        spawn = { cwd = cwd },
      }, p)
    end),
  }, pane)
end)

--- Leader+s: 既存ワークスペース一覧から fuzzy 切替
M.switch_workspace = wezterm.action_callback(function(window, pane)
  local current = window:mux_window():get_workspace()
  local workspaces = wezterm.mux.get_workspace_names()

  if #workspaces <= 1 then
    window:toast_notification('workspace', '他のワークスペースがありません', nil, 3000)
    return
  end

  local choices = {}
  for _, ws in ipairs(workspaces) do
    local is_current = (ws == current)
    local is_worktree = ws:find(':') ~= nil
    local fmt = {}
    if is_current then
      table.insert(fmt, { Foreground = { Color = '#f5a97f' } })
      table.insert(fmt, { Text = wezterm.nerdfonts.fa_circle .. ' ' })
      if is_worktree then
        table.insert(fmt, { Foreground = { Color = '#f5a97f' } })
        table.insert(fmt, { Text = wezterm.nerdfonts.cod_git_merge .. ' ' })
      else
        table.insert(fmt, { Foreground = { Color = '#8bd5ca' } })
        table.insert(fmt, { Text = wezterm.nerdfonts.oct_repo .. ' ' })
      end
      table.insert(fmt, { Foreground = { Color = '#cad3f5' } })
      table.insert(fmt, { Attribute = { Intensity = 'Bold' } })
      table.insert(fmt, { Text = ws })
      table.insert(fmt, { Attribute = { Intensity = 'Normal' } })
      table.insert(fmt, { Foreground = { Color = '#6e738d' } })
      table.insert(fmt, { Text = '  (current)' })
    else
      if is_worktree then
        table.insert(fmt, { Foreground = { Color = '#f5a97f' } })
        table.insert(fmt, { Text = wezterm.nerdfonts.fa_circle_o .. ' ' })
        table.insert(fmt, { Text = wezterm.nerdfonts.cod_git_merge .. ' ' })
      else
        table.insert(fmt, { Foreground = { Color = '#8bd5ca' } })
        table.insert(fmt, { Text = wezterm.nerdfonts.fa_circle_o .. ' ' })
        table.insert(fmt, { Text = wezterm.nerdfonts.oct_repo .. ' ' })
      end
      table.insert(fmt, { Foreground = { Color = '#cad3f5' } })
      table.insert(fmt, { Text = ws })
    end
    table.insert(choices, { id = ws, label = wezterm.format(fmt) })
  end

  window:perform_action(act.InputSelector {
    title = 'Switch Workspace',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, id, label)
      if not id or id == '' then return end
      win:perform_action(act.SwitchToWorkspace { name = id }, p)
    end),
  }, pane)
end)

--- Leader+S: ワークスペースを選択して削除（全タブ/ペインを閉じる）
M.delete_workspace = wezterm.action_callback(function(window, pane)
  local current = window:mux_window():get_workspace()
  local workspaces = wezterm.mux.get_workspace_names()

  -- 現在のワークスペース以外を候補にする
  local choices = {}
  for _, ws in ipairs(workspaces) do
    if ws ~= current then
      table.insert(choices, {
        id = ws,
        label = wezterm.format {
          { Foreground = { Color = '#ed8796' } },
          { Text = wezterm.nerdfonts.fa_trash .. ' ' },
          { Foreground = { Color = '#cad3f5' } },
          { Text = ws },
        },
      })
    end
  end

  if #choices == 0 then
    window:toast_notification('workspace', '削除できるワークスペースがありません', nil, 3000)
    return
  end

  window:perform_action(act.InputSelector {
    title = 'Delete Workspace',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, id, label)
      if not id or id == '' then return end
      local pane_ids = collect_workspace_pane_ids(id)

      if #pane_ids == 0 then
        win:toast_notification('workspace', id .. ' の pane が見つかりません', nil, 3000)
        return
      end

      local failed = 0
      for _, pane_id in ipairs(pane_ids) do
        if not kill_pane_by_id(pane_id) then
          failed = failed + 1
        end
      end

      if failed > 0 then
        win:toast_notification('workspace', id .. ' の削除に一部失敗しました', nil, 3000)
        return
      end

      win:toast_notification('workspace', id .. ' を削除しました', nil, 2000)
    end),
  }, pane)
end)

-- =============================================================================
-- Alfred 外部トリガー（ファイルベース IPC）
-- /tmp/wezterm-alfred-workspace.json を検知して SwitchToWorkspace を実行
-- =============================================================================

local ALFRED_TRIGGER_PATH = '/tmp/wezterm-alfred-workspace.json'
local ALFRED_TRIGGER_MAX_AGE = 5 -- 秒: これより古いトリガーファイルは無視
local alfred_last_check = 0
local ALFRED_CHECK_INTERVAL = 1 -- 秒: io.open の頻度を抑制

function M.setup_alfred_watcher()
  wezterm.on('update-status', function(window, pane)
    local now = os.time()
    if (now - alfred_last_check) < ALFRED_CHECK_INTERVAL then return end
    alfred_last_check = now

    local file = io.open(ALFRED_TRIGGER_PATH, 'r')
    if not file then return end

    local content = file:read('*a')
    file:close()
    os.remove(ALFRED_TRIGGER_PATH)

    if not content or content == '' then return end

    local ok, data = pcall(wezterm.json_parse, content)
    if not ok or type(data) ~= 'table' then return end

    local ts = tonumber(data.timestamp)
    if ts and (now - ts) > ALFRED_TRIGGER_MAX_AGE then return end

    local ws_name = data.name
    local cwd = data.cwd
    if not ws_name or not cwd then return end

    window:perform_action(act.SwitchToWorkspace {
      name = ws_name,
      spawn = { cwd = cwd },
    }, pane)
  end)
end

-- =============================================================================
-- サブエージェント監視（tmux セッションに overlay attach）
-- ai-orchestra の tmux-monitor が作成する claude-* セッションを表示
-- =============================================================================

M.overlay_tmux_monitor = wezterm.action_callback(function(window, pane)
  -- claude- で始まる tmux セッションを検索
  local success, stdout = wezterm.run_child_process({
    'tmux', 'list-sessions', '-F', '#{session_name}',
  })
  if not success or not stdout then
    window:toast_notification('tmux-monitor', 'tmux セッションが見つかりません', nil, 3000)
    return
  end

  local sessions = {}
  for line in stdout:gmatch('[^\n]+') do
    if line:match('^claude%-') then
      table.insert(sessions, line)
    end
  end

  if #sessions == 0 then
    window:toast_notification('tmux-monitor', '監視セッションがありません', nil, 3000)
    return
  end

  if #sessions == 1 then
    -- セッションが1つなら直接 attach
    local new_pane = pane:split({
      direction = 'Bottom',
      size = 0.5,
      args = shell_command_args('tmux attach-session -t ' .. shell_quote(sessions[1])),
    })
    window:perform_action(act.SetPaneZoomState(true), new_pane)
    return
  end

  -- 複数セッションがある場合は InputSelector で選択
  local choices = {}
  for _, s in ipairs(sessions) do
    table.insert(choices, {
      id = s,
      label = wezterm.format {
        { Foreground = { Color = '#c3e88d' } },
        { Text = wezterm.nerdfonts.cod_terminal_tmux .. ' ' },
        { Foreground = { Color = '#cad3f5' } },
        { Text = s },
      },
    })
  end

  window:perform_action(act.InputSelector {
    title = 'Attach to Monitor Session',
    choices = choices,
    fuzzy = true,
    action = wezterm.action_callback(function(win, p, id)
      if not id or id == '' then return end
      local new_pane = p:split({
        direction = 'Bottom',
        size = 0.5,
        args = shell_command_args('tmux attach-session -t ' .. shell_quote(id)),
      })
      win:perform_action(act.SetPaneZoomState(true), new_pane)
    end),
  }, pane)
end)

-- 画面クリア（スクロールバックに内容を保存）アクション
M.clear_screen_save_scrollback = wezterm.action_callback(function(window, pane)
  -- vim等のTUIプログラム内では通常のCtrl+Lを送る
  if pane:is_alt_screen_active() then
    pane:send_text('\x0c')
    return
  end

  -- 最下部にスクロール
  window:perform_action(wezterm.action.ScrollToBottom, pane)

  -- ビューポートの高さを取得
  local height = pane:get_dimensions().viewport_rows

  -- ビューポートの高さ分の改行を作成
  local blank_viewport = string.rep('\r\n', height)

  -- 改行を挿入してビューポートの内容をスクロールバックにプッシュ
  pane:inject_output(blank_viewport)

  -- Ctrl+Lを送信してビューポートをクリア
  pane:send_text('\x0c')
end)

-- スクロールバックとビューポートを消去
M.clear_scrollback_and_viewport = wezterm.action_callback(function(window, pane)
  window:perform_action(act.ClearScrollback 'ScrollbackAndViewport', pane)
end)

local function show_cheatsheet(cheatsheet)
  return wezterm.action_callback(function(window, pane)
    local args

    if command_exists('glow') then
      args = { '/opt/homebrew/bin/glow', '-s', 'dracula', '-p', cheatsheet }
    else
      args = shell_command_args('nvim -R ' .. shell_quote(cheatsheet))
    end

    local cheat_pane = pane:split({
      direction = 'Right',
      size = 0.4,
      args = args,
    })
    cheat_pane:activate()
  end)
end

-- チートシート表示（右ペインに glow / nvim で表示）
M.show_cheatsheet = show_cheatsheet(wezterm.home_dir .. '/.config/nvim/docs/CHEATSHEET.md')
M.show_wezterm_cheatsheet = show_cheatsheet(wezterm.home_dir .. '/.config/wezterm/CHEATSHEET.md')

return M
