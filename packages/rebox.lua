SILE.registerCommand("rebox", function (options, content)
  local box = SILE.call("hbox", {}, content)
  if options.width then box.width = SILE.length.make(options.width) end
  if options.height then box.height = SILE.length.make(options.height) end
  if options.depth then box.depth = SILE.length.make(options.depth) end
  if options.phantom then
    box.outputYourself = function (self, typesetter, line)
      typesetter.frame:advanceWritingDirection(self:scaledWidth(line))
    end
  end
  table.insert(SILE.typesetter.state.nodes, box)
end, "Place the output within a box of specified width, height, depth and visibility")
