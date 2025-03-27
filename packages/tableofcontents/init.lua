local base = require("packages.base")

local package = pl.class(base)
package._name = "tableofcontents"

if not SILE.scratch._tableofcontents then
   SILE.scratch._tableofcontents = {}
end

local toc_used = false

function package:moveTocNodes ()
   local node = SILE.scratch.info.thispage.toc
   if node then
      for i = 1, #node do
         node[i].pageno = self.packages.counters:formatCounter(SILE.scratch.counters.folio)
         table.insert(SILE.scratch.tableofcontents, node[i])
      end
   end
end

function package.writeToc (_)
   local tocdata = pl.pretty.write(SILE.scratch.tableofcontents)
   local tocfile, err = io.open(pl.path.splitext(SILE.input.filenames[1]) .. ".toc", "w")
   if not tocfile then
      return SU.error(err)
   end
   tocfile:write("return " .. tocdata)
   tocfile:close()

   if toc_used and not pl.tablex.deepcompare(SILE.scratch.tableofcontents, SILE.scratch._tableofcontents) then
      SU.msg("Notice: the table of contents has changed, please rerun SILE to update it.")
   end
end

function package.readToc (_)
   if SILE.scratch._tableofcontents and #SILE.scratch._tableofcontents > 0 then
      -- already loaded
      return SILE.scratch._tableofcontents
   end
   local tocfile_name = (pl.path.splitext(SILE.input.filenames[1]) .. ".toc")
   local tocfile, _ = io.open(tocfile_name)
   if not tocfile then
      return false -- No TOC yet
   end
   local doc = tocfile:read("*all")
   local toc = assert(load(doc), tocfile_name, "r")()
   SILE.scratch._tableofcontents = toc
   return SILE.scratch._tableofcontents
end

local function _linkWrapper (dest, func)
   if dest and SILE.Commands["pdf:link"] then
      return function ()
         SILE.call("pdf:link", { dest = dest }, func)
      end
   else
      return func
   end
end

if not SILE.scratch.pdf_destination_counter then
   SILE.scratch.pdf_destination_counter = 1
end

function package:_init ()
   base._init(self)
   if not SILE.scratch.tableofcontents then
      SILE.scratch.tableofcontents = {}
   end
   self:loadPackage("infonode")
   self:loadPackage("leaders")
   self.class:registerHook("endpage", self.moveTocNodes)
   self.class:registerHook("finish", self.writeToc)
end

