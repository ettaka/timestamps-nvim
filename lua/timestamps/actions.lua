local M = {}

M.get_timestamp = function (ts_ask)
  local local_tz_suffix = require('timestamps.parser').local_tz_suffix
  local ts = os.date("%Y-%m-%dT%H:%M", ts_ask) .. local_tz_suffix()
  return ts
end

M.get_timestamp_now = function ()
  local local_tz_suffix = require('timestamps.parser').local_tz_suffix
  local ts = os.date("%Y-%m-%dT%H:%M") .. local_tz_suffix()
  return ts
end

M.paste_timestamp_now  = function ()
  local ts = M.get_timestamp_now()
  vim.api.nvim_put({ ts }, "c", true, true)
end

return M
