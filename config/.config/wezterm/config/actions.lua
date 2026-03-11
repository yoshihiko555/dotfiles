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

-- プロジェクトごとのレイアウト定義
-- key: プロジェクト名（ワークスペース名と一致させる）
-- value: レイアウトプリセット名
local project_layouts = {
  -- 例:
  -- ['web-app'] = '3tab',
  -- ['api-server'] = 'ide',
}

-- レイアウトプリセット
-- 各関数は (mux_window, cwd) を受け取り、タブ・ペインを構築する
-- 注: ワークスペース作成時に最初の1タブは自動で存在するため、それを活用する
local layout_presets = {
  -- デフォルト: 3ペイン1タブ（既存の Cmd+t と同じ）
  -- ┌──────┬──────┐
  -- │      │  2   │
  -- │  1   ├──────┤
  -- │      │  3   │
  -- └──────┴──────┘
  default = function(first_pane, mux_win, cwd)
    local right = first_pane:split({ direction = 'Right', size = 0.5, cwd = cwd })
    right:split({ direction = 'Bottom', size = 0.5, cwd = cwd })
    first_pane:activate()
  end,

  -- 3タブ: Tab1 フル, Tab2 左右分割, Tab3 フル
  -- Tab1:          Tab2:            Tab3:
  -- ┌──────────┐  ┌─────┬─────┐  ┌──────────┐
  -- │    1     │  │  1  │  2  │  │    1     │
  -- └──────────┘  └─────┴─────┘  └──────────┘
  ['3tab'] = function(first_pane, mux_win, cwd)
    -- Tab 1 は first_pane（そのまま）
    -- Tab 2: 左右分割
    local tab2, pane2, _ = mux_win:spawn_tab({ cwd = cwd })
    pane2:split({ direction = 'Right', size = 0.5, cwd = cwd })
    -- Tab 3: フル
    mux_win:spawn_tab({ cwd = cwd })
    -- Tab 1 に戻る
    first_pane:activate()
  end,

  -- IDE: Tab1 エディタ全画面, Tab2 エージェント左右, Tab3 フリー
  -- Tab1:          Tab2:            Tab3:
  -- ┌──────────┐  ┌─────┬─────┐  ┌──────────┐
  -- │  editor  │  │agent│agent│  │   free   │
  -- │          │  │  1  │  2  │  │          │
  -- └──────────┘  └─────┴─────┘  └──────────┘
  ide = function(first_pane, mux_win, cwd)
    local tab2, pane2, _ = mux_win:spawn_tab({ cwd = cwd })
    pane2:split({ direction = 'Right', size = 0.5, cwd = cwd })
    mux_win:spawn_tab({ cwd = cwd })
    first_pane:activate()
  end,
}

--- ワークスペースが既に存在するか判定
local function workspace_exists(name)
  for _, ws in ipairs(wezterm.mux.get_workspace_names()) do
    if ws == name then return true end
  end
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
      table.insert(choices, {
        id = wt.path,
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

      local ws_name = context.workspace_name_from_label(label:gsub('^[^ ]+ ', ''))
      local already_exists = workspace_exists(ws_name)

      win:perform_action(act.SwitchToWorkspace {
        name = ws_name,
        spawn = { cwd = id },
      }, p)

      -- 新規ワークスペースの場合、レイアウトを構築
      if not already_exists then
        -- SwitchToWorkspace 完了後にレイアウトを適用
        wezterm.time.call_after(0.5, function()
          -- 切り替え先のワークスペースにいることを確認
          local mux_win = win:mux_window()
          if mux_win:get_workspace() ~= ws_name then return end
          local tabs = mux_win:tabs()
          if #tabs > 0 and #tabs[1]:panes() == 1 then
            local first_pane = tabs[1]:active_pane()
            local preset_name = project_layouts[ws_name] or 'default'
            local builder = layout_presets[preset_name] or layout_presets.default
            builder(first_pane, mux_win, id)
          end
        end)
      end
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
    local fmt = {}
    if is_current then
      table.insert(fmt, { Foreground = { Color = '#f5a97f' } })
      table.insert(fmt, { Text = wezterm.nerdfonts.fa_circle .. ' ' })
      table.insert(fmt, { Foreground = { Color = '#cad3f5' } })
      table.insert(fmt, { Attribute = { Intensity = 'Bold' } })
      table.insert(fmt, { Text = ws })
      table.insert(fmt, { Attribute = { Intensity = 'Normal' } })
      table.insert(fmt, { Foreground = { Color = '#6e738d' } })
      table.insert(fmt, { Text = '  (current)' })
    else
      table.insert(fmt, { Foreground = { Color = '#8bd5ca' } })
      table.insert(fmt, { Text = wezterm.nerdfonts.fa_circle_o .. ' ' })
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
      -- 対象ワークスペースの全ウィンドウ→全タブ→全ペインを閉じる
      for _, mux_win in ipairs(wezterm.mux.all_windows()) do
        if mux_win:get_workspace() == id then
          for _, tab in ipairs(mux_win:tabs()) do
            for _, tab_pane in ipairs(tab:panes()) do
              tab_pane:activate()
              win:perform_action(act.CloseCurrentPane { confirm = false }, tab_pane)
            end
          end
        end
      end
      window:toast_notification('workspace', id .. ' を削除しました', nil, 2000)
    end),
  }, pane)
