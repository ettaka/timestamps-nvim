---------------------------------------------------------------
-- TIMESTAMP PARSER (Z / H / +offset support with validation)
---------------------------------------------------------------
local M = {}

M.HOME_TZ = "+02:00"  -- your home timezone

-- convert offset string to seconds
local function offset_to_seconds(sign, hh, mm)
  return (tonumber(hh)*60 + tonumber(mm)) * 60 * (sign == "-" and -1 or 1)
end

--- Validates ISO-8601 format and real-world date/time values.
--- @param ts string The raw string to parse and validate
--- @return number|nil epoch The converted UTC timestamp, or nil if invalid
function M.parse_iso(ts)
  if type(ts) ~= "string" then return nil end

  -- Clean trailing punctuation/parentheses from the tag (e.g., "2026-09-01T00:00H)" -> "2026-09-01T00:00H")
  ts = ts:match("^([%w%-%+:]+)")
  if not ts then return nil end

  local y, m, d, H, M_, suffix

  -- 1. Try matching Z or H suffix first (strictly 4 digits year, 2 digits for others)
  y, m, d, H, M_, suffix = ts:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)([ZH])$")
  
  -- 2. Fall back to matching numeric offsets (e.g., +03:00 or -05:00)
  if not y then
    y, m, d, H, M_, suffix = ts:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)([%+%-]%d%d:%d%d)$")
  end

  -- If neither structural pattern matched, it's a formatting mistake
  if not y then return nil end

  local year  = tonumber(y)
  local month = tonumber(m)
  local day   = tonumber(d)
  local hour  = tonumber(H)
  local min   = tonumber(M_)

  -- 3. Validate basic logical ranges (Hours/Minutes/Months/Days)
  if hour > 23 or min > 59 or month < 1 or month > 12 or day < 1 or day > 31 then 
    return nil 
  end

  local offset = 0

  if suffix == "Z" then
    offset = 0
  elseif suffix == "H" then
    local sign, hh, mm = M.HOME_TZ:match("([%+%-])(%d%d):(%d%d)")
    if sign then offset = offset_to_seconds(sign, hh, mm) end
  else
    local sign, hh, mm = suffix:match("([%+%-])(%d%d):(%d%d)")
    if sign then offset = offset_to_seconds(sign, hh, mm) end
  end

  -- 4. Construct local fields and catch platform-level bounds (e.g., pre-1970 restrictions)
  local success, epoch = pcall(os.time, {
    year = year,
    month = month,
    day = day,
    hour = hour,
    min = min,
    sec = 0,
    isdst = false,
  })
  
  if not success or not epoch then return nil end

  -- 5. Mathematical check for calendar correctness (e.g., catching Feb 30th)
  local normalized = os.date("*t", epoch)
  if normalized.year ~= year or normalized.month ~= month or normalized.day ~= day then
    return nil 
  end

  -- Calculate system offset at that specific time (handles DST correctly)
  local local_offset = os.difftime(
    os.time(os.date("*t", epoch)),
    os.time(os.date("!*t", epoch))
  )

  epoch = epoch - offset + local_offset

  return epoch
end

M.local_tz_suffix = function ()
  local z = os.date("%z") -- e.g. "+0200"

  local sign, hh, mm = z:match("([%+%-])(%d%d)(%d%d)")
  if not sign then return "" end

  local formatted = string.format("%s%s:%s", sign, hh, mm)

  if formatted == "+00:00" then
    return "Z"
  elseif formatted == M.HOME_TZ then
    return "H"
  else
    return formatted
  end
end

return M
