local base = require("packages.base")

local package = pl.class(base)
package._name = "infonode"

-- Info nodes are used to store information about what actually ends up on which page.
-- Index terms are an obvious use for this, as well as anything where you wanted to
-- know where something had ended up after the page builder had broken the page.
-- Check out SILE.scratch.info.thispage in your end-of-page routine and see what nodes
-- are there.

local _info = pl.class(SILE.types.node.zerohbox)
_info.type = "info"

function _info:__tostring ()
   return "I<" .. self.category .. "|" .. tostring(self.value) .. ">"
end

function _info:outputYourself ()
   if not SILE.scratch.info.thispage[self.category] then
      SILE.scratch.info.thispage[self.category] = { self.value }
   else
      local i = #SILE.scratch.info.thispage[self.category] + 1
      SILE.scratch.info.thispage[self.category][i] = self.value
   end
end

local function newPageInfo (_)
   SILE.scratch.info = { thispage = {} }
end

local _deprecate = [[
   Directly calling info node handling functions is no longer necessary. All the
   SILE core classes and anything inheriting from them will take care of this
   automatically using hooks. Custom classes that override the class:endPage()
   function may need to handle this in other ways. By calling this hook directly
   you are likely causing it to run twice and duplicate entries.
]]

function package:_init ()
   base._init(self)
   if not SILE.scratch.info then
      SILE.scratch.info = { thispage = {} }
   end
   self.class:registerHook("newpage", newPageInfo)
   self:deprecatedExport("newPageInfo", function ()
      SU.deprecated("class:newPageInfo", nil, "0.13.0", "0.15.0", _deprecate)
   end)
end

function package:registerCommands ()
   self:registerCommand("info", function (options, _)
      SU.required(options, "category", "info node")
      SU.required(options, "value", "info node")
      table.insert(
         SILE.typesetter.state.nodes,
         _info({
            category = options.category,
            value = options.value,
         })
      )
   end, "Inserts an info node onto the current page")
end

package.documentation = [[
\begin{document}
\autodoc:note{This package is only for class designers.}

While typesetting a document, SILE first breaks a paragraph into lines, then arranges lines into a page, and later outputs the page.
In other words, while it is looking at the text of a paragraph, it is not clear what page the text will eventually end up on.
This makes it difficult to produce indexes, tables of contents, and so on, where one needs to know the page number for a particular element.

To get around this problem, the \autodoc:package{infonode} package allows you to insert \em{information nodes} into the text stream; when a page is outputted, these nodes are collected into a list, and a class’s output routine can examine this list to determine which nodes fell on a particular page.
\autodoc:package{infonode} provides the \autodoc:command{\info} command to put an information node into the text stream; it has two required parameters, \autodoc:parameter{category=<name>} and \autodoc:parameter{value=<any object>}.
Categories are used to group similar sets of node together.

As an example, when typesetting a Bible, you may wish to display which range of verses are on each page as a running header.
During the command which starts a new verse, you would insert an information node with the verse reference:

\begin[type=autodoc:codeblock]{raw}
SILE.call("info", { category = "references", value = ref }, {})
\end{raw}

During the \code{endPage} method which is called at the end of every page, we look at the list of “references” information nodes:

\begin[type=autodoc:codeblock]{raw}
local refs = SILE.scratch.info.thispage.references
local runningHead = SILE.shaper.shape(refs[1] .. " - " .. refs[#refs])
SILE.typesetNaturally(rhFrame, runningHead);
\end{raw}
\end{document}
]]

return package
