SILE.inputs.TeXlike = {}
local epnf = require("epnf")

local ID = lpeg.C( SILE.parserBits.letter * (SILE.parserBits.letter+SILE.parserBits.digit)^0 )
SILE.inputs.TeXlike.identifier = (ID + lpeg.P"-" + lpeg.P":")^1

SILE.inputs.TeXlike.passthroughTags = { script = true }
SILE.inputs.TeXlike.passthroughTag = function (tag)
    return SILE.inputs.TeXlike.passthroughTags[tag]
  end

SILE.inputs.TeXlike.parser = function (_ENV)
  local passthroughTag = function (_, _, tag) return SILE.inputs.TeXlike.passthroughTag(tag) end
  local notPassthroughTag = function (_, _, tag) return not SILE.inputs.TeXlike.passthroughTag(tag) end
  local _ = WS^0
  local sep = S",;" * _
  local eol = S"\r\n"
  local quote = P'"'
  local quotedString = ( quote * C((1-quote)^1) * quote )
  local value = ( quotedString + (1-S",;]")^1 )
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
      P(1-eol)^0 *
      eol^-1
    ) / ""

  START "document"
  document = V"texlike_stuff" * EOF"Unexpected character at end of input"
  texlike_stuff = Cg(
      V"environment" +
      comment +
      V"texlike_text" +
      V"texlike_bracketed_stuff" +
      V"command"
    )^0
  passthrough_stuff = C(Cg(
      V"passthrough_text" +
      V"passthrough_debracketed_stuff"
    )^0)
  passthrough_env_stuff = Cg(
      V"passthrough_env_text"
    )^0
  texlike_text = C((1-S("\\{}%"))^1)
  passthrough_text = C((1-S("{}"))^1)
  passthrough_env_text = C((1-(P"\\end{" * (myID * Cb"tag") * P"}"))^1)
  texlike_bracketed_stuff = P"{" * V"texlike_stuff" * ( P"}" + E("} expected") )
  passthrough_bracketed_stuff = P"{" * V"passthrough_stuff" * ( P"}" + E("} expected") )
  passthrough_debracketed_stuff = C(V"passthrough_bracketed_stuff")
  command = (
      ( P"\\"-P"\\begin" ) *
      Cg(myID, "tag") *
      Cg(parameters,"attr") *
      (
        (Cmt(Cb"tag", passthroughTag) * V"passthrough_bracketed_stuff") +
        (Cmt(Cb"tag", notPassthroughTag) * V"texlike_bracketed_stuff")
      )^0
    ) - P("\\end{")
  environment =
    P"\\begin" *
    Cg(parameters, "attr") *
    P"{" *
    Cg(myID, "tag") *
    P"}" *
    (
      (Cmt(Cb"tag", passthroughTag) * V"passthrough_env_stuff") +
      (Cmt(Cb"tag", notPassthroughTag) * V"texlike_stuff")
    ) *
    (
      P"\\end{" *
      (
        Cmt(myID * Cb"tag", function (_,_,thisTag,lastTag) return thisTag == lastTag end) + E"Environment mismatch"
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

local function massage_ast (tree, doc)
  -- Sort out pos
  if type(tree) == "string" then return tree end
  if tree.pos then
    tree.line, tree.col = getline(doc, tree.pos)
  end
  if tree.id == "document"
      or tree.id == "texlike_bracketed_stuff"
      or tree.id == "passthrough_bracketed_stuff"
    then return massage_ast(tree[1], doc) end
  if tree.id == "texlike_text"
      or tree.id == "passthrough_text"
      or tree.id == "passthrough_env_text"
    then return tree[1] end
  for key, val in ipairs(tree) do
    if val.id == "texlike_stuff"
      or val.id == "passthrough_stuff"
      or val.id == "passthrough_env_stuff"
      then
      SU.splice(tree, key, key, massage_ast(val, doc))
    else
      tree[key] = massage_ast(val, doc)
    end
  end
  return tree
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
  -- a document always consists of one texlike_stuff
  tree = tree[1][1]
  if tree.id == "texlike_text" then tree = {tree} end
  if not tree then return end
  resetCache()
  tree = massage_ast(tree, doc)
  return tree
end

SILE.inputs.TeXlike.order = 99
SILE.inputs.TeXlike.appropriate = function () return true end
