local wezterm = require("wezterm")

local M = {}

-- タブバーの基本設定
M.config = {
  -- 新規タブボタンを非表示
  show_new_tab_button_in_tab_bar = false,
  -- タブの閉じるボタンを非表示
  show_close_tab_button_in_tabs = false,
  -- タブバーを下部に配置（お好みで true: 下部 / false: 上部）
  tab_bar_at_bottom = false,
  -- タブの最大幅
  tab_max_width = 32,
  -- タブが1つの時もタブバーを表示(お好みで true: 非表示 / false: 表示)
  hide_tab_bar_if_only_one_tab = true,
}

-- 長い文字列を末尾n文字に省略する関数
local function truncate_left(str, max_len)
  if #str <= max_len then
    return str
  else
    return "…" .. string.sub(str, -(max_len - 1))
  end
end

-- プロセス名を取得する関数
local function get_process_name(pane)
  local process_name = pane.foreground_process_name or ""
  return process_name:match("([^/]+)$") or ""
end

-- カレントディレクトリからプロジェクト名を取得する関数
local function get_project_name(pane)
  local cwd_uri = pane.current_working_dir
  if cwd_uri then
    local cwd = cwd_uri.file_path or ""
    -- パスの最後のディレクトリ名を取得
    local project_name = cwd:match("([^/]+)/?$")
    if project_name and project_name ~= "" then
      return project_name
    end
  end
  -- フォールバック: paneのタイトルを使用
  return pane.title
end

-- タブタイトルを取得する関数
local function get_tab_title(pane)
  local process_name = get_process_name(pane)

  -- シェル以外のプロセスが実行中の場合はプロセス名を表示
  local shell_names = { "zsh", "bash", "fish", "sh", "pwsh", "powershell" }
  for _, shell in ipairs(shell_names) do
    if process_name == shell then
      -- シェルの場合はプロジェクト名を表示
      return get_project_name(pane)
    end
  end

  -- シェル以外のプロセス（vim, node, make等）はプロセス名を表示
  if process_name ~= "" then
    return process_name
  end

  return get_project_name(pane)
end

function M.setup()
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
    local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

    -- 色の設定
    local edge_background = "none"
    local background
    local foreground = "#FFFFFF"

    if tab.is_active then
      background = "#3BC1A8" -- アクティブなタブ
    elseif hover then
      background = "#007A8A" -- ホバー時
    else
      background = "#005461" -- 非アクティブなタブ
    end

    local edge_foreground = background

    -- タブタイトルを取得（プロセス名またはプロジェクト名）
    local title = get_tab_title(tab.active_pane)
    title = truncate_left(title, max_width - 6)  -- 短縮表示

    -- イトル形式
    local formatted_title = "   " .. title .. "   "

    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = formatted_title },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_RIGHT_ARROW },
    }
  end)
end

return M
