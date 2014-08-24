SILE.inputs.TeXlike = {}
local epnf = require( "epnf" )

texlike = epnf.define(function (_ENV)
  local _ = WS^0
  local sep = lpeg.S(",;") * _
  local value = (1-lpeg.S(",;]"))^1
  local myID = C( ((ID+P("-")+P(":"))^1)  + P(1) ) / function (t) return t end
  local pair = lpeg.Cg(myID * _ * "=" * _ * C(value)) * sep^-1
  local list = lpeg.Cf(lpeg.Ct("") * pair^0, rawset)
  local parameters = (P("[") * list * P("]")) ^-1 / function (a) return type(a)=="table" and a or {} end
  local anything = C( (1-lpeg.S("\\{}%\r\n")) ^1) 

  START "document";
  document = V("stuff") * (-1 + E("Unexpected character at end of input"))
  text = (anything + C(WS))^1 / function(...) return table.concat({...}, "") end
  stuff = Cg(V"environment" + 
    ((P("%") * (1-lpeg.S("\r\n"))^0 * lpeg.S("\r\n")^0) /function () return "" end) -- Don't bother telling me about comments
    + V("text") + V"bracketed_stuff" + V"command")^0
  bracketed_stuff = P"{" * V"stuff" * (P"}" + E("} expected"))
  command =((P("\\")-P("\\begin")) * Cg(myID, "tag") * Cg(parameters,"attr") * V"bracketed_stuff"^0)-P("\\end{")
  environment = 
    P("\\begin") * Cg(parameters, "attr") * P("{") * Cg(myID, "tag") * P("}") 
      * V("stuff") 
    * (P("\\end{") * (
      Cmt(myID * Cb("tag"), function(s,i,a,b) return a==b end) +
      E("Environment mismatch")
    ) * P("}") + E("Environment begun but never ended"))
end)

local function massage_ast(t)
  if type(t) == "string" then return t end
  if t.id == "document" then return massage_ast(t[1]) end
  if t.id == "text" then return t[1] end
  if t.id == "bracketed_stuff" then return massage_ast(t[1]) end
  for k,v in ipairs(t) do
    if v.id == "stuff" then
      local val = massage_ast(v)
      SU.splice(t, k,k, val)
    else
      t[k] = massage_ast(v)
    end
  end
  return t
end

function SILE.inputs.TeXlike.process(fn)
  local fh = io.open(fn)
  local doc = fh:read("*all")
  local t = SILE.inputs.TeXlike.docToTree(doc)
  local root = SILE.documentState.documentClass == nil
  if root then
    if not(t.tag == "document") then SU.error("Should begin with \\begin{document}") end
    SILE.inputs.common.init(fn, t)
  end
  SILE.process(t)
  if root and not SILE.preamble then
    SILE.documentState.documentClass:finish()
  end  
end

function SILE.inputs.TeXlike.docToTree(doc)
  local t = epnf.parsestring(texlike, doc)
  -- a document always consists of one stuff
  t = t[1][1]
  if not t then return end
  t = massage_ast(t) 
  return t
end
