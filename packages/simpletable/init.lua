local base = require("packages.base")

local package = pl.class(base)
package._name = "simpletable"

local tableTag, trTag, tdTag

function package:_init (options)
  base._init(self, options)

  if not SILE.scratch.simpletable then
    SILE.scratch.simpletable = { tables = {} }
  end

  if type(options) ~= "table" or pl.tablex.size(options) < 3 then
    options = {
      tableTag = "table",
      trTag = "tr",
      tdTag = "td"
    }
  end

  tableTag = SU.required(options, "tableTag", "setting up table class")
  trTag = SU.required(options, "trTag", "setting up table class")
  tdTag = SU.required(options, "tdTag", "setting up table class")

  -- This is a post init calback instead of the usual early command registration
  -- method using our package loader because we don't know what commands to register
  -- until we've been instantiated.
  self.class:registerPostinit(function (_)

    self:registerCommand(trTag, function(_, content)
      local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
      tbl[#tbl+1] = {}
      SILE.process(content)
    end)

    self:registerCommand(tdTag, function(_, content)
      local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
      local row = tbl[#tbl]
      row[#row+1] = {
        content = content,
        hbox = SILE.call("hbox", {}, content)
      }
      SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil
    end)

    self:registerCommand(tableTag, function(_, content)
      local tbl = {}
      table.insert(SILE.scratch.simpletable.tables, tbl)
      SILE.settings:temporarily(function ()
        SILE.settings:set("document.parindent", SILE.nodefactory.glue())
        SILE.process(content)
      end)
      SILE.typesetter:leaveHmode()
      -- Look down columns and find largest thing per column
      local colwidths = {}
      local col = 1
      local stuffInThisColumn
      repeat
        stuffInThisColumn = false
        for row = 1, #tbl do
          local cell = tbl[row][col]
          if cell then
            stuffInThisColumn = true
            if not(colwidths[col]) or cell.hbox.width > colwidths[col] then
              colwidths[col] = cell.hbox.width
            end
          end
        end
        col = col + 1
      until not stuffInThisColumn
      -- Now set each row at the given column width
      SILE.settings:temporarily(function ()
        SILE.settings:set("document.parindent", SILE.nodefactory.glue())
        for row = 1, #tbl do
          for colno = 1, #(tbl[row]) do
            local hbox = tbl[row][colno].hbox
            hbox.width = colwidths[colno]
            SILE.typesetter:pushHbox(hbox)
          end
          SILE.typesetter:leaveHmode()
          SILE.call("smallskip")
        end
      end)
      SILE.typesetter:leaveHmode()
      table.remove(SILE.scratch.simpletable.tables)
    end)

  end)

end

package.documentation = [[
\begin{document}
This implements (badly) a very simple table formatting class.

It should be called as so:

\begin[type=autodoc:codeblock]{raw}
myclass:loadpackage("simpletable", {
 tabletag = "a",
 trtag = "b",
 tdtag = "c"
})
\end{raw}

This will define commands \code{\\a}, \code{\\b} and \code{\\c} which are equivalent to the \code{<table>, \code{<tr>} and \code{<td>} tags.

This is not a complete table implementation, and should be replaced by one which implements the css2.1 two-pass table formatting algorithm.
\end{document}
]]

return package
