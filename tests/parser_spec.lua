-- timestamps.parser: parse_iso is the format contract for every due::/done::/old:: tag in the notes.
-- Expected epochs were computed independently (Python calendar.timegm), not with this code.
local H = require("tests.helpers")
local t = H.suite()
local P = require("timestamps.parser")

local valid = {
  -- input                       expected UTC epoch   what
  { "2026-01-15T10:00Z",         1768471200, "Z = UTC" },
  { "2026-07-15T10:00Z",         1784109600, "Z in summer" },
  { "2026-01-15T10:00H",         1768464000, "H = HOME_TZ +02:00" },
  { "2026-07-15T10:00S",         1784098800, "S = HOME_SUMMER_TZ +03:00" },
  { "2026-01-15T10:00S",         1768460400, "S is +03:00 also in winter" },
  { "2026-01-15T10:00-05:00",    1768489200, "negative offset" },
  { "2026-01-15T10:00+05:30",    1768451400, "half-hour offset" },
  { "2026-07-15T10:00+03:00",    1784098800, "positive offset, summer" },
  { "2028-02-29T12:00Z",         1835438400, "leap day" },
  { "2026-03-29T01:30Z",         1774747800, "Helsinki spring-forward instant" },
  { "2026-10-25T00:30Z",         1792888200, "Helsinki fall-back hour" },
  { "2026-01-15T10:00Z).",       1768471200, "trailing punctuation is ignored" },
  { "2026-01-15T10:00Z,",        1768471200, "trailing comma is ignored" },
  -- 23:xx local time in Helsinki summer time used to be rejected (os.time read it as standard time, a day later)
  { "2026-09-30T23:20+03:00",    1790799600, "23:20 with an offset, in Helsinki summer time" },
  { "2026-07-15T23:59S",         1784149140, "23:59 S in summer" },
  { "2026-03-29T03:30+03:00",    1774744200, "hour skipped by Helsinki spring-forward" },
  { "2026-10-25T00:30+03:00",    1792877400, "night before Helsinki fall-back" },
  { "2026-12-31T23:59+02:00",    1798754340, "last minute of the year" },
  { "2026-01-01T00:00-01:00",    1767229200, "midnight with a negative offset" },
}
for _, c in ipairs(valid) do
  t.test("parse_iso " .. c[3] .. " (" .. c[1] .. ")", function()
    H.eq(P.parse_iso(c[1]), c[2])
  end)
end

-- Current behaviour, pinned on purpose: H is a fixed +02:00 even in Finnish summer time (+03:00).
-- If the meaning of H changes (see known issue 7 in the PKB guide), change this test with it.
t.test("parse_iso H is fixed +02:00 also in summer (pinned behaviour)", function()
  H.eq(P.parse_iso("2026-07-15T10:00H"), 1784102400)
end)

-- The result must not depend on the zone Neovim runs in.
for _, tz in ipairs({ "UTC", "Europe/Helsinki", "America/New_York", "Asia/Kolkata", "Pacific/Auckland" }) do
  t.test("parse_iso gives the same epochs with TZ=" .. tz, function()
    local inputs = vim.tbl_map(function(c) return ("%q"):format(c[1]) end, valid)
    local got = H.eval_in_tz(tz, ("table.concat(vim.tbl_map(function(s) return tostring(require('timestamps.parser').parse_iso(s)) end, { %s }), ',')")
      :format(table.concat(inputs, ", ")))
    H.eq(got, table.concat(vim.tbl_map(function(c) return tostring(c[2]) end, valid), ","))
  end)
end

