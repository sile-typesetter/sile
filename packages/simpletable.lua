
SILE.scratch.simpletable = { tables = {} }
return {
  exports = {},
  init = function (class, args)
    local tableTag = SU.required(args,"tableTag","setting up table class")
    local trTag = SU.required(args,"trTag","setting up table class")
    local tdTag = SU.required(args,"tdTag","setting up table class")

    SILE.registerCommand(trTag, function(options,content)
      local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
      tbl[#tbl+1] = {}
      SILE.process(content)
    end)
    SILE.registerCommand(tdTag, function(options,content)
      local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
      local row = tbl[#tbl]
      row[#row+1] = {
        content = content,
        hbox = SILE.call("hbox", {},content)
      }
      SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil
    end)

SILE.registerCommand(tableTag, function(options, content)
  SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)+1] = {}
  local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    SILE.process(content)
  end)
  SILE.typesetter:leaveHmode()
  -- Look down columns and find largest thing per column
  local colwidths = {}
  local col = 1
  local stuffInThisColumn
  repeat
    stuffInThisColumn = false
    for row = 1,#tbl do
      cell = tbl[row][col]
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
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
    for row = 1,#tbl do
      for col = 1,#(tbl[row]) do
        local hbox = tbl[row][col].hbox
        hbox.width = colwidths[col]
        SILE.typesetter:pushHbox(hbox)
      end
      SILE.typesetter:leaveHmode()
      SILE.call("smallskip")
    end
  end)
  SILE.typesetter:leaveHmode()
  SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)] = nil
end)

end,
  documentation = [[
\begin{document}
This implements (badly) a very simple table formatting class.

It should be called as so:

\begin{verbatim}
myClass:loadPackage("simpletable", \{
 tableTag = "a",
 trTag = "b",
 tdTag = "c"
\})
\end{verbatim}

This will define commands \code{\\a}, \code{\\b} and \code{\\c} which
are equivalent to the \code{<table>, \code{<tr>} and \code{td} tags.

This is not a complete table implementation, and should be replaced by
one which implements the CSS2.1 two-pass table formatting algorithm.
\end{document}
]]
}
