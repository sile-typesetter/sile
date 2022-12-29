local base = require("inputters.base")

local epnf = require("epnf")

local inputter = pl.class(base)
inputter._name = "sil"

inputter.order = 50

inputter.appropriate = function (round, filename, doc)
  if round == 1 then
    return filename:match(".sil$")
  elseif round == 2 then
    local sniff = doc:sub(1, 100)
    local promising = sniff:match("\\begin") or sniff:match("\\document") or sniff:match("\\sile")
    return promising and inputter.appropriate(3, filename, doc) or false
  elseif round == 3 then
    local _parser = epnf.define(inputter._grammar)
    local status, _ = pcall(epnf.parsestring, _parser, doc)
    return status
  end
end

local bits = SILE.parserBits


inputter.passthroughCommands = {
  ftl = true,
  lua = true,
  math = true,
  raw = true,
  script = true,
  sil = true,
  use = true,
  xml = true
}

function inputter:_init ()
  -- Save time when parsing strings by only setting up the grammar once per
  -- instantiation then re-using it on every use.
  self._parser = self:rebuildParser()
  base._init(self)
end

-- luacheck: push ignore
---@diagnostic disable: undefined-global, unused-local, lowercase-global
function inputter._grammar (_ENV)
  local isPassthrough = function (_, _, command)
    return inputter.passthroughCommands[command] or false
  end
  local isNotPassthrough = function (...)
    return not isPassthrough(...)
  end
  local isMatchingEndEnv = function (a, b, thisCommand, lastCommand)
    return thisCommand == lastCommand
  end
  local _ = WS^0
  local eol = S"\r\n"
  local specials = S"{}%\\"
  local escaped_specials = P"\\" * specials
  local unescapeSpecials = function (str)
    return str:gsub('\\([{}%%\\])', '%1')
  end
  local myID = C(bits.silidentifier) / 1
  local cmdID = myID - P"beign" - P"end"
  local wrapper = function (a) return type(a)=="table" and a or {} end
  local parameters = (P"[" * bits.parameters * P"]")^-1 / wrapper
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
      V"texlike_braced_stuff" +
      V"texlike_command"
    )^0
  passthrough_stuff = C(Cg(
      V"passthrough_text" +
      V"passthrough_debraced_stuff"
    )^0)
  passthrough_env_stuff = Cg(
      V"passthrough_env_text"
    )^0
  texlike_text = C((1 - specials + escaped_specials)^1) / unescapeSpecials
  passthrough_text = C((1-S("{}"))^1)
  passthrough_env_text = C((1 - (P"\\end{" * Cmt(cmdID * Cb"command", isMatchingEndEnv) * P"}"))^1)
  texlike_braced_stuff = P"{" * V"texlike_stuff" * ( P"}" + E("} expected") )
  passthrough_braced_stuff = P"{" * V"passthrough_stuff" * ( P"}" + E("} expected") )
  passthrough_debraced_stuff = C(V"passthrough_braced_stuff")
  texlike_command = (
      P"\\" *
      Cg(cmdID, "command") *
      Cg(parameters, "options") *
      (
        (Cmt(Cb"command", isPassthrough) * V"passthrough_braced_stuff") +
        (Cmt(Cb"command", isNotPassthrough) * V"texlike_braced_stuff")
      )^0
    )
  local notpass_end =
      P"\\end{" *
      ( Cmt(cmdID * Cb"command", isMatchingEndEnv) + E"Environment mismatch") *
      ( P"}" * _ ) + E"Environment begun but never ended"
  local pass_end =
      P"\\end{" *
      ( cmdID * Cb"command" ) *
      ( P"}" * _ ) + E"Environment begun but never ended"
  environment =
    P"\\begin" *
    Cg(parameters, "options") *
    P"{" *
    Cg(cmdID, "command") *
    P"}" *
    (
      (Cmt(Cb"command", isPassthrough) * V"passthrough_env_stuff" * pass_end) +
      (Cmt(Cb"command", isNotPassthrough) * V"texlike_stuff" * notpass_end)
    )
end
-- luacheck: pop
---@diagnostic enable: undefined-global, unused-local, lowercase-global

local linecache = {}
local lno, col, lastpos
local function resetCache ()
  lno = 1
  col = 1
  lastpos = 0
  linecache = { { lno = 1, pos = 1} }
end

local function getline (str, pos)
  local start = 1
  lno = 1
  if pos > lastpos then
    lno = linecache[#linecache].lno
    start = linecache[#linecache].pos + 1
    col = 1
  else
    for j = 1, #linecache-1 do
      if linecache[j+1].pos >= pos then
        lno = linecache[j].lno
        col = pos - linecache[j].pos
        return lno, col
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
      or tree.id == "texlike_braced_stuff"
      or tree.id == "passthrough_stuff"
      or tree.id == "passthrough_braced_stuff"
      or tree.id == "passthrough_env_stuff"
    then
      return massage_ast(tree[1], doc)
  end
  if tree.id == "texlike_text"
    or tree.id == "passthrough_text"
    or tree.id == "passthrough_env_text"
    then
      return tree[1]
  end
  for key, val in ipairs(tree) do
    if val.id == "texlike_stuff" then
      SU.splice(tree, key, key, massage_ast(val, doc))
    else
      tree[key] = massage_ast(val, doc)
    end
  end
  return tree
end

function inputter:rebuildParser ()
  return epnf.define(self._grammar)
end

function inputter:parse (doc)
  local parsed = epnf.parsestring(self._parser, doc)[1]
  if not parsed then
    return SU.error("Unable to parse input document to an AST tree")
  end
  resetCache()
  local top = massage_ast(parsed, doc)
  local tree
  -- Content not part of a tagged command could either be part of a document
  -- fragment or junk (e.g. comments, whitespace) outside of a document tag. We
  -- need to either capture the document tag only or decide this is a fragment
  -- and wrap it in a document tag.
  for _, leaf in ipairs(top) do
    if leaf.command and (leaf.command == "document" or leaf.command == "sile") then
        tree = leaf
        break
    end
  end
  -- In the event we didn't isolate a top level document tag above, assume this
  -- is a fragment and wrap it in one.
  if not tree then
    tree = { top, command = "document" }
  end
  return { tree }
end

return inputter