end)

-- =============================================================================
-- タブ・ペインレイアウト
-- =============================================================================

-- 新規タブを8分割（4x2グリッド）で開くアクション（ホームディレクトリから）
M.spawn_tab_with_8_panes = wezterm.action_callback(function(window, pane)
  local tab, first_pane, _ = window:mux_window():spawn_tab({ cwd = wezterm.home_dir })

  -- パターン: 4x2 グリッド
  -- ┌───┬───┬───┬───┐
  -- │ 1 │ 2 │ 3 │ 4 │
  -- ├───┼───┼───┼───┤
  -- │ 5 │ 6 │ 7 │ 8 │
  -- └───┴───┴───┴───┘

  -- 上下に2分割
  local bottom_pane = first_pane:split({ direction = "Bottom", size = 0.5 })

  -- 上段を4列に分割（二分木方式: 常に0.5で分割し丸め誤差を最小化）
  local top_right_half = first_pane:split({ direction = "Right", size = 0.5 })
  first_pane:split({ direction = "Right", size = 0.5 })
  top_right_half:split({ direction = "Right", size = 0.5 })

  -- 下段を4列に分割
  local bottom_right_half = bottom_pane:split({ direction = "Right", size = 0.5 })
  bottom_pane:split({ direction = "Right", size = 0.5 })
  bottom_right_half:split({ direction = "Right", size = 0.5 })

  -- 左上ペインにフォーカス
  first_pane:activate()
end)

