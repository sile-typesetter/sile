local base = require("inputters.base")
local xml = pl.class(base)
xml._name = "xml"

xml.order = 1

function xml.appropriate (filename, sniff)
  return filename:match("xml$") or sniff:match("<")
end

function xml:process (doc)
  local lom = require("lomwithpos")
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
