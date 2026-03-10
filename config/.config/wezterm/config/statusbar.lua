local wezterm = require("wezterm")

local M = {}

-- =============================================================================
-- カラーパレット（Tokyo Night Moon 公式カラー）
-- https://github.com/folke/tokyonight.nvim/blob/main/extras/lua/tokyonight_moon.lua
-- =============================================================================

local C = {
  blue = "#82aaff",
  cyan = "#86e1fc",
  teal = "#4fd6be",
  green = "#c3e88d",
  yellow = "#ffc777",
  purple = "#c099ff",
  fg = "#c8d3f5",
  fg_dark = "#828bb8",
  dark3 = "#394270",
  bg_dark = "#1e2030",
}

local MODE_STYLES = {
  copy_mode = { bg = C.yellow, label = "COPY" },
  pane_mode = { bg = C.green, label = "PANE" },
  search_mode = { bg = C.purple, label = "SEARCH" },
}

-- =============================================================================
-- ヘルパー関数
-- =============================================================================

local function get_project_name(pane)
  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return ""
  end
  local cwd = cwd_uri.file_path or ""
  return cwd:match("([^/]+)/?$") or ""
end

local function get_process(pane)
  local name = pane:get_foreground_process_name() or ""
  return name:match("([^/]+)$") or ""
end

-- =============================================================================
-- ステータスバー構築
-- =============================================================================

function M.setup()
  wezterm.on("update-status", function(window, pane)
    local workspace = window:active_workspace()
    local key_table = window:active_key_table()
    local mode = MODE_STYLES[key_table]

    local project = get_project_name(pane)
    local process = get_process(pane)
    local datetime = wezterm.strftime("%m/%d %H:%M")

    -- ===================== 左ステータス =====================
    -- モード表示のみ（COPY / PANE / SEARCH）

    local left = {}

    if mode then
      table.insert(left, { Background = { Color = mode.bg } })
      table.insert(left, { Foreground = { Color = C.bg_dark } })
      table.insert(left, { Attribute = { Intensity = "Bold" } })
      table.insert(left, { Text = "  " .. mode.label .. "  " })
      table.insert(left, { Background = { Color = "none" } })
      table.insert(left, { Text = "" })
    end

    window:set_left_status(wezterm.format(left))

    -- ===================== 右ステータス =====================
    -- [teal: workspace ][dark3: process | project ][blue: datetime ]

    local right = {}

    -- ワークスペース名（"default" 以外のとき表示）
    if workspace ~= "default" then
      table.insert(right, { Background = { Color = C.teal } })
      table.insert(right, { Foreground = { Color = C.bg_dark } })
      table.insert(right, { Attribute = { Intensity = "Bold" } })
      table.insert(right, { Text = "  " .. workspace .. "  " })
    end

    -- プロセス名 + プロジェクト名ブロック
    local mid_parts = {}
    if process ~= "" then
      table.insert(mid_parts, process)
    end
    if project ~= "" then
      table.insert(mid_parts, project)
    end

    if #mid_parts > 0 then
      table.insert(right, { Background = { Color = C.dark3 } })
      table.insert(right, { Foreground = { Color = C.fg } })
      table.insert(right, { Attribute = { Intensity = "Normal" } })
      table.insert(right, { Text = "  " .. table.concat(mid_parts, "  |  ") .. "  " })
    end

    -- 日時ブロック（右端アクセント）
    table.insert(right, { Background = { Color = C.blue } })
    table.insert(right, { Foreground = { Color = C.bg_dark } })
    table.insert(right, { Attribute = { Intensity = "Bold" } })
    table.insert(right, { Text = "  " .. datetime .. "  " })

    window:set_right_status(wezterm.format(right))
  end)
end

return M
