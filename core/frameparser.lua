lpeg = require("lpeg")
local R = lpeg.R
local S = lpeg.S
local P = lpeg.P
local C = lpeg.C
local V = lpeg.V
local Cg = lpeg.Cg
local Ct = lpeg.Ct

local number = SILE.parserBits.number
local identifier = SILE.parserBits.identifier
local dimensioned_string = SILE.parserBits.dimensioned_string
local whitespace = SILE.parserBits.whitespace

local func = C(P("top") + P("left") + P("bottom") + P("right") ) * P("(") * C(identifier) * P(")") / function (dim, ident) f = SILE.getFrame(ident); return f[dim](f) end
local percentage = ( C(number.number) * whitespace * P("%") ) / function (n) return SILE.toPoints(n, "%", SILE.documentState._dimension) end
local primary = dimensioned_string + percentage + func + number.number

if testingSILE then
	SILE.frameParserBits = {
		number = number,
		identifier = identifier,
		whitespace = whitespace,
		units = units,
		dimensioned_string = dimensioned_string,
		func = func,
		percentage = percentage,
		primary = primary
	}
end

local grammar = {
	"additive",
	additive =  (( V("multiplicative") * whitespace * P("+")  * whitespace * V("additive") ) / function (l,r) return l+r end)
				+
				(( V("multiplicative") * whitespace * P("-") * whitespace * V("additive") * whitespace ) / function(l,r) return l-r end )+
				V("multiplicative")
	,
	primary = primary + V("bracketed"),
	multiplicative =  (( V("primary") * whitespace * P("*") * whitespace * V("multiplicative") ) / function (l,r) return (l*r) end)+
				(( V("primary") * whitespace * P("/") * whitespace * V("multiplicative") ) / function(l,r) return l/r end) +
				V("primary"),
	bracketed = P("(") * whitespace * V("additive") * whitespace * P(")") / function (a) return a; end
}

return P(grammar)