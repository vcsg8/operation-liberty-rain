local function parseTime(str)
    local h, m = string.match(str, "^(%d+):(%d+)$")
    return tonumber(h) * 3600 + tonumber(m) * 60
end

function isInWindow(startStr, endStr)
  local function parseTime(str)
    local h,m = string.match(str, "^(%d+):?(%d*)$")
    h = tonumber(h); m = tonumber(m) or 0
    return h*3600 + m*60
  end
  local t = timer.getAbsTime() % 86400
  local a = parseTime(startStr)
  local b = parseTime(endStr)
  if a < b then return t >= a and t < b else return t >= a or t < b end
end

