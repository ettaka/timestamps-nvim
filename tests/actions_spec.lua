-- timestamps.actions: producing timestamps that parse_iso reads back.
local H = require("tests.helpers")
local t = H.suite()
local A = require("timestamps.actions")
local P = require("timestamps.parser")

local fixed_zones = {
  { "UTC",        "2026-01-15T10:00Z" },
  { "Etc/GMT-2",  "2026-01-15T12:00H" },
  { "Asia/Tokyo", "2026-01-15T19:00+09:00" },
}
for _, c in ipairs(fixed_zones) do
  t.test("get_timestamp formats local time + suffix in " .. c[1], function()
    H.eq(H.eval_in_tz(c[1], "require('timestamps.actions').get_timestamp(1768471200)"), c[2])
  end)
end

t.test("get_timestamp_now round-trips through parse_iso (to the minute)", function()
  local now = os.time()
  local parsed = P.parse_iso(A.get_timestamp_now())
  H.ok(parsed, "get_timestamp_now() output did not parse")
  H.ok(math.abs(parsed - (now - now % 60)) <= 60, ("off by %ds"):format(parsed - now))
end)

-- get_timestamp(ts) must use the offset in effect at ts, not now: in a DST zone one of these
-- dates is always in the other half of the year from "now".
t.test("get_timestamp round-trips for dates in both DST halves", function()
  for _, ts in ipairs({ H.local_ts(2026, 1, 15, 10, 0), H.local_ts(2026, 7, 15, 10, 0) }) do
    H.eq(P.parse_iso(A.get_timestamp(ts)), ts, A.get_timestamp(ts))
  end
end)

t.test("get_timestamp uses the offset of the date it formats (Helsinki)", function()
  H.eq(A.get_timestamp(H.local_ts(2026, 1, 15, 10, 0)), "2026-01-15T10:00H")
  H.eq(A.get_timestamp(H.local_ts(2026, 7, 15, 10, 0)), "2026-07-15T10:00S")
end)

t.test("get_timestamp is correct on both sides of the clock changes", function()
  -- 2026-03-29 03:00 -> 04:00 and 2026-10-25 04:00 -> 03:00 in Helsinki
  for _, c in ipairs({ { 3, 29, 2, 30 }, { 3, 29, 4, 30 }, { 10, 24, 9, 0 }, { 10, 25, 9, 0 } }) do
    local ts = H.local_ts(2026, c[1], c[2], c[3], c[4])
    H.eq(P.parse_iso(A.get_timestamp(ts)), ts, A.get_timestamp(ts))
  end
end)

t.test("paste_timestamp_now inserts after the cursor", function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "ab" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  A.paste_timestamp_now()
  local line = vim.api.nvim_get_current_line()
  H.ok(line:match("^a%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d[%w%+%-:]+b$"), line)
end)

---------------------------------------------------------------- keymaps
local function mapped(mode) return vim.fn.maparg("<leader>ts", mode) ~= "" end
local function fresh_plugin()
  H.unload("timestamps")
  for _, mode in ipairs({ "n", "i", "t" }) do pcall(vim.keymap.del, mode, "<leader>ts") end
  return require("timestamps")
end

t.test("plugin file maps <leader>ts in normal, insert and terminal mode by default", function()
  fresh_plugin()
  vim.cmd.source(H.root .. "/plugin/timestamps.lua")
  H.eq({ mapped("n"), mapped("i"), mapped("t") }, { true, true, true })
end)

t.test("setup{insert_mappings=false} before the plugin loads: normal mode only", function()
  fresh_plugin().setup({ insert_mappings = false })
  vim.cmd.source(H.root .. "/plugin/timestamps.lua")
  H.eq({ mapped("n"), mapped("i"), mapped("t") }, { true, false, false })
end)

t.test("setup{insert_mappings=false} after the plugin loaded removes the insert maps", function()
  local ts = fresh_plugin()
  vim.cmd.source(H.root .. "/plugin/timestamps.lua")
  ts.setup({ insert_mappings = false })
  H.eq({ mapped("n"), mapped("i"), mapped("t") }, { true, false, false })
end)

return t
