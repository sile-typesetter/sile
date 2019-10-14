SILE.inputs.TeXlike = {}
local epnf = require("epnf")

local ID = lpeg.C( SILE.parserBits.letter * (SILE.parserBits.letter+SILE.parserBits.digit)^0 )
SILE.inputs.TeXlike.identifier = (ID + lpeg.P"-" + lpeg.P":")^1

SILE.inputs.TeXlike.passthroughCommands = {
  ftl = true,
  script = true
}
setmetatable(SILE.inputs.TeXlike.passthroughCommands, {
    __call = function(self, command)
      return self[command]
    end
  })

SILE.inputs.TeXlike.parser = function (_ENV)
  local isPassthrough = function (_, _, command) return SILE.inputs.TeXlike.passthroughCommands(command) end
  local isNotPassThrough = function (...) return not isPassthrough(...) end
  local _ = WS^0
  local sep = S",;" * _
  local eol = S"\r\n"
  local quote = P'"'
  local quotedString = ( quote * C((1-quote)^1) * quote )
  local value = ( quotedString + (1-S",;]")^1 )
  local myID = C(SILE.inputs.TeXlike.identifier + P(1)) / 1
  local pair = Cg(myID * _ * "=" * _ * C(value)) * sep^-1 / function (...) local tbl = {...}; return tbl[1], tbl[#tbl] end
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
      V"texlike_command"
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
  passthrough_env_text = C((1-(P"\\end{" * (myID * Cb"command") * P"}"))^1)
  texlike_bracketed_stuff = P"{" * V"texlike_stuff" * ( P"}" + E("} expected") )
  passthrough_bracketed_stuff = P"{" * V"passthrough_stuff" * ( P"}" + E("} expected") )
  passthrough_debracketed_stuff = C(V"passthrough_bracketed_stuff")
  texlike_command = (
      ( P"\\"-P"\\begin" ) *
      Cg(myID, "command") *
      Cg(parameters,"options") *
      (
        (Cmt(Cb"command", isPassthrough) * V"passthrough_bracketed_stuff") +
        (Cmt(Cb"command", isNotPassThrough) * V"texlike_bracketed_stuff")
      )^0
    ) - P("\\end{")
  environment =
    P"\\begin" *
    Cg(parameters, "options") *
    P"{" *
    Cg(myID, "command") *
    P"}" *
    (
      (Cmt(Cb"command", isPassthrough) * V"passthrough_env_stuff") +
      (Cmt(Cb"command", isNotPassThrough) * V"texlike_stuff")
    ) *
    (
      P"\\end{" *
      (
        Cmt(myID * Cb"command", function (_,_,thisCommand,lastCommand) return thisCommand == lastCommand end) + E"Environment mismatch"
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

local function getline (str, pos)
  start = 1
  lno = 1
  if pos > lastpos then
    lno = linecache[#linecache].lno
    start = linecache[#linecache].pos + 1
    col = 1
  else
    for j = 1,#linecache-1 do
      if linecache[j+1].pos >= pos then
        lno = linecache[j].lno
        col = pos - linecache[j].pos
        return lno,col
      end
    end
  end
  for i = start, pos do
    if string.sub( str, i, i ) == "\n" then
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
    tree.lno, tree.col = getline(doc, tree.pos)
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
  if tree.command then
    if root and tree.command == "document" then
      SILE.inputs.common.init(doc, tree)
    end
    SILE.process(tree)
  elseif pcall(function () assert(load(doc))() end) then
  else
    SU.error("Input not recognized as Lua or SILE content")
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
