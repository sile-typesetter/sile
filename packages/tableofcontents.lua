-- Table of contents class

-- Exports: The \tableofcontents command
--          The \tocentry command (call this in your sectioning commands)
--          writeToc (call this in finish)
--          moveTocNodes (call this in endPage)

SILE.scratch.tableofcontents = {}

local loadstring = loadstring or load

local moveNodes = function (self)
  local node = SILE.scratch.info.thispage.toc
  if node then
    for i = 1, #node do
      node[i].pageno = SILE.formatCounter(SILE.scratch.counters.folio)
      SILE.scratch.tableofcontents[#(SILE.scratch.tableofcontents)+1] = node[i]
    end
  end
end

local writeToc = function ()
  local contents = "return "..std.string.pickle(SILE.scratch.tableofcontents)
  local tocfile,err = io.open(SILE.masterFilename .. '.toc', "w")
  if not tocfile then return SU.error(err) end
  tocfile:write(contents)
end

SILE.registerCommand("tableofcontents", function (options, content)
  local tocfile,_ = io.open(SILE.masterFilename .. '.toc')
  if not tocfile then
    SILE.call("tableofcontents:notocmessage")
    return
  end
  local doc = tocfile:read("*all")
  local toc = assert(loadstring(doc))()
  SILE.call("tableofcontents:header")
  for i = 1, #toc do
    local item = toc[i]
    SILE.call("tableofcontents:item", {
      level = item.level,
      pageno = item.pageno
    }, item.label)
  end
  SILE.call("tableofcontents:footer")
end)

SILE.registerCommand("tableofcontents:item", function (options, content)
  SILE.settings.temporarily(function ()
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.call("tableofcontents:level" .. options.level .. "item", {}, function ()
      SILE.process(content)
      SILE.call("dotfill")
      SILE.typesetter:typeset(options.pageno)
    end)
  end)
end)

SILE.registerCommand("tocentry", function (options, content)
  SILE.call("info", {
    category = "toc",
    value = {
      label = content,
      level = (options.level or 1)
    }
  })
end)

return {
  exports = { writeToc = writeToc, moveTocNodes = moveNodes },
  init = function (self)
    self:loadPackage("infonode")
    self:loadPackage("leaders")
SILE.doTexlike([[%
\define[command=tableofcontents:title]{}%
\define[command=tableofcontents:notocmessage]{\tableofcontents:headerfont{Rerun SILE to process table of contents!}}%
\define[command=tableofcontents:headerfont]{\font[size=24pt,weight=800]{\process}}%
\define[command=tableofcontents:header]{\par\noindent\tableofcontents:headerfont{\tableofcontents:title}\medskip}%
\define[command=tableofcontents:footer]{}%
\define[command=tableofcontents:level1item]{\bigskip\noindent\font[size=14pt,weight=800]{\process}\medskip}%
\define[command=tableofcontents:level2item]{\noindent\font[size=12pt]{\process}\medskip}%
\define[command=tableofcontents:level3item]{\indent\font[size=10pt]{\process}\smallskip}%
]])

  end
}
