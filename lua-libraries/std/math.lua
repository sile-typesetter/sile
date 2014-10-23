--[[--
 Additions to the math module.
 @module std.math
]]

local _floor = math.floor


--- Extend `math.floor` to take the number of decimal places.
-- @function floor
-- @param n number
-- @param p number of decimal places to truncate to (default: 0)
-- @return `n` truncated to `p` decimal places
local function floor (n, p)
  if p and p ~= 0 then
    local e = 10 ^ p
    return _floor (n * e) / e
  else
    return _floor (n)
  end
end


--- Round a number to a given number of decimal places
-- @function round
-- @param n number
-- @param p number of decimal places to round to (default: 0)
-- @return `n` rounded to `p` decimal places
local function round (n, p)
  local e = 10 ^ (p or 0)
  return _floor (n * e + 0.5) / e
end


local Math = {
  floor  = floor,
  round  = round,

  -- Core Lua function implementations.
  _floor = _floor,
}

for k, v in pairs (math) do
  Math[k] = Math[k] or v
end

return Math
