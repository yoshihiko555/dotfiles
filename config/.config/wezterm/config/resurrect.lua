local wezterm = require("wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

local M = {}

function M.setup()
  -- ペインテキストは保存しない（パフォーマンス優先）
  resurrect.state_manager.set_max_nlines(0)

  -- 5分間隔で workspace 状態を自動保存（window/tab は不要）
  resurrect.state_manager.periodic_save({
    interval_seconds = 300,
    save_workspaces = true,
    save_windows = false,
    save_tabs = false,
  })
end

--- Leader+r: 保存済みワークスペースを fuzzy 選択して復元
M.restore_state = wezterm.action_callback(function(win, pane)
  resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
    local type = string.match(id, "^([^/]+)")
    id = string.match(id, "([^/]+)$")
    id = string.match(id, "(.+)%.%..+$")
    local opts = {
      relative = true,
      restore_text = false,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
    if type == "workspace" then
      local state = resurrect.state_manager.load_state(id, "workspace")
      resurrect.workspace_state.restore_workspace(state, opts)
    elseif type == "window" then
      local state = resurrect.state_manager.load_state(id, "window")
      resurrect.window_state.restore_window(pane:window(), state, opts)
    elseif type == "tab" then
      local state = resurrect.state_manager.load_state(id, "tab")
      resurrect.tab_state.restore_tab(pane:tab(), state, opts)
    end
  end)
end)

--- Leader+R: 保存済み状態を fuzzy 選択して削除
M.delete_state = wezterm.action_callback(function(win, pane)
  resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
    resurrect.state_manager.delete_state(id)
  end, {
    title = "Delete State",
    description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
    fuzzy_description = "Search State to Delete: ",
    is_fuzzy = true,
  })
end)

return M
