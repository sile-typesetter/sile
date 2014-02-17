lpeg = require("lpeg")
local R = lpeg.R
local S = lpeg.S
local P = lpeg.P
local C = lpeg.C
local V = lpeg.V

local number = {}

local digit = R("09")
number.integer = (S("+-") ^ -1) * (digit   ^  1)
number.fractional = (P(".")   ) * (digit ^ 1)
number.decimal =	
	(number.integer *              -- Integer
	(number.fractional ^ -1)) +    -- Fractional
	(S("+-") * number.fractional)  -- Completely fractional number

number.scientific = 
	number.decimal * -- Decimal number
	S("Ee") *        -- E or e
	number.integer   -- Exponent

-- Matches all of the above
number.number = C(number.decimal + number.scientific) / function (n) return tonumber(n) end
local identifier = (R("AZ") + R("az") + P("_") + R("09"))^1
local whitespace = S('\r\n\f\t ')^0
local units = P("mm") + P("cm") + P("in") + P("pt")
local dimensioned_string = ( C(number.number) * whitespace * C(units) ) / function (x,n,u) return  SILE.toPoints(n, u) end
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