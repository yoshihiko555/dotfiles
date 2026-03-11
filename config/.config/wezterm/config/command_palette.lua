local wezterm = require 'wezterm'
local act = wezterm.action
local actions = require 'config/actions'

local M = {}

local function entry(brief, action)
  return {
    brief = brief,
    action = action,
  }
end

function M.setup()
  wezterm.on('augment-command-palette', function(_window, _pane)
    return {
      entry('Workspace: Open Project', actions.select_project),
      entry('Workspace: Switch Workspace', actions.switch_workspace),
      entry('Workspace: Delete Workspace', actions.delete_workspace),
      entry('Workspace: Initialize Current Layout', actions.init_workspace),

      entry('Tab: New 3-Pane Tab', actions.spawn_tab_with_3_panes),
      entry('Tab: New 8-Pane Tab', actions.spawn_tab_with_8_panes),

      entry('Pane: Enter Pane Mode', act.ActivateKeyTable { name = 'pane_mode', one_shot = false }),
      entry('Overlay: Open Lazygit', actions.overlay_lazygit),
      entry('Overlay: Open Yazi', actions.overlay_yazi),
      entry('Overlay: Open Claude Code', actions.overlay_claude),
      entry('Overlay: Open Temporary Shell', actions.open_bottom_shell),

      entry('Utility: Show Cheatsheet', actions.show_cheatsheet),
      entry('Utility: Clear Screen (Keep Scrollback)', actions.clear_screen_save_scrollback),
      entry('Utility: Clear Scrollback and Viewport', actions.clear_scrollback_and_viewport),
    }
  end)
end

return M