function package:registerCommands ()
   self:registerCommand("tableofcontents", function (options, _)
      local depth = SU.cast("integer", options.depth or 3)
      local linking = SU.boolean(options.linking, true)
      toc_used = true
      local toc = self:readToc()
      if toc == false then
         SILE.call("tableofcontents:notocmessage")
         return
      end
      SILE.call("tableofcontents:header")
      for i = 1, #toc do
         local item = toc[i]
         if item.level <= depth then
            SILE.call("tableofcontents:item", {
               level = item.level,
               pageno = item.pageno,
               number = item.number,
               link = linking and item.link,
            }, item.label)
         end
      end
      SILE.call("tableofcontents:footer")
   end)

   self:registerCommand("tableofcontents:item", function (options, content)
      SILE.settings:temporarily(function ()
         SILE.settings:set("typesetter.parfillskip", SILE.types.node.glue())
         SILE.call(
            "tableofcontents:level" .. options.level .. "item",
            {},
            _linkWrapper(options.link, function ()
               SILE.call("tableofcontents:level" .. options.level .. "number", {}, function ()
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

   self:registerCommand("tocentry", function (options, content)
      local dest
      if SILE.Commands["pdf:destination"] then
         dest = "dest" .. tostring(SILE.scratch.pdf_destination_counter)
         SILE.call("pdf:destination", { name = dest })
         -- Reconstruct a textual representation of the content tree
         local title = SILE.typesetter:contentToText(content)
         SILE.call("pdf:bookmark", { title = title, dest = dest, level = options.level })
         SILE.scratch.pdf_destination_counter = SILE.scratch.pdf_destination_counter + 1
      end
      SILE.call("info", {
         category = "toc",
         value = {
            label = SU.ast.stripContentPos(content),
            level = (options.level or 1),
            number = options.number,
            link = dest,
         },
      })
   end)

   self:registerCommand("tableofcontents:notocmessage", function (_, _)
      SILE.call("tableofcontents:headerfont", {}, function ()
         SILE.call("fluent", {}, { "tableofcontents-not-generated" })
      end)
   end)

   self:registerCommand("tableofcontents:headerfont", function (_, content)
      SILE.call("font", { size = 24, weight = 800 }, content)
   end)

   self:registerCommand("tableofcontents:header", function (_, _)
      SILE.call("par")
      SILE.call("noindent")
      SILE.call("tableofcontents:headerfont", {}, function ()
         SILE.call("fluent", {}, { "tableofcontents-title" })
      end)
      SILE.call("medskip")
   end)

   self:registerCommand("tableofcontents:footer", function (_, _) end)

   self:registerCommand("tableofcontents:level1item", function (_, content)
      SILE.call("bigskip")
      SILE.call("noindent")
      SILE.call("font", { size = 14, weight = 800 }, content)
      SILE.call("medskip")
   end)

   self:registerCommand("tableofcontents:level2item", function (_, content)
      SILE.call("noindent")
      SILE.call("font", { size = 12 }, content)
      SILE.call("medskip")
   end)

   self:registerCommand("tableofcontents:level3item", function (_, content)
      SILE.call("indent")
      SILE.call("font", { size = 10 }, content)
      SILE.call("smallskip")
   end)

   self:registerCommand("tableofcontents:level1number", function (_, _) end)

   self:registerCommand("tableofcontents:level2number", function (_, _) end)

   self:registerCommand("tableofcontents:level3number", function (_, _) end)
end

package.documentation = [[
\begin{document}
The \autodoc:package{tableofcontents} package provides tools for class authors to
create tables of contents (TOCs). When you are writing sectioning commands such
as \autodoc:command[check=false]{\chapter} or \autodoc:command[check=false]{\section}, your classes should call the
\autodoc:command{\tocentry[level=<number>, number=<strings>]{<title>}}
command to register a table of contents entry.
At the end of each page the class will call a hook function (\code{moveTocNodes}) that collates the table of contents entries from that pages and records which page they’re on.
At the end of the document another hook function (\code{writeToc}) will write this data to a file.
The next time the document is built, any use of the \autodoc:command{\tableofcontents} (typically near the beginning of a document) will be able to read that index data and output the TOC.
Because the toc entry and page data is not available until after rendering the document,
the TOC will not render until at least the second pass.
If by chance rendering the TOC itself changes the document pagination (e.g., the TOC spans more than one page) it will be necessary to run SILE a third time to get accurate page numbers shown in the TOC.

The \autodoc:command{\tableofcontents} command accepts a \autodoc:parameter{depth} option to
control the depth of the content added to the table.

If the \autodoc:package{pdf} package is loaded before using sectioning commands,
then a PDF document outline will be generated.
Moreover, entries in the table of contents will be active links to the
relevant sections. To disable the latter behavior, pass \autodoc:parameter{linking=false} to
the \autodoc:command{\tableofcontents} command.

Class designers can also style the table of contents by overriding the
following commands:

\begin{itemize}
\item{\autodoc:command{\tableofcontents:headerfont}: The font used for the header.}
\item{\autodoc:command{\tableofcontents:level1item}, \autodoc:command{\tableofcontents:level2item},
      etc.: Styling for entries.}
\item{\autodoc:command{\tableofcontents:level1number}, \autodoc:command{\tableofcontents:level2number},
      etc.: Deciding what to do with entry section number, if defined: by default, nothing (so they
      do not show up in the table of contents).}
\end{itemize}

\end{document}
]]

return package
