local M = {}

function M.date_str(state)
  return string.format("%04d-%02d-%02d", state.year, state.month, state.day)
end

function M.paste_timestamp(state, origin_win, origin_buf, win, local_tz_suffix)
  return_to_origin(origin_win, origin_buf)
  local ts = date_str(state) .. "T" .. os.date("%H:%M") .. local_tz_suffix
  vim.api.nvim_put({ ts }, "c", true, true)
  M.close(win)
end

M.paste_timestamp_now  = function (win, local_tz_suffix)
  local ts = os.date("%Y-%m-%dT%H:%M") .. local_tz_suffix
  vim.api.nvim_put({ ts }, "c", true, true)
  M.close(win)
end

return M
