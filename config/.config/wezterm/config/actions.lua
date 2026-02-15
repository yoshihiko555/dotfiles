local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

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
-- 前提: 8ペインタブで pane 1 が目的のディレクトリに cd 済み
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

return M
