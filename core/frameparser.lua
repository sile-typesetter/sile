lpeg = require("lpeg")
local cassowary = require("cassowary")
local R = lpeg.R
local S = lpeg.S
local P = lpeg.P
local C = lpeg.C
local V = lpeg.V
local Cg = lpeg.Cg
local Ct = lpeg.Ct

local number = SILE.parserBits.number
local identifier = SILE.parserBits.identifier
local dimensioned_string = SILE.parserBits.dimensioned_string / function (s) return SILE.toAbsoluteMeasurement(s) end
local whitespace = SILE.parserBits.whitespace

local functionOfFrame = function (dim, ident)
	if not SILE.frames[ident] then
		SILE.newFrame({id = ident})
	end
	return SILE.frames[ident].variables[dim]
end
local func = C(P("top") + P("left") + P("bottom") + P("right") + P("width") + P("height")) * P("(") * C(identifier) * P(")") / functionOfFrame

local primary = dimensioned_string + func + number.number

	-- For testing
	SILE.frameParserBits = {
		number = number,
		identifier = identifier,
		whitespace = whitespace,
		units = units,
		dimensioned_string = dimensioned_string,
		func = func,
		primary = primary
	}

local grammar = {
	"additive",
	additive =  (( V("multiplicative") * whitespace * P("+")  * whitespace * V("additive") ) / function (l,r) return cassowary.plus(l,r) end)
				+
				(( V("multiplicative") * whitespace * P("-") * whitespace * V("additive") * whitespace ) / function(l,r) return cassowary.minus(l,r) end )+
				V("multiplicative")
	,
	primary = primary + V("bracketed"),
	multiplicative =  (( V("primary") * whitespace * P("*") * whitespace * V("multiplicative") ) / function (l,r) return cassowary.times(l,r) end)+
				(( V("primary") * whitespace * P("/") * whitespace * V("multiplicative") ) / function(l,r) return cassowary.divide(l,r) end) +
				V("primary"),
	bracketed = P("(") * whitespace * V("additive") * whitespace * P(")") / function (a) return a; end
}

return P(grammar)
