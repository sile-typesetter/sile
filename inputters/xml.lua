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
  local content, err = lom.parse(doc)
  if content == nil then
    error(err)
  end
  local root = SILE.documentState.documentClass == nil
  if root then
    if content.command ~= "sile" then
      SU.error("This isn't a SILE document!")
    end
    self:classInit(content)
  end
  if SILE.Commands[content.command] then
    SILE.call(content.command, content.options, content)
  else
    SILE.process(content)
  end
  if root and not SILE.preamble then
    SILE.documentState.documentClass:finish()
  end
end

return xml
