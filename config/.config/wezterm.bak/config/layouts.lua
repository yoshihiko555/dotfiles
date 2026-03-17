local wezterm = require 'wezterm'
local context = require('config/context')

local M = {}

-- =============================================================================
-- 分割レイアウト定義
-- =============================================================================

-- split_layouts[N] = function(first_pane, cwd)
-- first_pane から N ペインに分割する手順を定義
local split_layouts = {
  -- 左右分割
  -- ┌──────┬──────┐
  -- │  1   │  2   │
  -- └──────┴──────┘
  [2] = function(first_pane, cwd)
    first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
  end,

  -- 左 + 右上下
  -- ┌──────┬──────┐
  -- │      │  2   │
  -- │  1   ├──────┤
  -- │      │  3   │
  -- └──────┴──────┘
  [3] = function(first_pane, cwd)
    local right = first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    right:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
  end,

  -- 2x2 グリッド
  -- ┌──────┬──────┐
  -- │  1   │  2   │
  -- ├──────┼──────┤
  -- │  3   │  4   │
  -- └──────┴──────┘
  [4] = function(first_pane, cwd)
    local right = first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    first_pane:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    right:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
  end,

  -- 上2 + 下3
  -- ┌────────┬────────┐
  -- │   1    │   2    │
  -- ├─────┬──┴──┬─────┤
  -- │  3  │  4  │  5  │
  -- └─────┴─────┴─────┘
  [5] = function(first_pane, cwd)
    local bottom = first_pane:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    local br = bottom:split({ direction = 'Right', size = 0.67, cwd = cwd })
    br:split({ direction = 'Left', size = 0.5, cwd = cwd })
  end,

  -- 2x3 グリッド
  -- ┌─────┬─────┬─────┐
  -- │  1  │  2  │  3  │
  -- ├─────┼─────┼─────┤
  -- │  4  │  5  │  6  │
  -- └─────┴─────┴─────┘
  [6] = function(first_pane, cwd)
    local bottom = first_pane:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    local tr = first_pane:split({ direction = 'Right', size = 0.67, cwd = cwd })
    tr:split({ direction = 'Left', size = 0.5, cwd = cwd })
    local br = bottom:split({ direction = 'Right', size = 0.67, cwd = cwd })
    br:split({ direction = 'Left', size = 0.5, cwd = cwd })
  end,

  -- 上3 + 下4
  -- ┌─────┬─────┬─────┐
  -- │  1  │  2  │  3  │
  -- ├───┬─┴──┬──┴─┬───┤
  -- │ 4 │ 5  │ 6  │ 7 │
  -- └───┴────┴────┴───┘
  [7] = function(first_pane, cwd)
    local bottom = first_pane:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    -- 上段3列
    local tr = first_pane:split({ direction = 'Right', size = 0.67, cwd = cwd })
    tr:split({ direction = 'Left', size = 0.5, cwd = cwd })
    -- 下段4列（二分木方式）
    local br_half = bottom:split({ direction = 'Right', size = 0.5, cwd = cwd })
    bottom:split({ direction = 'Right', size = 0.5, cwd = cwd })
    br_half:split({ direction = 'Right', size = 0.5, cwd = cwd })
  end,

  -- 4x2 グリッド
  -- ┌───┬───┬───┬───┐
  -- │ 1 │ 2 │ 3 │ 4 │
  -- ├───┼───┼───┼───┤
  -- │ 5 │ 6 │ 7 │ 8 │
  -- └───┴───┴───┴───┘
  [8] = function(first_pane, cwd)
    local bottom = first_pane:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    -- 上段4列（二分木方式）
    local tr_half = first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    tr_half:split({ direction = 'Right', size = 0.5, cwd = cwd })
    -- 下段4列
    local br_half = bottom:split({ direction = 'Right', size = 0.5, cwd = cwd })
    bottom:split({ direction = 'Right', size = 0.5, cwd = cwd })
    br_half:split({ direction = 'Right', size = 0.5, cwd = cwd })
  end,
}

-- =============================================================================
-- split_to(n) — Leader+2~8 用
-- =============================================================================

--- 現在のタブを N ペインに分割するアクションを返す
--- 1ペイン以外のタブでは toast で拒否
function M.split_to(n)
  return wezterm.action_callback(function(window, pane)
    local tab = pane:tab()
    local pane_count = #tab:panes()

    if pane_count ~= 1 then
      window:toast_notification(
        'layout',
        '1ペインのタブでのみ実行できます (現在: ' .. pane_count .. 'ペイン)',
        nil, 3000
      )
      return
    end

    local builder = split_layouts[n]
    if not builder then
      window:toast_notification('layout', n .. '分割は未対応です', nil, 3000)
      return
    end

    local cwd = context.get_cwd_path(pane) or wezterm.home_dir
    builder(pane, cwd)
    pane:activate()
  end)
