local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

-- 新規タブを8分割（4x2グリッド）で開くアクション（ホームディレクトリから）
local spawn_tab_with_8_panes = wezterm.action_callback(function(window, pane)
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
-- 前提: 8ペインタブで pane 1 が目的のディレクトリに cd 済み
-- ┌───────┬───────┬───────┬───────┐
-- │claude │claude │ codex │gemini │
-- │  (1)  │  (2)  │  (3)  │  (4)  │
-- ├───────┼───────┼───────┼───────┤
-- │ tmux  │ tmux  │shell  │shell  │
-- │cc1(5) │cc2(6) │  (7)  │  (8)  │
-- └───────┴───────┴───────┴───────┘
local init_workspace = wezterm.action_callback(function(window, pane)
  local tab = pane:tab()
  local panes_info = tab:panes_with_info()

  if #panes_info < 8 then
    wezterm.log_warn("init_workspace: 8ペインが必要です (現在: " .. #panes_info .. ")")
    return
  end

  -- ペインを位置順にソート（上→下、左→右）
  table.sort(panes_info, function(a, b)
    if a.top ~= b.top then return a.top < b.top end
    return a.left < b.left
  end)

  -- pane 1 の cwd を取得
  local cwd_url = panes_info[1].pane:get_current_working_dir()
  if not cwd_url then
    wezterm.log_warn("init_workspace: pane 1 の cwd を取得できません")
    return
  end
  local cwd = (cwd_url.file_path or ""):gsub("/$", "")
  if cwd == "" then return end

  local project = (cwd:match("([^/]+)$") or "project"):gsub("[%.:]", "-")

  -- シェル引数のクォート
  local function sq(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
  end

  -- pane 2-8: pane 1 のディレクトリへ移動
  for i = 2, 8 do
    panes_info[i].pane:send_text("cd " .. sq(cwd) .. "\n")
  end

  -- pane 1, 2: Shell PID を保存して Claude Code 起動
  panes_info[1].pane:send_text("echo $$ > /tmp/wez-cc1.pid && claude\n")
  panes_info[2].pane:send_text("echo $$ > /tmp/wez-cc2.pid && claude\n")

  -- pane 3: Codex
  panes_info[3].pane:send_text("codex\n")

  -- pane 4: Gemini
  panes_info[4].pane:send_text("gemini\n")

  -- pane 5: pane 1 の Claude Code に紐づく tmux セッション（PID 監視用）
  panes_info[5].pane:send_text(
    "sleep 1 && command tmux kill-session -t " .. sq(project .. "-cc1") .. " 2>/dev/null; "
    .. "export CLAUDE_SHELL_PID=$(cat /tmp/wez-cc1.pid 2>/dev/null) && "
    .. "command tmux new-session -s " .. sq(project .. "-cc1")
    .. " -c " .. sq(cwd) .. "\n"
  )

  -- pane 6: pane 2 の Claude Code に紐づく tmux セッション（PID 監視用）
  panes_info[6].pane:send_text(
    "sleep 1 && command tmux kill-session -t " .. sq(project .. "-cc2") .. " 2>/dev/null; "
    .. "export CLAUDE_SHELL_PID=$(cat /tmp/wez-cc2.pid 2>/dev/null) && "
    .. "command tmux new-session -s " .. sq(project .. "-cc2")
    .. " -c " .. sq(cwd) .. "\n"
  )

  -- pane 7, 8: そのまま（cd 済み）

  -- pane 1 にフォーカス
  panes_info[1].pane:activate()
end)

-- 新規タブを3分割で開くアクション（ホームディレクトリから）
local spawn_tab_with_3_panes = wezterm.action_callback(function(window, pane)
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
local clear_screen_save_scrollback = wezterm.action_callback(function(window, pane)
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
local clear_scrollback_and_viewport = wezterm.action_callback(function(window, pane)
  window:perform_action(act.ClearScrollback 'ScrollbackAndViewport', pane)
end)

return {
  -- デフォルトのキーバインド無効化
  disable_default_key_bindings = true,
  -- リーダーキー設定
  leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 },
  keys = {
    ---------------------------------------------------------------------------
    -- タブ操作
    ---------------------------------------------------------------------------
    { key = 't', mods = 'SUPER', action = spawn_tab_with_3_panes },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentPane{ confirm = true } },
    { key = 'w', mods = 'SUPER|SHIFT', action = act.CloseCurrentTab{ confirm = true } },
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = '{', mods = 'SUPER', action = act.ActivateTabRelative(-1) },
    { key = '}', mods = 'SUPER', action = act.ActivateTabRelative(1) },
    -- タブ番号で直接移動 (Cmd + 1-9)
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },
    -- タブ移動
    { key = 'PageUp', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(-1) },
    { key = 'PageDown', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(1) },

    ---------------------------------------------------------------------------
    -- ペイン操作 (Cmd)
    ---------------------------------------------------------------------------
    { key = 'd', mods = 'SUPER', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = 'z', mods = 'CTRL', action = act.TogglePaneZoomState },
    -- 矢印キーでペイン移動・サイズ調整
    { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Down' },
    { key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Left', 1 } },
    { key = 'RightArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Right', 1 } },
    { key = 'UpArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Up', 1 } },
    { key = 'DownArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Down', 1 } },

    ---------------------------------------------------------------------------
    -- ペイン操作 (Leader: Ctrl+q)
    ---------------------------------------------------------------------------
    -- 8分割タブ
    { key = '8', mods = 'LEADER', action = spawn_tab_with_8_panes },
    -- ワークスペース初期化（8ペインタブで pane 1 の cwd を基準に各ツール起動）
    { key = 'i', mods = 'LEADER', action = init_workspace },
    -- 分割
    { key = 'd', mods = 'LEADER', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = '/', mods = 'LEADER', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    -- 移動 (vim風・単発)
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
    -- サイズ調整 (単発)
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Left', 5 } },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Down', 5 } },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Up', 5 } },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Right', 5 } },
    -- ペイン操作モード (連続操作)
    { key = 'p', mods = 'LEADER', action = act.ActivateKeyTable{ name = 'pane_mode', one_shot = false } },

    ---------------------------------------------------------------------------
    -- コピー・ペースト
    ---------------------------------------------------------------------------
    { key = 'c', mods = 'SUPER', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },
    { key = 'Copy', mods = 'NONE', action = act.CopyTo 'Clipboard' },
    { key = 'Paste', mods = 'NONE', action = act.PasteFrom 'Clipboard' },

    ---------------------------------------------------------------------------
    -- 検索・選択
    ---------------------------------------------------------------------------
    { key = 'f', mods = 'SUPER', action = act.Search 'CurrentSelectionOrEmptyString' },
    { key = 'x', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    { key = 'phys:Space', mods = 'SHIFT|CTRL', action = act.QuickSelect },
    { key = 'u', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' } },

    ---------------------------------------------------------------------------
    -- フォントサイズ
    ---------------------------------------------------------------------------
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },

    ---------------------------------------------------------------------------
    -- スクロール
    ---------------------------------------------------------------------------
    { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
    { key = 'k', mods = 'SUPER', action = clear_scrollback_and_viewport },
    -- Ctrl+L: 画面クリア（スクロールバックに内容を保存）
    { key = 'l', mods = 'CTRL', action = clear_screen_save_scrollback },

    ---------------------------------------------------------------------------
    -- ウィンドウ・アプリケーション
    ---------------------------------------------------------------------------
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'h', mods = 'SUPER', action = act.HideApplication },
    { key = 'm', mods = 'SUPER', action = act.Hide },
    { key = 'q', mods = 'SUPER', action = act.QuitApplication },

    ---------------------------------------------------------------------------
    -- その他
    ---------------------------------------------------------------------------
    { key = 'Enter', mods = 'SHIFT', action = act.SendString '\n' },
    { key = 'r', mods = 'SUPER', action = act.ReloadConfiguration },
    { key = 'p', mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
    { key = 'l', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
  },

  ---------------------------------------------------------------------------
  -- Key Tables
  ---------------------------------------------------------------------------
  key_tables = {
    -- ペイン操作モード (Leader + p で入る)
    pane_mode = {
      { key = 'h', mods = 'NONE', action = act.ActivatePaneDirection 'Left' },
      { key = 'j', mods = 'NONE', action = act.ActivatePaneDirection 'Down' },
      { key = 'k', mods = 'NONE', action = act.ActivatePaneDirection 'Up' },
      { key = 'l', mods = 'NONE', action = act.ActivatePaneDirection 'Right' },
      { key = 'H', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Left', 5 } },
      { key = 'J', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Down', 5 } },
      { key = 'K', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Up', 5 } },
      { key = 'L', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Right', 5 } },
      { key = 'd', mods = 'NONE', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
      { key = '/', mods = 'NONE', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
      { key = 'x', mods = 'NONE', action = act.CloseCurrentPane{ confirm = true } },
      { key = 'z', mods = 'NONE', action = act.TogglePaneZoomState },
      { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
      { key = 'Enter', mods = 'NONE', action = act.PopKeyTable },
      { key = 'q', mods = 'NONE', action = act.PopKeyTable },
    },

    -- コピーモード (vim風)
    copy_mode = {
      -- 終了
      { key = 'Escape', mods = 'NONE', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      { key = 'q', mods = 'NONE', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      { key = 'c', mods = 'CTRL', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      -- 移動
      { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },
      { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
      { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
      -- ページ移動
      { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
      { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
      { key = 'd', mods = 'CTRL', action = act.CopyMode{ MoveByPage = 0.5 } },
      { key = 'u', mods = 'CTRL', action = act.CopyMode{ MoveByPage = -0.5 } },
      -- ジャンプ
      { key = 'f', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = false } } },
      { key = 'F', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 't', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = true } } },
      { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
      { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
      -- 選択
      { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Cell' } },
      { key = 'V', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Line' } },
      { key = 'v', mods = 'CTRL', action = act.CopyMode{ SetSelectionMode = 'Block' } },
      { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
      { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      -- コピー
      { key = 'y', mods = 'NONE', action = act.Multiple{ { CopyTo = 'ClipboardAndPrimarySelection' }, { Multiple = { 'ScrollToBottom', { CopyMode = 'Close' } } } } },
      -- 矢印キー
      { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
    },

    -- 検索モード
    search_mode = {
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
      { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
      { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
      { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
    },
  },
}
