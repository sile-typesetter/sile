SILE.inputs.XML = {
  order = 1,
  appropriate = function(filename, sniff)
    return (filename:match("xml$") or sniff:match("<"))
  end,
  process = function (doc)
    local lom = require("lomwithpos")
    local content, err = lom.parse(doc)
    if content == nil then
      error(err)
    end
    local root = SILE.documentState.documentClass == nil
    if root then
      if not(content.tag == "sile") then
        SU.error("This isn't a SILE document!")
      end
      SILE.inputs.common.init(doc, content)
    end
    if SILE.Commands[content.tag] then
      SILE.call(content.tag, content.attr, content)
    else
      SILE.process(content)
    end
    if root and not SILE.preamble then
      SILE.documentState.documentClass:finish()
    end
  end,
}