end

-- =============================================================================
-- init_panes — Leader+1 用
-- =============================================================================

--- ペイン数に応じてプロセスを起動
--- 2ペイン: pane1=nvim, pane2=free
--- 3ペイン: pane1=nvim, pane2=claude, pane3=free
--- 4ペイン: pane1=claude, pane2=codex, pane3=free, pane4=free
--- 8ペイン: 既存の8ペインロジック（claude x2, codex, gemini, tmux x2, shell x2）
M.init_panes = wezterm.action_callback(function(window, pane)
  local tab = pane:tab()
  local panes_info = tab:panes_with_info()
  local pane_count = #panes_info

  local supported = { [2] = true, [3] = true, [4] = true, [8] = true }
  if not supported[pane_count] then
    window:toast_notification(
      'init_panes',
      pane_count .. 'ペインには未対応です (対応: 2, 3, 4, 8)',
      nil, 3000
    )
    return
  end

  -- ペインを位置順にソート（上→下、左→右）
  table.sort(panes_info, function(a, b)
    if a.top ~= b.top then return a.top < b.top end
    return a.left < b.left
  end)

  -- pane 1 の cwd を取得
  local cwd = context.get_cwd_path(panes_info[1].pane)
  if not cwd then
    window:toast_notification('init_panes', 'pane 1 の cwd を取得できません', nil, 3000)
    return
  end
  cwd = cwd:gsub('/$', '')
  if cwd == '' then return end

  -- GHQ リポジトリ配下でのみ実行を許可
  local ghq_root = wezterm.home_dir .. '/ghq/'
  if cwd:sub(1, #ghq_root) ~= ghq_root then
    window:toast_notification(
      'init_panes',
      'GHQ リポジトリ配下でのみ実行できます\ncwd: ' .. cwd,
      nil, 4000
    )
    return
  end

  local function sq(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
  end

  -- TUI プロセスが実行中のペインがないかチェック（二重起動防止）
  for i = 1, pane_count do
    if panes_info[i].pane:is_alt_screen_active() then
      window:toast_notification(
        'init_panes',
        'ペイン ' .. i .. ' でプロセスが実行中です\n先に終了してください',
        nil, 4000
      )
      return
    end
  end

  -- pane 2-* を pane 1 のディレクトリへ移動
  for i = 2, pane_count do
    panes_info[i].pane:send_text('cd ' .. sq(cwd) .. '\n')
  end

  if pane_count == 2 then
    -- pane 1: nvim, pane 2: free
    panes_info[1].pane:send_text('nvim\n')
    panes_info[1].pane:activate()
    return
  end

  if pane_count == 3 then
    -- pane 1: nvim, pane 2: claude, pane 3: free
    panes_info[1].pane:send_text('nvim\n')
    panes_info[2].pane:send_text('claude\n')
    panes_info[1].pane:activate()
    return
  end

  if pane_count == 4 then
    -- pane 1: claude, pane 2: codex, pane 3: free, pane 4: free
    panes_info[1].pane:send_text('claude\n')
    panes_info[2].pane:send_text('codex\n')
    panes_info[1].pane:activate()
    return
  end

  -- 8ペイン
  local project = context.get_project_name_from_path(cwd)
  if project == '' then project = 'project' end
  project = project:gsub('[%.:]', '-')

  -- pane 1, 2: Claude Code
  panes_info[1].pane:send_text("sh -c 'echo $$ > /tmp/wez-cc1.pid; exec claude'\n")
  panes_info[2].pane:send_text("sh -c 'echo $$ > /tmp/wez-cc2.pid; exec claude'\n")

  -- pane 3: Codex
  panes_info[3].pane:send_text('codex\n')

  -- pane 4: Gemini
  panes_info[4].pane:send_text('gemini\n')

  -- pane 5: pane 1 の Claude Code tmux セッションにアタッチ
  panes_info[5].pane:send_text(
    "sleep 1 && CC_PID=$(cat /tmp/wez-cc1.pid 2>/dev/null) && "
    .. 'SN="claude-' .. project .. '-${CC_PID}" && '
    .. 'until command tmux has-session -t "$SN" 2>/dev/null; do sleep 2; done && '
    .. 'command tmux attach-session -t "$SN"\n'
  )

  -- pane 6: pane 2 の Claude Code tmux セッションにアタッチ
  panes_info[6].pane:send_text(
    "sleep 1 && CC_PID=$(cat /tmp/wez-cc2.pid 2>/dev/null) && "
    .. 'SN="claude-' .. project .. '-${CC_PID}" && '
    .. 'until command tmux has-session -t "$SN" 2>/dev/null; do sleep 2; done && '
    .. 'command tmux attach-session -t "$SN"\n'
  )

  -- pane 7, 8: free（cd 済み）

  panes_info[1].pane:activate()
end)

return M
