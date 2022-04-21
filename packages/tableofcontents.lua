-- Table of contents class

-- Exports: The \tableofcontents command
--          The \tocentry command (call this in your sectioning commands)
--          writeToc (call this in finish)
--          moveTocNodes (call this in endPage)

SILE.scratch.tableofcontents = {}
local _tableofcontents = {}

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

  if not pl.tablex.deepcompare(SILE.scratch.tableofcontents, _tableofcontents) then
    io.stderr:write("\n! Warning: table of contents has changed, please rerun SILE to update it.")
  end
end

SILE.registerCommand("tableofcontents", function (options, _)
  local depth = SU.cast("integer", options.depth or 3)
  local linking = SU.boolean(options.linking, true)
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
    if item.level <= depth then
      SILE.call("tableofcontents:item", {
        level = item.level,
        pageno = item.pageno,
        number = item.number,
        link = linking and item.link
      }, item.label)
    end
  end
  SILE.call("tableofcontents:footer")
  _tableofcontents = toc
end)

local linkWrapper = function (dest, func)
  if dest and SILE.Commands["pdf:link"] then
    return function()
      SILE.call("pdf:link", { dest = dest }, func)
    end
  else
    return func
  end
end

SILE.registerCommand("tableofcontents:item", function (options, content)
  SILE.settings.temporarily(function ()
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue())
    SILE.call("tableofcontents:level" .. options.level .. "item", {
    }, linkWrapper(options.link,
      function ()
        SILE.call("tableofcontents:level" .. options.level .. "number", {
        }, function ()
          if options.number then
            SILE.typesetter:typeset(options.number or "")
            SILE.call("kern", { width = "1spc" })
          end
        end)
        SILE.process(content)
        SILE.call("dotfill")
        SILE.typesetter:typeset(options.pageno)
      end)
    )
  end)
end)

-- Flatten a node list into just its string representation.
-- (Similar to SU.contentToString(), but allows passing typeset
-- objects to functions that need plain strings).
local nodesToText = function (nodes)
  local string = ""
  for i = 1, #nodes do
    local node = nodes[i]
    if node.is_nnode or node.is_unshaped then
      string = string .. node:toText()
    elseif node.is_glue then
      -- Not so sure about this one...
      if node.width:tonumber() > 0 then
        string = string .. " "
      end
    elseif not (node.is_zerohbox or node.is_migrating) then
      -- Here, typically, the main case is an hbox.
      -- Even if extracting its content could be possible in regular cases
      -- (e.g. \raise), we cannot take a general decision, as it is a versatile
      -- object (e.g. \rebox) and its outputYourself could moreover have been
      -- redefine to do fancy things. Better warn and skip.
      SU.warn("Some content could not be converted to text: "..node)
    end
  end
  return string
end

local dc = 1
SILE.registerCommand("tocentry", function (options, content)
  local dest
  if SILE.Commands["pdf:destination"] then
    dest = "dest" .. dc
    SILE.call("pdf:destination", { name = dest })
    SILE.typesetter:pushState()
    SILE.process(content)
    local title = nodesToText(SILE.typesetter.state.nodes)
    SILE.typesetter:popState()
    SILE.call("pdf:bookmark", { title = title, dest = dest, level = options.level })
    dc = dc + 1
  end
  SILE.call("info", {
    category = "toc",
    value = {
      label = content,
      level = (options.level or 1),
      number = options.number,
      link = dest
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
\define[command=tableofcontents:level1number]{}%
\define[command=tableofcontents:level2number]{}%
\define[command=tableofcontents:level3number]{}%
]])

  end,
  documentation = [[
\begin{document}
The \autodoc:package{tableofcontents} package provides tools for class authors to
create tables of contents. When you are writing sectioning commands such
as \code{\\chapter} or \code{\\section}, your classes should call the
\autodoc:command{\tocentry[level=<number>, number=<strings>]{<title>}}
command to register a table of contents entry.
At the end of each page, the exported Lua function \code{moveTocNodes}
should be called to collate the table of contents
entries and store which page they’re on. At the end of the document,
the \code{writeToc} Lua function writes the table of contents data
to a file. This is because the table of contents (written out with
the \autodoc:command{\tableofcontents} command) is usually found at the
start of a document, before the entries have been processed. Because of
this, documents with a table of contents need to be processed at least
twice—once to collect the entries and work out which pages they’re on,
then to write the table of contents.

The \autodoc:command{\tableofcontents} command accepts a \autodoc:parameter{depth} option to
control the depth of the content added to the table.

If the \autodoc:package{pdf} package is loaded before using sectioning commands,
then a PDF document outline will be generated.
Moreover, entries in the table of contents will be active links to the
relevant sections. To disable the latter behavior, pass \autodoc:parameter{linking=false} to
the \autodoc:command{\tableofcontents} command.

Class designers can also style the table of contents by overriding the
following commands:

\noindent{}• \autodoc:command{\tableofcontents:headerfont} - the font used for the header.

\noindent{}• \autodoc:command{\tableofcontents:level1item}, \autodoc:command{\tableofcontents:level2item}, etc. - styling
for entries.

\noindent{}• \autodoc:command{\tableofcontents:level1number}, \autodoc:command{\tableofcontents:level2number}, etc. - deciding
what to do with entry section number, if defined: by default, nothing (so they do not show
up in the table of contents).

\end{document}
]]
}
