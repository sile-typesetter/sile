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
        width = (SILE.Commands["hbox"]({},content)).width
      }
      SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil
    end)

SILE.registerCommand(tableTag, function(options, content)
  SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)+1] = {}
  local tbl = SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)]
  SILE.settings.temporarily(function ()
    SILE.settings.set("document.parindent", SILE.nodefactory.newGlue("0pt"))
    SILE.settings.set("current.parindent", SILE.nodefactory.newGlue("0pt"))
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
        if not(colwidths[col]) or cell.width > colwidths[col] then
          colwidths[col] = cell.width
        end
      end
    end
    col = col + 1
  until not stuffInThisColumn
  

  -- Now set each row at the given column width
  for row = 1,#tbl do
    for col = 1,#(tbl[row]) do
      cell = tbl[row][col]
      local box = SILE.Commands["vbox"]({width = colwidths[col]}, cell.content)
      box = box.nodes[1]
      box.outputYourself = function(self,typesetter, line)
       for i, n in ipairs(self.nodes) do 
          n:outputYourself(typesetter, self) 
        end
      end
      table.insert(SILE.typesetter.state.nodes, box) -- a vbox on the hbox list!
    end
    SILE.typesetter:leaveHmode()
    SILE.call("smallskip")
  end
  SILE.typesetter:leaveHmode()
  SILE.scratch.simpletable.tables[#(SILE.scratch.simpletable.tables)] = nil
end)

end}