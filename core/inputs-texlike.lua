SILE.inputs.TeXlike = {}
lpeg = require("lpeg")
lpeg.locale(lpeg)
local R= lpeg.R
local P= lpeg.P
local C= lpeg.C
local Cb= lpeg.Cb
local Cg= lpeg.Cg
local Cc= lpeg.Cc
local Ct= lpeg.Ct

local V= lpeg.V

local newline = P"\r"^-1 * "\n" / function (a) print("New"); end
local incrementline = Cg( Cb"linenum" / function ( a ) print("NL");  return a + 1 end , "linenum" )
local setup = Cg ( Cc ( 100) , "linenum" )

local identifier = (R("AZ") + R("az") + P("_") + R("09"))^1
nl = newline * incrementline
space = nl + lpeg.space
local sep = lpeg.S(",;") * space^0
local value = (1-lpeg.S(",;]"))^1
local pair = lpeg.Cg(C(identifier) * space ^0 * "=" * space ^0 * C(value)) * sep^-1
local list = lpeg.Cf(lpeg.Ct("") * pair^0, rawset)
local parameters = (P("[") * list * P("]")) ^-1

anything = C( (space^1 + (1-lpeg.S("\\{}")) )^1) * Cb("linenum") / function (a,b) return { text = a, line = b } end

local check_env = function(e) if not e == Cb("environment") then die() end end
local begin_environment = P("\\begin") * Ct(parameters) * P("{") * Cg(identifier, "environment") * P("}")
local end_environment = P("\\end{") * (Cg(identifier) / check_env) * P("}")
command_with = P("\\") * Cg(identifier) * Ct(parameters) * P("{") * anything^0 * P("}")

texlike = lpeg.P{
  "environment";
  document = setup * V("stuff") * -1,
  stuff = Ct((V"environment" + V"command_with" + V"bracketed_stuff" + anything)^0),
  bracketed_stuff = P"{" * V"stuff" * P"}" / function (a) return a end,
  command_with = P("\\") * Cg(identifier) * Ct(parameters) * V"bracketed_stuff" / function (i,p,n) return { command = i, parameters = p, nodes = n } end,
  command_without = ( P("\\") * Cg(identifier) * Ct(parameters) ) / function (i,p) return { command = i, parameters = p } end,
  environment = begin_environment * P"stuff" * end_environment
}

function SILE.inputs.TeXlike.process(file)
end