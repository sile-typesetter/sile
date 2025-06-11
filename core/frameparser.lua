local lpeg = require("lpeg")
local cassowary = require("cassowary")

local P, C, V = lpeg.P, lpeg.C, lpeg.V

local function resolveMeasurement (str)
   return SILE.types.measurement(str):tonumber()
end

local functionOfFrame = function (dim, id)
   -- TODO implement without a private attribute
   return SILE.frames:pull(id)._variables[dim]
end

-- stylua: ignore start
local number = SILE.parserBits.number
local identifier = SILE.parserBits.identifier
local measurement = SILE.parserBits.measurement / resolveMeasurement
local ws = SILE.parserBits.ws
local dims = P"top" + P"left" + P"bottom" + P"right" + P"width" + P"height"
local relation = C(dims) * ws * P"(" * ws * C(identifier) * ws * P")" / functionOfFrame

local primary = relation + measurement + number

-- For unit testing
SILE._frameParserBits = {
   measurement = measurement,
   relation = relation,
}

local frameparser = P{
   "additive",
   additive = V"plus" + V"minus" + V"multiplicative",
   multiplicative = V"times" + V"divide" + V"primary",
   primary = (ws * primary * ws) + V"braced",
   plus = ws * V"multiplicative" * ws * P"+" * ws * V"additive" * ws / cassowary.plus,
   minus = ws * V"multiplicative" * ws * P"-" * ws * V"additive" * ws / cassowary.minus,
   times = ws * V"primary" * ws * P"*" * ws * V"multiplicative" * ws / cassowary.times,
   divide = ws * V"primary" * ws * P"/" * ws * V"multiplicative" * ws / cassowary.divide,
   braced = ws * P"(" * ws * V"additive" * ws * P")" * ws
}
-- stylua: ignore end

return frameparser
