---------------------------------------------------------------
-- TIMESTAMP PARSER (Z / H / S / +offset support with validation)
--
-- Zone suffixes are fixed offsets, whatever the date:
--   Z = UTC, H = HOME_TZ (home standard time), S = HOME_SUMMER_TZ (home summer time),
--   or an explicit +hh:mm / -hh:mm.
---------------------------------------------------------------
local M = {}

M.HOME_TZ = "+02:00"         -- H: home standard time (Finland, EET)
M.HOME_SUMMER_TZ = "+03:00"  -- S: home summer time (Finland, EEST)

local OFFSET_FORMAT = "^[%+%-]%d%d:%d%d$"

--- Configure the home letters: setup({ home_tz = "+02:00", home_summer_tz = "+03:00" }).
--- Options that are not given keep their current value.
function M.setup(opts)
  opts = opts or {}
  for key, field in pairs({ home_tz = "HOME_TZ", home_summer_tz = "HOME_SUMMER_TZ" }) do
    local value = opts[key]
    if value ~= nil then
      if type(value) ~= "string" or not value:match(OFFSET_FORMAT) then
        error(("timestamps: %s must look like +02:00, got %s"):format(key, vim.inspect(value)), 2)
      end
      M[field] = value
    end
  end
end

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
  y, m, d, H, M_, suffix = ts:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)([ZHS])$")
  
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
  elseif suffix == "H" or suffix == "S" then
    local home = suffix == "H" and M.HOME_TZ or M.HOME_SUMMER_TZ
    local sign, hh, mm = home:match("([%+%-])(%d%d):(%d%d)")
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

--- Zone suffix for local time at `ts` (default: now): "Z", "H" (= HOME_TZ), "S" (= HOME_SUMMER_TZ) or "+hh:mm".
--- Pass the timestamp being formatted: in a DST zone the offset depends on the date.
--- @param ts number|nil epoch seconds
M.local_tz_suffix = function (ts)
  local z = os.date("%z", ts) -- e.g. "+0200"

  local sign, hh, mm = z:match("([%+%-])(%d%d)(%d%d)")
  if not sign then return "" end

  local formatted = string.format("%s%s:%s", sign, hh, mm)

  if formatted == "+00:00" then
    return "Z"
  elseif formatted == M.HOME_TZ then
    return "H"
  elseif formatted == M.HOME_SUMMER_TZ then
    return "S"
  else
    return formatted
  end
end

return M
