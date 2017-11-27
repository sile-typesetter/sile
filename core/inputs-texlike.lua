SILE.inputs.TeXlike = {}
local epnf = require("epnf")

local ID = lpeg.C( SILE.parserBits.letter * (SILE.parserBits.letter+SILE.parserBits.digit)^0 )
SILE.inputs.TeXlike.identifier = (ID + lpeg.P"-" + lpeg.P":")^1

SILE.inputs.TeXlike.parser = function (_ENV)
  local _ = WS^0
  local sep = S",;" * _
  local quotedString = P"\"" * C((1-S"\"")^1) * P"\""
  local value = quotedString + (1-S",;]")^1
  local myID = C(SILE.inputs.TeXlike.identifier + P(1)) / 1
  local pair = Cg(myID * _ * "=" * _ * C(value)) * sep^-1 / function (...) local t = {...}; return t[1], t[#t] end
  local list = Cf(Ct"" * pair^0, rawset)
  local parameters = (
      P"[" *
      list *
      P"]"
    )^-1/function (a) return type(a)=="table" and a or {} end
  local comment = (
      P"%" *
      P(1-S"\r\n")^0 *
      S"\r\n"^-1
    ) / ""

  START "document"
  document = V"stuff" * EOF"Unexpected character at end of input"
  text = C((1-S("\\{}%"))^1)
  stuff = Cg(
      V"environment" +
      comment +
      V"text" +
      V"bracketed_stuff" +
      V"command"
    )^0
  bracketed_stuff = P"{" * V"stuff" * (P"}" + E("} expected"))
  command = (
      ( P"\\"-P"\\begin" ) *
      Cg(myID, "tag") *
      Cg(parameters,"attr") *
      V"bracketed_stuff"^0
    ) - P("\\end{")
  environment =
    P"\\begin" *
    Cg(parameters, "attr") *
    P"{" *
    Cg(myID, "tag") *
    P"}" *
    V"stuff" *
    (
      P"\\end{" *
      (
        Cmt(myID * Cb"tag", function (s,i,a,b) return a==b end) + E"Environment mismatch"
      ) *
      ( P"}" * _ ) + E"Environment begun but never ended"
    )
end

local linecache = {}
local lno, col, lastpos
local function resetCache ()
  lno = 1
  col = 1
  lastpos = 0
  linecache = { { lno = 1, pos = 1} }
end

local function getline (s, p)
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

local function massage_ast (t, doc)
  -- Sort out pos
  if type(t) == "string" then return t end
  if t.pos then
    t.line, t.col = getline(doc, t.pos)
  end
  if t.id == "document" then return massage_ast(t[1], doc) end
  if t.id == "text" then return t[1] end
  if t.id == "bracketed_stuff" then return massage_ast(t[1], doc) end
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

function SILE.inputs.TeXlike.process (doc)
  local tree = SILE.inputs.TeXlike.docToTree(doc)
  local root = SILE.documentState.documentClass == nil
  if root then
    if tree.tag == "document" then
      SILE.inputs.common.init(doc, tree)
      SILE.process(tree)
    elseif pcall(function () assert(loadstring(doc))() end) then
    else
      SU.error("Input not recognized as Lua or SILE content")
    end
  end
  if root and not SILE.preamble then
    SILE.documentState.documentClass:finish()
  end
end

local _parser

function SILE.inputs.TeXlike.rebuildParser ()
  _parser = epnf.define(SILE.inputs.TeXlike.parser)
end

SILE.inputs.TeXlike.rebuildParser()

function SILE.inputs.TeXlike.docToTree (doc)
  local tree = epnf.parsestring(_parser, doc)
  -- a document always consists of one stuff
  tree = tree[1][1]
  if tree.id == "text" then tree = {tree} end
  if not tree then return end
  resetCache()
  tree = massage_ast(tree, doc)
  return tree
end

SILE.inputs.TeXlike.order = 99
SILE.inputs.TeXlike.appropriate = function () return true end