-- ワークスペース初期化アクション（Leader + i）
-- 前提: pane 1 が目的のディレクトリに cd 済み
-- 3ペイン時:
-- ┌────────┬────────┐
-- │ nvim   │ claude │
-- │  (1)   ├────────┤
-- │        │ free   │
-- │        │  (3)   │
-- └────────┴────────┘
-- 8ペイン時:
-- ┌───────┬───────┬───────┬───────┐
-- │claude │claude │ codex │gemini │
-- │  (1)  │  (2)  │  (3)  │  (4)  │
-- ├───────┼───────┼───────┼───────┤
-- │ tmux  │ tmux  │shell  │shell  │
-- │cc1(5) │cc2(6) │  (7)  │  (8)  │
-- └───────┴───────┴───────┴───────┘
M.init_workspace = wezterm.action_callback(function(window, pane)
  local tab = pane:tab()
  local panes_info = tab:panes_with_info()

  local pane_count = #panes_info
  local layout = nil
  if pane_count == 3 then
    layout = "3pane"
  elseif pane_count >= 8 then
    layout = "8pane"
  else
    wezterm.log_warn("init_workspace: 3または8ペインが必要です (現在: " .. pane_count .. ")")
    window:toast_notification("init_workspace", "3または8ペインが必要です (現在: " .. pane_count .. ")", nil, 3000)
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
    wezterm.log_warn("init_workspace: pane 1 の cwd を取得できません")
    return
  end
  cwd = cwd:gsub("/$", "")
  if cwd == "" then return end

  -- GHQ リポジトリ配下でのみ実行を許可
  local ghq_root = wezterm.home_dir .. "/ghq/"
  if cwd:sub(1, #ghq_root) ~= ghq_root then
    wezterm.log_warn("init_workspace: GHQ 配下ではありません: " .. cwd)
    window:toast_notification("init_workspace", "GHQ リポジトリ配下でのみ実行できます\ncwd: " .. cwd, nil, 4000)
    return
  end

  -- シェル引数のクォート
  local function sq(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
  end

  local max_panes = (layout == "3pane") and 3 or 8

  -- TUI プロセスが実行中のペインがないかチェック（二重起動防止）
  for i = 1, max_panes do
    if panes_info[i].pane:is_alt_screen_active() then
      wezterm.log_warn("init_workspace: ペイン " .. i .. " でプロセスが実行中です")
      window:toast_notification("init_workspace", "ペイン " .. i .. " でプロセスが実行中です\n先に終了してください", nil, 4000)
      return
    end
  end

  -- pane 2-*: pane 1 のディレクトリへ移動
  for i = 2, max_panes do
    panes_info[i].pane:send_text("cd " .. sq(cwd) .. "\n")
  end

  if layout == "3pane" then
    -- pane 1: Neovim
    panes_info[1].pane:send_text("nvim\n")

    -- pane 2: Claude Code
    panes_info[2].pane:send_text("claude\n")

    -- pane 3: Free（cd のみ）

    -- pane 1 にフォーカス
    panes_info[1].pane:activate()
    return
  end

  local project = context.get_project_name_from_path(cwd)
  if project == "" then
    project = "project"
  end
  project = project:gsub("[%.:]", "-")

  -- pane 1, 2: サブシェルの PID を保存し exec で claude に置換（PID = claude プロセス PID）
  panes_info[1].pane:send_text("sh -c 'echo $$ > /tmp/wez-cc1.pid; exec claude'\n")
  panes_info[2].pane:send_text("sh -c 'echo $$ > /tmp/wez-cc2.pid; exec claude'\n")

  -- pane 3: Codex
  panes_info[3].pane:send_text("codex\n")

  -- pane 4: Gemini
  panes_info[4].pane:send_text("gemini\n")

  -- pane 5: pane 1 の Claude Code が作成する tmux セッションに自動アタッチ
  panes_info[5].pane:send_text(
    "sleep 1 && CC_PID=$(cat /tmp/wez-cc1.pid 2>/dev/null) && "
    .. "SN=\"claude-" .. project .. "-${CC_PID}\" && "
    .. "until command tmux has-session -t \"$SN\" 2>/dev/null; do sleep 2; done && "
    .. "command tmux attach-session -t \"$SN\"\n"
  )

  -- pane 6: pane 2 の Claude Code が作成する tmux セッションに自動アタッチ
  panes_info[6].pane:send_text(
    "sleep 1 && CC_PID=$(cat /tmp/wez-cc2.pid 2>/dev/null) && "
    .. "SN=\"claude-" .. project .. "-${CC_PID}\" && "
    .. "until command tmux has-session -t \"$SN\" 2>/dev/null; do sleep 2; done && "
    .. "command tmux attach-session -t \"$SN\"\n"
  )

  -- pane 7, 8: そのまま（cd 済み）

  -- pane 1 にフォーカス
  panes_info[1].pane:activate()
end)

-- 新規タブを3分割で開くアクション（ホームディレクトリから）
M.spawn_tab_with_3_panes = wezterm.action_callback(function(window, pane)
  -- 新しいタブを作成（ホームディレクトリで開始）
  local tab, first_pane, _ = window:mux_window():spawn_tab({ cwd = wezterm.home_dir })

  -- パターン: 左1 + 右上下2
  -- ┌──────┬──────┐
  -- │      │  2   │
  -- │  1   ├──────┤
  -- │      │  3   │
  -- └──────┴──────┘

  -- 右側に縦分割（50%）
  local right_pane = first_pane:split({ direction = "Right", size = 0.5 })
  -- 右側ペインをさらに横分割（50%）→ 右上・右下に分かれる
  right_pane:split({ direction = "Bottom", size = 0.5 })
  -- 左ペインにフォーカス
  first_pane:activate()
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

-- チートシート表示（右ペインに glow で表示、q で閉じる）
M.show_cheatsheet = wezterm.action_callback(function(window, pane)
  local cheatsheet = wezterm.home_dir .. '/.config/nvim/docs/CHEATSHEET.md'
  local cheat_pane = pane:split({
    direction = 'Right',
    size = 0.4,
    args = { '/opt/homebrew/bin/glow', '-s', 'dracula', '-p', cheatsheet },
  })
  cheat_pane:activate()
end)

return M
