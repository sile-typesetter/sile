local base = require("packages.base")

local package = pl.class(base)
package._name = "infonode"

-- Info nodes are used to store information about what actually ends up on which page.
-- Index terms are an obvious use for this, as well as anything where you wanted to
-- know where something had ended up after the page builder had broken the page.
-- Check out SILE.scratch.info.thispage in your end-of-page routine and see what nodes
-- are there.

local _info = pl.class(SILE.nodefactory.hbox)

_info.type ="special"
_info.category = ""
_info.value = nil
_info.savepos = false
_info.width = SILE.length()

function _info:__tostring ()
  return "I<" .. self.category .. "|" .. self.value.. ">"
end

function _info:outputYourself (typesetter)
  local item
  if self.savepos then
    item = {
      value = self.value,
      x = typesetter.frame.state.cursorX,
      y = typesetter.frame.state.cursorY,
    }
  else
    item = self.value
  end
  if not SILE.scratch.info.thispage[self.category] then
    if item then
      SILE.scratch.info.thispage[self.category] = {item}
    else
      SILE.scratch.info.thispage[self.category] = {}
    end
  elseif item then
    local i = #(SILE.scratch.info.thispage[self.category]) + 1
    SILE.scratch.info.thispage[self.category][i] = item
  end
end

local function newPageInfo (_)
  SILE.scratch.info = { thispage = {} }
end

local _deprecate  = [[
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
  self:deprecatedExport("newPageInfo", function (class)
    SU.deprecated("class:newPageInfo", nil, "0.13.0", "0.15.0", _deprecate)
    return class:newPageInfo()
  end)
end

function package:registerCommands ()

  self:registerCommand("info", function (options, _)
    SU.required(options, "category", "info node")
    table.insert(SILE.typesetter.state.nodes, _info({
      category = options.category,
      value = options.value,
      savepos = SU.boolean(options.savepos, false),
    }))
  end, "Inserts an info node onto the current page")

end

package.documentation = [[
\begin{document}
\note{This package is only for class designers.}

While typesetting a document, SILE first breaks a paragraph into lines, then arranges lines into a page, and later outputs the page.
In other words, while it is looking at the text of a paragraph, it is not clear what page the text will eventually end up on, or at what position it will be on the page.
This makes it difficult to produce indexes, tables of contents and so on where one needs to know the page number and/or coordinates of a particular element.

To get around this problem, the \autodoc:package{infonode} package allows you to insert \em{information nodes} into the text stream; when a page is outputted, these nodes are collected into a list, and a class’s output routine can examine this list to determine which nodes fell on a particular page.
\autodoc:package{infonode} provides the \autodoc:command{\info} command to put an information node into the text stream; it has three parameters, \autodoc:parameter{category=<name>} (required), \autodoc:parameter{value=<any object>} (optional), and \autodoc:parameter{savepos=<boolean>} (defaults to false).

The information nodes for the current page are made available in the \code{SILE.scratch.info.thispage.<category>} list, grouped by their category.
If \autodoc:parameter{savepos} was set to true for a given node, the list entry for that node is a table containing three keys \code{x}, \code{y}, and \code{value}, where \code{x} and \code{y} are the recorded coordinates of the node on the page and \code{value} is the value attached to the node (if any).
If \autodoc:parameter{savepos} was omitted or set to false, the node’s position is not recorded and its value is added as-is to the list.
If it doesn’t have a value, the list for the node’s category is not extended but is created when missing, so that you can know that a node of a given category was present on the page.

As an example, when typesetting a Bible, you may wish to display which range of verses are on each page as a running header.
During the command which starts a new verse, you would insert an information node with the verse reference:

\begin{verbatim}
\line
SILE.call("info", \{ category = "references", value = ref \}, \{\})
\line
\end{verbatim}

During the \code{endPage} method which is called at the end of every page, we look at the list of “references” information nodes:

\begin{verbatim}
\line
local refs = SILE.scratch.info.thispage.references
local runningHead = SILE.shaper.shape(refs[1] .. " - " .. refs[#refs])
SILE.typesetNaturally(rhFrame, runningHead);
\line
\end{verbatim}
\end{document}
]]

return package
