local base = require("inputters.base")

local epnf = require("epnf")

local inputter = pl.class(base)
inputter._name = "sil"

inputter.order = 50

inputter._grammar = require("inputters.sil-epnf")

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

function inputter:_init ()
  -- Save time when parsing strings by only setting up the grammar once per
  -- instantiation then re-using it on every use.
  self._parser = self:rebuildParser()
  base._init(self)
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
      or tree.id == "braced_content"
      or tree.id == "passthrough_content"
      or tree.id == "braced_passthrough_content"
      or tree.id == "env_passthrough_content"
    then
      return massage_ast(tree[1], doc)
  end
  if tree.id == "text"
    or tree.id == "passthrough_text"
    or tree.id == "env_passthrough_text"
    then
      return tree[1]
  end
  for key, val in ipairs(tree) do
    if val.id == "content" then
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
  local status, result = pcall(epnf.parsestring, self._parser, doc)
  if not status then
    return SU.error(([[Unable to parse input document to an AST tree. Parser error:

%s  thrown from document beginning]]):format(pl.stringx.indent(result, 6)))
  end
  resetCache()
  local top = massage_ast(result[1], doc)
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
