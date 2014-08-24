
SILE.registerCommand("table", function(options, content)
  local tbl = {}

  local processIfNot = function(tag, v, cb)
    if type(v) == "table" then
      if v.tag == tag then
        cb(v)
      else
        SILE.Commands[v.tag](v.attr,v)
      end
    else
      SILE.typesetter:typeset(v)
    end
  end

  for _,v in ipairs(content) do
    processIfNot("tr", v, function (tr)
      tbl[#tbl+1] = {}
      for _,v in ipairs(tr) do
        processIfNot("td", v, function (cell)
          local row = tbl[#tbl]
          row[#row+1] = {
            content = cell,
            width = (SILE.Commands["hbox"]({},cell)).width
          }
          SILE.typesetter.state.nodes[#(SILE.typesetter.state.nodes)] = nil
        end)
      end
    end)
  end

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
  end
  SILE.typesetter:leaveHmode()

end)