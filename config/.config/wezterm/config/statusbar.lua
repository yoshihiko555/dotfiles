local wezterm = require("wezterm")
local context = require("config/context")

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

local function push_gap(parts)
  if #parts == 0 then
    return
  end
  table.insert(parts, { Background = { Color = "none" } })
  table.insert(parts, { Text = " " })
end

local function get_workspace_icon(workspace)
  if workspace:find(":") then
    return wezterm.nerdfonts.cod_git_merge
  end
  return wezterm.nerdfonts.oct_repo
end

-- =============================================================================
-- ステータスバー構築（キャッシュ付き）
-- =============================================================================

-- 前回の入力値と描画結果をキャッシュし、変化がなければ再描画をスキップする
local cache = {
  workspace = nil,
  key_table = nil,
  datetime = nil,
  left = "",
  right = "",
}

local function build_left(mode)
  local left = {}
  if mode then
    table.insert(left, { Background = { Color = mode.bg } })
    table.insert(left, { Foreground = { Color = C.bg_dark } })
    table.insert(left, { Attribute = { Intensity = "Bold" } })
    table.insert(left, { Text = "  " .. mode.label .. "  " })
    table.insert(left, { Background = { Color = "none" } })
    table.insert(left, { Text = "" })
  end
  return wezterm.format(left)
end

local function build_right(workspace, datetime)
  local right = {}

  if workspace ~= "default" then
    local workspace_icon = get_workspace_icon(workspace)
    table.insert(right, { Background = { Color = C.bg_dark } })
    table.insert(right, { Foreground = { Color = C.teal } })
    table.insert(right, { Attribute = { Intensity = "Bold" } })
    table.insert(right, { Text = "  " .. workspace_icon .. "" })
    table.insert(right, { Foreground = { Color = C.fg } })
    table.insert(right, { Text = "" .. workspace .. "  " })
  end

  push_gap(right)
  table.insert(right, { Background = { Color = C.blue } })
  table.insert(right, { Foreground = { Color = C.bg_dark } })
  table.insert(right, { Attribute = { Intensity = "Bold" } })
  table.insert(right, { Text = "  " .. wezterm.nerdfonts.cod_calendar .. " " .. datetime .. "  " })

  return wezterm.format(right)
end

function M.setup()
  wezterm.on("update-status", function(window, _pane)
    local workspace = context.get_workspace_name(window)
    local key_table = window:active_key_table()
    local datetime = wezterm.strftime("%m/%d %H:%M")

    -- 入力が前回と同じならスキップ
    if workspace == cache.workspace
      and key_table == cache.key_table
      and datetime == cache.datetime
    then
      return
    end

    -- 変化した部分だけ再構築
    if key_table ~= cache.key_table then
      cache.left = build_left(MODE_STYLES[key_table])
    end

    if workspace ~= cache.workspace or datetime ~= cache.datetime then
      cache.right = build_right(workspace, datetime)
    end

    cache.workspace = workspace
    cache.key_table = key_table
    cache.datetime = datetime

    window:set_left_status(cache.left)
    window:set_right_status(cache.right)
  end)
end

return M
