-- A very simple table formatting class

-- Calling conventions:
-- myClass:loadPackage("simpletable", {
--  tableTag = "a",
--  trTag = "b",
--  tdTag = "c"
-- })

-- Defines commands \a, \b and \c equivalent to HTML
-- <table>, <tr> and <td> tags.

-- Todo: Set a maximum width for the whole table and ensure
-- vbox width is no greater than this. In fact, we should use
-- the complete CSS2.1 two-pass table layout algorithm.

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

end}
