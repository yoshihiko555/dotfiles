-- 使い方:
--   local baton = require 'config/baton-status'
--   baton.setup({
--     bin = '/path/to/baton',             -- 必須: baton バイナリのパス
--     path = '/tmp/baton-status.json',    -- 省略可: ステータス JSON のパス
--   })

local M = {}
local wezterm = require 'wezterm'

-- 状態ファイル読み取り結果の短期キャッシュ
local cache = { data = nil, last_read = 0 }

local CACHE_TTL_SECONDS = 2
local DEFAULT_STATUS_PATH = '/tmp/baton-status.json'

local function now_seconds()
  return os.time()
end

function M.read_status(path)
  path = path or DEFAULT_STATUS_PATH

  -- 直近読み取りから TTL 以内ならファイル再読込を避ける
  local now = now_seconds()
  if cache.data ~= nil and (now - cache.last_read) < CACHE_TTL_SECONDS then
    return cache.data
  end

  local file = io.open(path, 'r')
  if not file then
    return nil
  end

  local content = file:read('*a')
  file:close()

  if not content or content == '' then
    return nil
  end

  -- JSON の破損で落ちないように pcall で保護
  local ok, parsed = pcall(wezterm.json_parse, content)
  if not ok or type(parsed) ~= 'table' then
    return nil
  end

  -- 正常時のみキャッシュ更新
  cache.data = parsed
  cache.last_read = now
  return parsed
end

function M.format_status(data)
  -- データなし
  if not data then
    return wezterm.format({
      { Foreground = { Color = '#808080' } },
      { Text = 'baton: no data' },
    })
  end

  -- v2 フォーマットのみ対応（バージョン不一致は unknown format として表示）
  if data.version ~= 2 then
    return wezterm.format({
      { Foreground = { Color = '#888888' } },
      { Text = 'baton: unknown format' },
    })
  end

  local text = data.formatted_status or ''
  local waiting = (data.summary or {}).waiting or 0

  -- waiting セッションがある場合はオレンジ色で強調表示
  if waiting > 0 then
    return wezterm.format({
      { Foreground = { Color = '#FF8800' } },
      { Text = text },
      'ResetAttributes',
    })
  end

  return wezterm.format({
    { Text = text },
    'ResetAttributes',
  })
end

function M.setup(config)
  config = config or {}
end

return M
