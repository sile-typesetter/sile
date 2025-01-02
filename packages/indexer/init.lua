local base = require("packages.base")

local package = pl.class(base)
package._name = "indexer"

local function isNotSamePage (p1, p2)
   if not p1 then
      return true
   end
   return p1.display ~= p2.display or p1.value ~= p2.value
end

local function groupPageRanges(pages)
   local ret = {}
   for _, page in ipairs(pages) do
      if #ret == 0
         or ret[#ret][#ret[#ret]].display ~= page.display
         or ret[#ret][#ret[#ret]].value + 1 ~= page.value
      then
         table.insert(ret, { page })
      else
         table.insert(ret[#ret], page)
      end
   end
   return ret
end

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
      if not #pages or isNotSamePage(pages[#pages], pageno) then
         table.insert(pages, pageno)
      end
   end
end

function package:_init (options)
   base._init(self)
   self.config = pl.tablex.merge({
      ["page-range-format"] = "expanded",
      ["page-range-delimiter"] = "–",
      ["page-delimiter"] = ", "
   }, options, true)
   self:loadPackage("infonode")
   self.class:registerHook("endpage", self.buildIndex)
   if not SILE.scratch.index then
      SILE.scratch.index = {}
   end
end

function package:formatPageRanges (pages)
   local ranges = {}
   for _, range in ipairs(groupPageRanges(pages)) do
      if #range == 1 then
         table.insert(ranges, self.class.packages.counters:formatCounter(range[1]))
      else
         table.insert(ranges,
            self.class.packages.counters:formatCounter(range[1])
               .. self.config['page-range-delimiter']
               .. self.class.packages.counters:formatCounter(range[#range]))
      end
   end
   return table.concat(ranges, self.config['page-delimiter'])
end

function package:formatPages (pages)
   if self.config['page-range-format'] ~= 'none' then
      return self:formatPageRanges(pages)
   end
   local ret = pl.tablex.map(function (page)
      return self.class.packages.counters:formatCounter(page)
   end, pages)
   return table.concat(ret, self.config['page-delimiter'])
end

function package:registerCommands ()
   self:registerCommand("indexentry", function (options, content)
      if not options.label then
         -- Reconstruct the text.
         SILE.typesetter:pushState()
         SILE.process(content)
         local text = ""
         local nl = SILE.typesetter.state.nodes
         for i = 2, #nl do
            text = text .. nl[i]:toText()
         end
         options.label = text
         SILE.typesetter:popState()
      end
      if not options.index then
         options.index = "main"
      end
      SILE.call("info", { category = "index", value = { index = options.index, label = options.label } })
   end)

   self:registerCommand("printindex", function (options, _)
      if not options.index then
         options.index = "main"
      end
      local index = SILE.scratch.index[options.index]
      local sortedIndex = {}
      for n in pairs(index) do
         table.insert(sortedIndex, n)
      end
      SU.collatedSort(sortedIndex)
      SILE.call("bigskip")
      for _, k in ipairs(sortedIndex) do
         local pageno = self:formatPages(index[k])
         SILE.call("index:item", { pageno = pageno }, { k })
      end
   end)

   self:registerCommand("index:item", function (options, content)
      SILE.settings:temporarily(function ()
         SILE.settings:set("typesetter.parfillskip", SILE.types.node.glue())
         SILE.settings:set("current.parindent", SILE.types.node.glue())
         SILE.call("code", {}, content)
         -- Ideally, leaders
         SILE.call("hss")
         SILE.typesetter:typeset(options.pageno)
         SILE.call("smallskip")
      end)
   end)
end

package.documentation = [[
\begin{document}
An index is essentially the same thing as a table of contents, but sorted.

The package accepts several configuration options:
\begin{itemize}
\item{\autodoc:parameter{page-range-format}: The format used to display page ranges.
Possible values are \autodoc:parameter{expanded} (default), \autodoc:parameter{none}.}
\item{\autodoc:parameter{page-range-delimiter}: The delimiter between the start and end of a page range.}
\item{\autodoc:parameter{page-delimiter}: The delimiter between pages.}
\end{itemize}

This package provides the \autodoc:command{\indexentry} command, which can be called as either \autodoc:command{\indexentry[label=<text>]} or \autodoc:command{\indexentry{<text>}} (so that it can be called from a macro).
Index entries are collated at the end of each page, and the command \autodoc:command{\printindex} will deposit them in a list.
The entry can be styled using the \autodoc:command{\index:item} command.

Multiple indexes are available and an index can be selected by passing the \autodoc:parameter{index=<name>} parameter to \autodoc:command{\indexentry} and \autodoc:command{\printindex}.

\end{document}
]]

return package
