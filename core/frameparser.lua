local lpeg = require("lpeg")
local cassowary = require("cassowary")

local P, C, V = lpeg.P, lpeg.C, lpeg.V

local function resolveMeasurement (str)
  return SILE.measurement(str):tonumber()
end

local functionOfFrame = function (dim, id)
  -- SU.debug("que", "fof", dim, id)
  if not SILE.frames[id] then
    -- TODO: Fix this race condition properly!
    SILE.newFrame({ id = id })
  end
  return SILE.frames[id].variables[dim]
end

local number = SILE.parserBits.number
local identifier = SILE.parserBits.identifier
local measurement = SILE.parserBits.measurement / resolveMeasurement
local whitespace = SILE.parserBits.whitespace
local func = C(P"top" + P"left" + P"bottom" + P"right" + P"width" + P"height") * P"(" * C(identifier) * P")" / functionOfFrame

local primary = func + measurement + number

-- For unit testing
SILE._frameParserBits = {
  measurement = measurement,
  func = func,
}

-- TODO: Cleanup this grammar for readability and maybe export a Lua function that does a match() instead of the grammar
return P{
  "additive",
  additive = ((V"multiplicative" * whitespace * P"+" * whitespace * V"additive") / cassowary.plus) + ((V"multiplicative" * whitespace * P"-" * whitespace * V"additive" * whitespace) / cassowary.minus ) + V"multiplicative",
  primary = primary + V"bracketed",
  multiplicative = ((V"primary" * whitespace * P"*" * whitespace * V"multiplicative") / cassowary.times) + ((V"primary" * whitespace * P"/" * whitespace * V"multiplicative") / cassowary.divide) + V"primary",
  bracketed = P"(" * whitespace * V"additive" * whitespace * P")" / function (a) return a end
}
