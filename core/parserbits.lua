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

SILE.parserBits = {
  number = number,
  digit = digit,
  letter = lpeg.R( "az", "AZ" ) + lpeg.P"_",
  identifier = (R("AZ") + R("az") + P("_") + R("09"))^1,
  units = units,
  zero = zero,
  whitespace = whitespace,
  dimensioned_string = dimensioned_string,
  length = Ct(Cg(dimensioned_string + zero, "length") * whitespace * (P("plus") * whitespace * Cg(dimensioned_string + zero, "stretch"))^-1 * whitespace * (P("minus") * whitespace * Cg(dimensioned_string + zero,"shrink"))^-1)
}