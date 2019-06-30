lpeg = require("lpeg")
local R = lpeg.R
local S = lpeg.S
local P = lpeg.P
local C = lpeg.C
local V = lpeg.V
local Cg = lpeg.Cg
local Ct = lpeg.Ct
local number = {}

local digit = R("09")
number.integer = (S("+-") ^ -1) * (digit   ^  1)
number.fractional = (P(".")   ) * (digit ^ 1)
number.decimal =
  (number.integer *              -- Integer
  (number.fractional ^ -1)) +    -- Fractional
  (S("+-")^-1 * number.fractional)  -- Completely fractional number

number.scientific =
  number.decimal * -- Decimal number
  S("Ee") *        -- E or e
  number.integer   -- Exponent

-- Matches all of the above
number.number = C(number.decimal + number.scientific) / function (n) return tonumber(n) end
local whitespace = S('\r\n\f\t ')^0
local units = lpeg.Cmt(C(R("az", "%%")^-5), function (s,i,p)
  for k,v in pairs(SILE.units) do
    if p == k then return true end
  end
  return false
end)
local zero = P("0") / function(...) return 0 end
local dimensioned_string = ( C(number.number) * whitespace * C(units) ) / function (x,n,u) return  SILE.toMeasurement(n, u) end

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

local decode_pattern = lpeg.Ct(utf8char^0) * -1

SILE.parserBits = {
  number = number,
  digit = digit,
  letter = lpeg.R( "az", "AZ" ) + lpeg.P"_",
  identifier = (R("AZ") + R("az") + P("_") + R("09"))^1,
  utf8char = utf8char,
  units = units,
  zero = zero,
  whitespace = whitespace,
  dimensioned_string = dimensioned_string,
  length = Ct(Cg(dimensioned_string + zero, "length") * whitespace * (P("plus") * whitespace * Cg(dimensioned_string + zero, "stretch"))^-1 * whitespace * (P("minus") * whitespace * Cg(dimensioned_string + zero,"shrink"))^-1)
}
