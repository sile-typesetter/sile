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
local Cmt = lpeg.Cmt

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

local check_env = function(text, pos, ...) 
  print(inspect(...))
  die()
end
begin_environment = P("\\begin") * Ct(parameters) * P("{") * Cg(identifier, "environment") * Cb("environment") * P("}") / function (p,i) return { params = p, environment = i } end
end_environment = P("\\end{") * Cg(identifier) * P("}") /function (id) return { endx = id } end
command_with = P("\\") * Cg(identifier) * Ct(parameters) * P("{") * anything^0 * P("}")

texlike = lpeg.P{
  "document";
  document = setup * V("stuff") * -1,
  stuff = Cg(V"environment" + anything + V"bracketed_stuff" + V"command_with" + V"command_without")^0,
  bracketed_stuff = P"{" * V"stuff" * P"}" / function (a) return a end,
  command_with =((P("\\") * Cg(identifier) * Ct(parameters) * V"bracketed_stuff")-P("\\end{")) / function (i,p,n) return { command = i, parameters = p, nodes = n } end,
  command_without = (( P("\\") * Cg(identifier) * Ct(parameters) )-P("\\end{")) / function (i,p) return { command = i, parameters = p } end,
  environment = Cmt(begin_environment * V("stuff") * end_environment, check_env) / function(i,p) return { env = i, p = p } end
}

-- texlike = lpeg.P{
--   "stuff";
--   environment = P("\\BEGIN") * V("stuff") * P("\\END"),
--   stuff = (V("environment") + (1-lpeg.S("\\")))^1
-- }

function SILE.inputs.TeXlike.process(file)
end