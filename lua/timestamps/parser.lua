---------------------------------------------------------------
-- TIMESTAMP PARSER (Z / H / +offset support)
---------------------------------------------------------------
local M = {}

local HOME_TZ = "+02:00"  -- your home timezone
M.DEFAULT_NOTIFY = "15min"

function M.setup(opts)
  opts = opts or {}
  if opts.default_notify then
    M.DEFAULT_NOTIFY = opts.default_notify
  end
end

-- convert offset string to seconds
local function offset_to_seconds(sign, hh, mm)
  return (tonumber(hh)*60 + tonumber(mm)) * 60 * (sign == "-" and -1 or 1)
end

function M.parse_iso(ts)
  local y,m,d,H,M_,suffix

  y,m,d,H,M_,suffix = ts:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)([ZH])")
  if not y then
    y,m,d,H,M_,suffix =
      ts:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)([%+%-]%d%d:%d%d)")
  end

  if not y then return nil end

  local year  = tonumber(y)
  local month = tonumber(m)
  local day   = tonumber(d)
  local hour  = tonumber(H)
  local min   = tonumber(M_)

  local offset = 0

  if suffix == "Z" then
    offset = 0
  elseif suffix == "H" then
    local sign, hh, mm = HOME_TZ:match("([%+%-])(%d%d):(%d%d)")
    offset = offset_to_seconds(sign, hh, mm)
  else
    local sign, hh, mm = suffix:match("([%+%-])(%d%d):(%d%d)")
    offset = offset_to_seconds(sign, hh, mm)
  end

  -- construct UTC time
  local epoch = os.time({
    year = year,
    month = month,
    day = day,
    hour = hour,
    min = min,
    sec = 0,
    isdst = false,
  })

  -- system offset at that specific time (handles DST correctly)
  local local_offset = os.difftime(
    os.time(os.date("*t", epoch)),
    os.time(os.date("!*t", epoch))
  )

  epoch = epoch - offset + local_offset

  return epoch
end

M.local_tz_suffix = function (home_tz)
  local z = os.date("%z") -- e.g. "+0200"

  local sign, hh, mm = z:match("([%+%-])(%d%d)(%d%d)")
  if not sign then return "" end

  local formatted = string.format("%s%s:%s", sign, hh, mm)

  if formatted == "+00:00" then
    return "Z"
  elseif formatted == home_tz then
    return "H"
  else
    return formatted
  end
end


return M
