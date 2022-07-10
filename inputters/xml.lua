local base = require("inputters.base")

local lom = require("lomwithpos")

local xml = pl.class(base)
xml._name = "xml"

xml.order = 2

function xml.appropriate (round, filename, doc)
  if round == 1 then
    return filename:match(".xml$")
  elseif round == 2 then
    local sniff = doc:sub(1, 100):gsub("begin.*", "") or ""
    local promising = sniff:match("<")
    return promising and xml.appropriate(3, filename, doc)
  elseif round == 3 then
    local _, err = lom.parse(doc)
    return not err
  end
end

function xml:process (doc)
  local tree = self:parse(doc)
  local root = SILE.documentState.documentClass == nil
  if root then
    if tree.command ~= "sile" then
      SU.error("This isn't a SILE document!")
    end
    self:classInit(tree)
  end
  if SILE.Commands[tree.command] then
    SILE.call(tree.command, tree.options, tree)
  else
    SILE.process(tree)
  end
  if root and not SILE.preamble then
    SILE.documentState.documentClass:finish()
  end
end

function xml.parse (_, doc)
  local tree, err = lom.parse(doc)
  if not tree then
    SU.error(err)
  end
  return tree
end

return xml
