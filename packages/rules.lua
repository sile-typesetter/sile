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
      typesetter.frame:normalize()

      SILE.outputter.rule(typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-(self.height.length), scaledWidth, self.height.length+self.depth)
      typesetter.frame:moveX(scaledWidth)
    end
  });
end, "Creates a line of width <width> and height <height>");

SILE.registerCommand("underline", function(options, content)
  local hbox = SILE.Commands["hbox"]({}, content)
  local gl = SILE.length.new() - hbox.width
  SILE.Commands["lower"]({height = "0.5pt"}, function()
    SILE.Commands["hrule"]({width = gl.length, height = "0.5pt"})
  end);
  SILE.typesetter:pushGlue({width = hbox.width})

end, "Underlines some content (badly)")