local invalid = {
  { "2026-02-30T10:00Z", "Feb 30" },
  { "2026-02-29T10:00Z", "Feb 29 in non-leap year" },
  { "2026-13-01T10:00Z", "month 13" },
  { "2026-00-10T10:00Z", "month 0" },
  { "2026-01-32T10:00Z", "day 32" },
  { "2026-01-15T24:00Z", "hour 24" },
  { "2026-01-15T10:60Z", "minute 60" },
  { "2026-1-15T10:00Z",  "single-digit month" },
  { "2026-01-15 10:00Z", "space instead of T" },
  { "2026-01-15T10:00",  "missing zone suffix" },
  { "2026-01-15T10:00X", "unknown suffix" },
  { "2026-01-15T10:00+0200", "offset without colon" },
  { "2026-01-15",        "date only" },
  { "",                  "empty string" },
}
for _, c in ipairs(invalid) do
  t.test("parse_iso rejects " .. c[2] .. " (" .. c[1] .. ")", function()
    H.eq(P.parse_iso(c[1]), nil)
  end)
end

t.test("parse_iso rejects non-strings", function()
  H.eq(P.parse_iso(nil), nil)
  H.eq(P.parse_iso(1768471200), nil)
  H.eq(P.parse_iso({}), nil)
end)

-- local_tz_suffix depends on the process timezone, so each case runs in a child nvim.
local suffixes = {
  { "UTC",           "Z" },
  { "Etc/GMT-2",     "H" },      -- POSIX sign is inverted: Etc/GMT-2 is UTC+02:00
  { "Etc/GMT-3",     "S" },
  { "Asia/Tokyo",    "+09:00" },
  { "Asia/Kolkata",  "+05:30" },
  { "Etc/GMT+5",     "-05:00" },
}
for _, c in ipairs(suffixes) do
  t.test("local_tz_suffix in " .. c[1] .. " is " .. c[2], function()
    H.eq(H.eval_in_tz(c[1], "require('timestamps.parser').local_tz_suffix()"), c[2])
  end)
end

t.test("local_tz_suffix(ts) gives the suffix in effect at ts (Helsinki)", function()
  H.eq(P.local_tz_suffix(H.local_ts(2026, 1, 15, 10, 0)), "H")
  H.eq(P.local_tz_suffix(H.local_ts(2026, 7, 15, 10, 0)), "S")
end)

t.test("local_tz_suffix() without argument is the suffix for now", function()
  H.eq(P.local_tz_suffix(), P.local_tz_suffix(os.time()))
end)

---------------------------------------------------------------- home letters (known issue 7)
--- Reset the letters to the defaults after the test.
local function restore_letters()
  H.defer(function() P.setup({ home_tz = "+02:00", home_summer_tz = "+03:00" }) end)
end

t.test("setup changes what H and S mean, for parsing and writing", function()
  restore_letters()
  P.setup({ home_tz = "+01:00", home_summer_tz = "+02:00" })
  H.eq(P.parse_iso("2026-01-15T10:00H"), 1768467600)
  H.eq(P.parse_iso("2026-01-15T10:00S"), 1768464000)
  H.eq(P.local_tz_suffix(H.local_ts(2026, 1, 15, 10, 0)), "S", "+02:00 is now the summer letter")
  H.eq(P.local_tz_suffix(H.local_ts(2026, 7, 15, 10, 0)), "+03:00", "+03:00 no longer has a letter")
end)

t.test("setup keeps a letter it is not given", function()
  restore_letters()
  P.setup({ home_summer_tz = "+04:00" })
  H.eq({ P.HOME_TZ, P.HOME_SUMMER_TZ }, { "+02:00", "+04:00" })
end)

t.test("setup rejects malformed offsets", function()
  restore_letters()
  for _, bad in ipairs({ "+2:00", "0200", "+02", "EET" }) do
    H.ok(not pcall(P.setup, { home_tz = bad }), "accepted " .. bad)
  end
  H.eq(P.HOME_TZ, "+02:00")
end)

t.test("require('timestamps').setup() works (it used to call a missing parser.setup)", function()
  restore_letters()
  require("timestamps").setup()
  require("timestamps").setup({ home_tz = "+02:00" })
end)

return t
