local wezterm = require 'wezterm'
local act = wezterm.action
local actions = require 'config/actions'
local layouts = require 'config/layouts'

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
      entry('Layout: Initialize Panes', layouts.init_panes),
      entry('Layout: Split to 2 Panes', layouts.split_to(2)),
      entry('Layout: Split to 3 Panes', layouts.split_to(3)),
      entry('Layout: Split to 4 Panes', layouts.split_to(4)),

      entry('Pane: Enter Pane Mode', act.ActivateKeyTable { name = 'pane_mode', one_shot = false }),
      entry('Overlay: Open Lazygit', actions.overlay_lazygit),
      entry('Overlay: Open Yazi', actions.overlay_yazi),
      entry('Overlay: Open Claude Code', actions.overlay_claude),
      entry('Overlay: Open Temporary Shell', actions.open_bottom_shell),

      entry('Utility: Show Neovim Cheatsheet', actions.show_cheatsheet),
      entry('Utility: Show WezTerm Cheatsheet', actions.show_wezterm_cheatsheet),
      entry('Utility: Clear Screen (Keep Scrollback)', actions.clear_screen_save_scrollback),
      entry('Utility: Clear Scrollback and Viewport', actions.clear_scrollback_and_viewport),
    }
  end)
end

return M
