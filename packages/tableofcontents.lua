-- Table of contents class

-- Exports: The \tableofcontents command
--          The \tocentry command (call this in your sectioning commands)
--          writeToc (call this in finish)
--          moveTocNodes (call this in endPage)

SILE.scratch.tableofcontents = {}

local moveNodes = function (_)
  local node = SILE.scratch.info.thispage.toc
  if node then
    for i = 1, #node do
      node[i].pageno = SILE.formatCounter(SILE.scratch.counters.folio)
      SILE.scratch.tableofcontents[#(SILE.scratch.tableofcontents)+1] = node[i]
    end
  end
end

local writeToc = function ()
  local tocdata = pl.pretty.write(SILE.scratch.tableofcontents)
  local tocfile, err = io.open(SILE.masterFilename .. '.toc', "w")
  if not tocfile then return SU.error(err) end
  tocfile:write("return " .. tocdata)
  tocfile:close()
end

SILE.registerCommand("tableofcontents", function (_, _)
  local tocfile,_ = io.open(SILE.masterFilename .. '.toc')
  if not tocfile then
    SILE.call("tableofcontents:notocmessage")
    return
  end
  local doc = tocfile:read("*all")
  local toc = assert(load(doc))()
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
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
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

SILE.registerCommand("tableofcontents:title", function (_, _)
  local lang = SILE.settings.get("document.language")
  SILE.call("tableofcontents:title:" .. lang)
end)

return {
  exports = { writeToc = writeToc, moveTocNodes = moveNodes },
  init = function (self)
    self:loadPackage("infonode")
    self:loadPackage("leaders")
SILE.doTexlike([[%
\define[command=tableofcontents:notocmessage]{\tableofcontents:headerfont{\fluent{toc-not-generated}}}%
\define[command=tableofcontents:headerfont]{\font[size=24pt,weight=800]{\process}}%
\define[command=tableofcontents:header]{\par\noindent\tableofcontents:headerfont{\fluent{toc-title}}\medskip}%
\define[command=tableofcontents:footer]{}%
\define[command=tableofcontents:level1item]{\bigskip\noindent\font[size=14pt,weight=800]{\process}\medskip}%
\define[command=tableofcontents:level2item]{\noindent\font[size=12pt]{\process}\medskip}%
\define[command=tableofcontents:level3item]{\indent\font[size=10pt]{\process}\smallskip}%
]])

  end,
  documentation = [[
\begin{document}
The \code{tableofcontents} package provides tools for class authors to
create tables of contents. When you are writing sectioning commands such
as \code{\\chapter} or \code{\\section}, your classes should call the
\code{\\tocentry[level=...]\{Entry\}} command to register a table of
contents entry. At the end of each page, the exported Lua function
\code{moveTocNodes} should be called to collate the table of contents
entries and store which page they're on. At the end of the document,
the \code{writeToc} Lua function writes the table of contents data
to a file. This is because the table of contents (written out with
the \code{\\tableofcontents} command) is usually found at the
start of a document, before the entries have been processed. Because of
this, documents with a table of contents need to be processed at least
twice—once to collect the entries and work out which pages they’re on,
then to write the table of contents.

Class designers can also style the table of contents by overriding the
following commands:

\noindent{}• \code{\\tableofcontents:headerfont} - the font used for the header.

\noindent{}• \code{\\tableofcontents:level1item}, \code{\\tableofcontents:level2item}, etc. - styling
for entries.

\end{document}
]]
}
