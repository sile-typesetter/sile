SILE.registerCommand("ruby", function (o,c)
  local reading = SU.required(o, "reading", "\\ruby")
  SILE.call("hbox", {}, function()
    SILE.settings.temporarily(function ()
      SILE.call("noindent")
      SILE.call("font", {size = "0.5zw"})
      SILE.typesetter:typeset(reading)
    end)
  end)
  local rubybox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  rubybox.outputYourself = function (self, typesetter, line)
    local ox = typesetter.frame.state.cursorX
    typesetter.frame.state.cursorX = typesetter.frame.state.cursorX + rubybox.width.length / 2
    typesetter.frame:advancePageDirection(-SILE.toPoints("1zw"))
    SILE.outputter.moveTo(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY)
    for i = 1, #(self.value) do local node = self.value[i]
      node:outputYourself(typesetter, line)
    end
    typesetter.frame.state.cursorX = ox
    typesetter.frame:advancePageDirection(SILE.toPoints("1zw"))
  end

  -- measure the content
  SILE.call("hbox", {}, c)
  cbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
  if cbox.width > rubybox.width then
    rubybox.width = cbox.width - rubybox.width
  else
    local to_insert = SILE.length.new({length = (rubybox.width - cbox.width).length / 2, })
    cbox.width = rubybox.width
    rubybox.width = SILE.length.zero
    -- add spaces at beginning and end
    table.insert(cbox.value, 1, SILE.nodefactory.newGlue({ width = to_insert }))
    table.insert(cbox.value, SILE.nodefactory.newGlue({ width = to_insert }))
  end
end)