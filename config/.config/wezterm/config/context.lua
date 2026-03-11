local M = {}

-- pane / window から取得する名前まわりの helper を集約する。
-- tab / statusbar / actions で同じ表記ルールを再利用する前提。

local function basename(path)
  if not path or path == "" then
    return ""
  end

  return tostring(path):match("([^/]+)$") or tostring(path)
end

local function try_call(method)
  local ok, result = pcall(method)
  if ok then
    return result
  end

  return nil
end

-- CLI ごとの実体名や alias を UI 表示用の短いラベルへ寄せる。
function M.normalize_process_label(label)
  if not label or label == "" then
    return ""
  end

  if label == "lg" then
    return "lazygit"
  end

  if label:match("^codex") then
    return "codex"
  end

  if label:match("^claude") then
    return "claude"
  end

  return label
end

-- pane API の差異を吸収して cwd の file_path を返す。
function M.get_cwd_path(pane)
  if not pane then
    return nil
  end

  local cwd_url = try_call(function()
    return pane:get_current_working_dir()
  end)

  if cwd_url == nil then
    cwd_url = pane.current_working_dir
  end

  return cwd_url and cwd_url.file_path or nil
end

-- パス末尾のディレクトリ名を project 名として扱う。
function M.get_project_name_from_path(path)
  if not path or path == "" then
    return ""
  end

  local normalized = tostring(path):gsub("/$", "")
  return normalized:match("([^/]+)$") or normalized
end

-- pane の cwd から project 名を解決する。
function M.get_project_name(pane)
  return M.get_project_name_from_path(M.get_cwd_path(pane))
end

-- foreground_process_name から UI 用の process 名を返す。
function M.get_process_name(pane)
  local process_name = ""

  if pane then
    process_name = try_call(function()
      return pane:get_foreground_process_name()
    end) or ""

    if process_name == "" then
      process_name = pane.foreground_process_name or ""
    end
  end

  return M.normalize_process_label(basename(process_name))
end

-- pane.title も process 名と同じ正規化を通して表記ゆれを減らす。
function M.get_pane_title(pane)
  if not pane then
    return ""
  end

  return M.normalize_process_label(pane.title or "")
end

-- GUI window / mux window のどちらからでも workspace 名を引けるようにする。
function M.get_workspace_name(window)
  if not window then
    return ""
  end

  local workspace = try_call(function()
    return window:active_workspace()
  end)
  if workspace ~= nil then
    return workspace or ""
  end

  local mux_window = try_call(function()
    return window:mux_window()
  end)
  if mux_window then
    workspace = try_call(function()
      return mux_window:get_workspace()
    end)
    if workspace ~= nil then
      return workspace or ""
    end
  end

  return ""
end

-- repo-list の表示ラベルから workspace 名を復元する。
-- worktree は "repo:branch"、通常 repo は末尾ディレクトリ名を使う。
function M.workspace_name_from_label(label)
  if not label or label == "" then
    return ""
  end

  if label:find(":") then
    local repo_part, branch = label:match(".-/([^/]+):(.+)$")
    if repo_part and branch then
      return repo_part .. ":" .. branch
    end
  end

  return label:match("([^/]+)$") or label
end

return M
