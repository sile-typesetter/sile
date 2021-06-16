local lpeg = require("lpeg")

local R, S, P = lpeg.R, lpeg.S, lpeg.P
local Cg, Ct, Cmt = lpeg.Cg, lpeg.Ct, lpeg.Cmt

local function isaunit (_, _, unit)
  -- TODO: fix race condition so we can validate units
  if not SILE or not SILE.units then return true end
  return SILE.units[unit] and true or false
end

local function inferpoints (number)
  return { amount = number, unit = "pt" }
end

-- UTF-8 characters
-- decode a two-byte UTF-8 sequence
local function f2 (s)
  local c1, c2 = string.byte(s, 1, 2)
  return c1 * 64 + c2 - 12416
end
-- decode a three-byte UTF-8 sequence
local function f3 (s)
  local c1, c2, c3 = string.byte(s, 1, 3)
  return (c1 * 64 + c2) * 64 + c3 - 925824
end
-- decode a four-byte UTF-8 sequence
local function f4 (s)
  local c1, c2, c3, c4 = string.byte(s, 1, 4)
  return ((c1 * 64 + c2) * 64 + c3) * 64 + c4 - 63447168
end
local cont = lpeg.R("\128\191")   -- continuation byte
local utf8char = lpeg.R("\0\127") / string.byte
  + lpeg.R("\194\223") * cont / f2
  + lpeg.R("\224\239") * cont * cont / f3
  + lpeg.R("\240\244") * cont * cont * cont / f4

local bits = {}

bits.digit = R"09"
bits.whitespace = S'\r\n\f\t '
bits.letter = R("az", "AZ") + P"_"
bits.identifier = (bits.letter + bits.digit)^1
local sign = S"+-"^-1
bits.integer = sign * bits.digit^1
local sep = P"."
bits.decimal = sign * (bits.digit^0 * sep)^-1 * bits.digit^1
bits.scientific = bits.decimal * S"Ee" * bits.integer
bits.number = (bits.scientific + bits.decimal) / tonumber
local ws = bits.whitespace^0
local unit = Cmt(P"%"^-1 * R("az")^-4, isaunit)
bits.measurement = Ct(Cg(bits.number, "amount") * ws * Cg(unit, "unit"))
local amount = bits.measurement + bits.number / inferpoints
local length = Cg(amount, "length")
local stretch = ws * P"plus" * ws * Cg(amount, "stretch")
local shrink = ws * P"minus" * ws * Cg(amount, "shrink")
bits.length = Ct(length * stretch^-1 * shrink^-1)
bits.utf8char = utf8char

return bits
