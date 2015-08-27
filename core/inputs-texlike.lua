SILE.inputs.TeXlike = {}
local epnf = require( "epnf" )

local ID = lpeg.C( SILE.parserBits.letter * (SILE.parserBits.letter+SILE.parserBits.digit)^0 )
SILE.inputs.TeXlike.identifier = (ID + lpeg.P("-") + lpeg.P(":"))^1

SILE.inputs.TeXlike.parser = function (_ENV)
  local _ = WS^0
  local sep = lpeg.S(",;") * _
  local quotedString = (P("\"") * C((1-lpeg.S("\""))^1) * P("\""))
  local value = (quotedString + (1-lpeg.S(",;]"))^1 )
  local myID = C( SILE.inputs.TeXlike.identifier + lpeg.P(1) ) / function (t) return t end
  local pair = lpeg.Cg(myID * _ * "=" * _ * C(value)) * sep^-1   / function (...) local t= {...}; return t[1], t[#t] end
  local list = lpeg.Cf(lpeg.Ct("") * pair^0, rawset)
  local parameters = (P("[") * list * P("]")) ^-1 / function (a) return type(a)=="table" and a or {} end
  local anything = C( (1-lpeg.S("\\{}%\r\n")) ^1)
  local lineEndLineStartSpace = (lpeg.S(" ")^0 * lpeg.S("\r\n")^1 * lpeg.S(" ")^0)^-1
  local comment = ((P("%") * (1-lpeg.S("\r\n"))^0 * lpeg.S("\r\n")^-1) /function () return "" end)

  START "document";
  document = V("stuff") * (-1 + E("Unexpected character at end of input"))
  text = (anything + C(WS))^1 / function(...) return table.concat({...}, "") end
  stuff = Cg(V"environment" +
    comment
    + V("text") + V"bracketed_stuff" + V"command")^0
  bracketed_stuff = P"{" * V"stuff" * (P"}" + E("} expected"))
  command =((P("\\")-P("\\begin")) * Cg(myID, "tag") * Cg(parameters,"attr") * V"bracketed_stuff"^0)-P("\\end{")
  environment =
    P("\\begin") * Cg(parameters, "attr") * P("{") * Cg(myID, "tag") * P("}")
      * V("stuff")
    * (P("\\end{") * (
      Cmt(myID * Cb("tag"), function(s,i,a,b) return a==b end) +
      E("Environment mismatch")
    ) * (P("}") * _) + E("Environment begun but never ended"))
end

local linecache = {}
local lno, col, lastpos
local function resetCache()
  lno = 1
  col = 1
  lastpos = 0
  linecache = { { lno = 1, pos = 1} }
end

local function getline( s, p )
  start = 1
  lno = 1
  if p > lastpos then
    lno = linecache[#linecache].lno
    start = linecache[#linecache].pos + 1
    col = 1
  else
    for j = 1,#linecache-1 do
      if linecache[j+1].pos >= p then
        lno = linecache[j].lno
        col = p - linecache[j].pos
        return lno,col
      end
    end
  end
  for i = start, p do
    if string.sub( s, i, i ) == "\n" then
      lno = lno + 1
      col = 1
      linecache[#linecache+1] = { pos = i, lno = lno }
      lastpos = i
    end
    col = col + 1
  end
  return lno, col
end

local function massage_ast(t,doc)
  -- Sort out pos
  if type(t) == "string" then return t end
  if t.pos then
    t.line, t.col = getline(doc, t.pos)
  end
  if t.id == "document" then return massage_ast(t[1],doc) end
  if t.id == "text" then return t[1] end
  if t.id == "bracketed_stuff" then return massage_ast(t[1],doc) end
  for k,v in ipairs(t) do
    if v.id == "stuff" then
      local val = massage_ast(v,doc)
      SU.splice(t, k,k, val)
    else
      t[k] = massage_ast(v,doc)
    end
  end
  return t
end

function SILE.inputs.TeXlike.process(fn)
  local fh = io.open(fn)
  resetCache()
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

local _parser

function SILE.inputs.TeXlike.rebuildParser()
  _parser = epnf.define(SILE.inputs.TeXlike.parser)
end

SILE.inputs.TeXlike.rebuildParser()

function SILE.inputs.TeXlike.docToTree(doc)
  local t = epnf.parsestring(_parser, doc)
  -- a document always consists of one stuff
  t = t[1][1]
  if not t then return end
  resetCache()
  t = massage_ast(t,doc)
  return t
end
