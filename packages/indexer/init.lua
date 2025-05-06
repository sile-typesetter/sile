local base = require("packages.base")

local package = pl.class(base)
package._name = "indexer"

if not SILE.scratch.pdf_destination_counter then
   SILE.scratch.pdf_destination_counter = 1
end

--- Check if page p2 is not the same as previous page p1.
-- @tparam table p1 A page counter value or nil (if no previous page yet)
-- @tparam table p2 A page counter value
-- @treturn boolean True if p2 is not the same as p1
local function _isNotSamePage (p1, p2)
   if not p1 then
      return true
   end
   return p1.display ~= p2.display or p1.value ~= p2.value
end

--- Group pages into ranges of consecutive pages.
-- @tparam table pages A list of pages with pageno (counter) and link (internal string) fields
-- @treturn table A list of ranges, each containing a list of pages
local function _groupPageRanges (pages)
   local ret = {}
   for _, page in ipairs(pages) do
      if
         #ret == 0
         or ret[#ret][#ret[#ret]].pageno.display ~= page.pageno.display
         or ret[#ret][#ret[#ret]].pageno.value + 1 ~= page.pageno.value
      then
         table.insert(ret, { page })
      else
         table.insert(ret[#ret], page)
      end
   end
   return ret
end

--- Wrap content in a link if a destination is provided.
-- @tparam string dest The destination name
-- @tparam string page The page number
-- @treturn table The content AST, possibly wrapped in a link
function package:_linkWrapper (dest, page)
   if dest and self.commands:exists("pdf:link") then
      return SU.ast.createCommand("pdf:link", { dest = dest }, page)
   end
   return page
end

--- Add a delimiter between elements of a table.
-- @tparam table t A list of elements
-- @tparam string sep The delimiter
-- @treturn table A new list with the delimiter inserted between elements
local function _addDelimiter (t, sep)
   local ret = {}
   for i = 1, #t - 1 do
      table.insert(ret, t[i])
      table.insert(ret, sep)
   end
   if #t > 0 then
      table.insert(ret, t[#t])
   end
   return ret
end

--- Simplify the second number in an Arabic page range.
-- @tparam string p1 The first page number (assumed to be in Arabic format)
-- @tparam string p2 The second page number (assumed to be in Arabic format)
-- @tparam string format The format to use (either 'minimal' or 'minimal-two')
-- @treturn string The simplified second page number
local function _simplifyArabicInRange (p1, p2, format)
   if #p1 > 1 and #p1 == #p2 then
      local ending = format == "minimal" and 1 or 2
      for i = 1, #p1 - ending do
         if p1:sub(i, i) ~= p2:sub(i, i) then
            return p2:sub(i, -1)
         end
      end
      return p2:sub(#p1 - ending + 1, -1)
   end
   return p2
end

local _indexer_used = false

--- Write the index to a file.
-- This function is called as a hook from the class, not as a method of the package.
function package.writeIndex ()
   local idxdata = pl.pretty.write(SILE.scratch.index)
   local idxfile, err = io.open(pl.path.splitext(SILE.input.filenames[1]) .. ".idx", "w")
   if not idxfile then
      return SU.error(err)
   end
   idxfile:write("return " .. idxdata)
   idxfile:close()
   if _indexer_used and not pl.tablex.deepcompare(SILE.scratch.index, SILE.scratch._index) then
      SU.msg("Notice: the index has changed, please rerun SILE to update it.")
   end
end

--- Read the index from a file.
-- This function is called as a hook from the class, not as a method of the package.
function package.readIndex ()
   if SILE.scratch._index and #SILE.scratch._index > 0 then
      -- already loaded
      return SILE.scratch._index
   end
   local idxfile_name = (pl.path.splitext(SILE.input.filenames[1]) .. ".idx")
   local idxfile, _ = io.open(idxfile_name)
   if not idxfile then
      return false -- No index yet
   end
   local doc = idxfile:read("*all")
   local idx = assert(load(doc), idxfile_name, "r")()
   SILE.scratch._index = idx
   return SILE.scratch._index
end

--- Collect index entries from the current page.
-- This function is called as a hook from the class, not as a method of the package.
function package.buildIndex ()
   local nodes = SILE.scratch.info.thispage.index
   local pageno = pl.tablex.copy(SILE.scratch.counters.folio)
   if not nodes then
      return
   end
   for _, node in ipairs(nodes) do
      if not SILE.scratch.index[node.index] then
         SILE.scratch.index[node.index] = {}
      end
      local index = SILE.scratch.index[node.index]
      if not index[node.label] then
         index[node.label] = {}
      end
      local pages = index[node.label]
      if not #pages or _isNotSamePage(pages[#pages], pageno) then
         table.insert(pages, { pageno = pageno, link = node.link })
      end
   end
end

--- Initialize the package.
-- @tparam table options Configuration options
function package:_init (options)
   base._init(self)
   self.config = pl.tablex.merge({
      ["page-range-format"] = "expanded",
      ["page-range-delimiter"] = "–",
      ["page-delimiter"] = ", ",
      filler = "dotfill",
   }, options, true)
   self:loadPackage("infonode")
   self:loadPackage("leaders")
   self.class:registerHook("endpage", self.buildIndex)
   self.class:registerHook("finish", self.writeIndex)
   if not SILE.scratch.index then
      SILE.scratch.index = {}
   end
end

-- Format a list of pages, collapsing consecutive pages into ranges.
-- @tparam table pages A list of pages with pageno and link fields.
-- @treturn table A list of formatted page ranges.
function package:formatPageRanges (pages)
   local ranges = {}
   for _, range in ipairs(_groupPageRanges(pages)) do
      if #range == 1 then
         table.insert(
            ranges,
            self:_linkWrapper(range[1].link, self.class.packages.counters:formatCounter(range[1].pageno))
         )
      else
         local p1 = self.class.packages.counters:formatCounter(range[1].pageno)
         local p2 = self.class.packages.counters:formatCounter(range[#range].pageno)
         if self.config["page-range-format"] ~= "expanded" and range[1].pageno.display == "arabic" then
            p2 = _simplifyArabicInRange(p1, p2, self.config["page-range-format"])
         end
         table.insert(ranges, {
            self:_linkWrapper(range[1].link, p1),
            self.config["page-range-delimiter"],
            self:_linkWrapper(range[#range].link, p2),
         })
      end
   end
   return _addDelimiter(ranges, self.config["page-delimiter"])
end

-- Format a list of pages.
-- @tparam table pages A list of pages with pageno and link fields.
-- @treturn table A list of formatted pages.
function package:formatPages (pages)
   if self.config["page-range-format"] ~= "none" then
      return self:formatPageRanges(pages)
   end
   local ret = pl.tablex.map(function (page)
      return self:_linkWrapper(page.link, self.class.packages.counters:formatCounter(page.pageno))
   end, pages)
   return _addDelimiter(ret, self.config["page-delimiter"])
end

-- Output an index entry.
-- @tparam table options The index entry options (passed to the style hooks).
-- @tparam table entry The index entry as a SILE AST.
-- @tparam table pages The formatted pages as a SILE AST.
function package:outputIndexEntry (options, entry, pages)
   self.settings:temporarily(function ()
      if self.config.filler ~= "comma" then
         self.settings:set("typesetter.parfillskip", SILE.types.node.glue())
      end
      self.settings:set("current.parindent", SILE.types.node.glue())
      SILE.call("index:entry:style", options, entry)
      if self.config.filler == "dotfill" then
         SILE.call("dotfill")
      elseif self.config.filler == "fill" then
         SILE.call("hss")
      elseif self.config.filler == "comma" then
         SILE.typesetter:typeset(", ")
      else
         SU.error("Unknown filler: " .. self.config.filler)
      end
      SILE.call("index:pages:style", options, pages)
      SILE.call("smallskip")
   end)
end

-- Register the indexer commands.
function package:registerCommands ()
   self.commands:register("indexentry", function (options, content)
      if not options.label then
         -- Reconstruct the text from the content tree
         options.label = SILE.typesetter:contentToText(content)
      end
      if not options.index then
         options.index = "main"
      end
      local dest
      if self.commands:exists("pdf:destination") then
         dest = "dest" .. tostring(SILE.scratch.pdf_destination_counter)
         SILE.call("pdf:destination", { name = dest })
         SILE.scratch.pdf_destination_counter = SILE.scratch.pdf_destination_counter + 1
      end
      SILE.call("info", {
         category = "index",
         value = {
            index = options.index,
            label = options.label,
            link = dest,
         },
      })
   end, "Add an entry to the index")

   self.commands:register("printindex", function (options, _)
      _indexer_used = true
      local idx = self:readIndex()
      if idx == false then
         SU.warn("The index is not available yet, rerun SILE to generate it")
         return
      end
      if not options.index then
         options.index = "main"
      end
      local index = idx[options.index]
      if not index then
         -- Either the index is not up-to-date (and we should rerun SILE), or it does not exist at all.
         SU.warn("Index '" .. options.index .. "' does not exist, rerun SILE or check the index name")
         return
      end
      local sortedIndex = {}
      for n in pairs(index) do
         table.insert(sortedIndex, n)
      end
      SU.collatedSort(sortedIndex)
      SILE.call("bigskip")
      for _, entry in ipairs(sortedIndex) do
         local pages = self:formatPages(index[entry])
         self:outputIndexEntry({ index = options.index }, { entry }, pages)
      end
   end, "Print the index")

   -- Hooks for styling the index
   self.commands:register("index:entry:style", function (_, content)
      SILE.process(content)
   end, "Hook for styling an index entry")

   self.commands:register("index:pages:style", function (_, content)
      SILE.process(content)
   end, "Hook for styling index pages")
end

package.documentation = [[
\begin{document}
The \autodoc:package{indexer} package provides a way to create indexex of terms in a document.
An index functions similarly to a table of contents but organizes entries alphabetically by the indexed terms.
The sorting order is based on the conventions of the current language.

The package accepts several configuration options:
\begin{itemize}
\item{\autodoc:parameter{page-range-format}: The format used to display page ranges for arabic numbers.
Possible values are:
\begin{itemize}
\item{\code{none}: All numbers are displayed, without page range collapsing.}
\item{\code{expanded} (default): All digits are displayed in a page range: 42–45, 321–328, 2787–2816.}
\item{\code{minimal}: All digits repeated in the second number are left out in a page range: 42–5, 321–8, 2787–816.}
\item{\code{minimal-two}: As \code{minimal}, but at least two digits are kept in the second number when it has two or more digits long: 42–45, 321–28, 2787–816.}
\end{itemize}}
\item{\autodoc:parameter{page-range-delimiter}: The delimiter between the start and end of a page range.}
\item{\autodoc:parameter{page-delimiter}: The delimiter between pages.}
\item{\autodoc:parameter{filler}: The filler between the index item and the page number. Possible values are:
\begin{itemize}
\item{\code{dotfill} (default): Fill with dots (leaders).}
\item{\code{fill}: Fill with a stretchable space.}
\item{\code{comma}: Use a comma, and page numbers are not flushed to the end of the line.}
\end{itemize}}
\end{itemize}

The package provides the \autodoc:command{\indexentry} command, which can be called as either \autodoc:command{\indexentry[label=<text>]} or \autodoc:command{\indexentry{<text>}}.
Index entries are gathered and collated at the end of each page, tracking their page numbers.

The \autodoc:command{\printindex} command outputs the collected entries as a formatted list.
Since page numbers are finalized after rendering, the index appears on the second pass.
If the index occurs early and affects pagination, a third pass may be needed for accuracy.

Multiple indexes are available and an index can be selected by passing the \autodoc:parameter{index=<name>} parameter to \autodoc:command{\indexentry} and \autodoc:command{\printindex}.

If the \autodoc:package{pdf} package is loaded, then pages in the index will be hyperlinked to the relevant references.

The following commands just process their content by default, but can be overridden to style the index at your convenience:
\begin{itemize}
\item{\autodoc:command{\index:entry:style}: Hook for styling the index entry.}
\item{\autodoc:command{\index:pages:style}: Hook for styling the page numbers.}
\end{itemize}
When called, they are being passed, as parameters, the index name and the content to be styled.

\end{document}
]]

return package
