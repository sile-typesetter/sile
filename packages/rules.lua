SILE.baseClass:loadPackage("raiselower")

SILE.registerCommand("hrule", function(options, content)
  local width = options.width or 0
  local height = options.height or 0
  SILE.typesetter:pushHbox({ 
    width= SILE.length.new({length = SILE.parseComplexFrameDimension(width,"w") }),
    height= SILE.length.new({ length = SILE.parseComplexFrameDimension(height,"h") }),
    depth= 0,
    value= options.src,
    outputYourself= function (self, typesetter, line)
      local scaledWidth = self.width.length
      if line.ratio < 0 and self.width.shrink > 0 then
        scaledWidth = scaledWidth + self.width.shrink * line.ratio
      elseif line.ratio > 0 and self.width.stretch > 0 then
        scaledWidth = scaledWidth + self.width.stretch * line.ratio
      end    
      if (type(typesetter.state.cursorY)) == "table" then typesetter.state.cursorY  =typesetter.state.cursorY.length end
      if (type(typesetter.state.cursorX)) == "table" then typesetter.state.cursorX  =typesetter.state.cursorX.length end

      SILE.outputter.rule(typesetter.state.cursorX, typesetter.state.cursorY-(self.height.length), scaledWidth, self.height.length+self.depth)
      typesetter.state.cursorX = typesetter.state.cursorX + scaledWidth
    end
  });
end);

SILE.registerCommand("underline", function(options, content)
  -- This is very fragile
  local index = #(SILE.typesetter.state.nodes)
  SILE.process(content)
  local l = SILE.length.new()
  for i = index, #(SILE.typesetter.state.nodes) do
    --if SILE.typesetter.state.nodes[i]:isBox() then
      l = l + SILE.typesetter.state.nodes[i].width 
    --end
  end
  local gl = SILE.length.new() - l
  SILE.typesetter:pushGlue({width = gl})
  print(l.length)
  SILE.Commands["lower"]({height = "0.5pt"}, function()
    SILE.Commands["hrule"]({width = l.length, height = "0.5pt"})
  end);
end)