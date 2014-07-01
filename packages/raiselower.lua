SILE.registerCommand("raise", function(options, content)
  local height = options.height or 0
  height = SILE.parseComplexFrameDimension(height,"h")
  SILE.typesetter:pushHbox({ 
    outputYourself= function (self, typesetter, line)
      if (type(typesetter.state.cursorY)) == "table" then typesetter.state.cursorY  =typesetter.state.cursorY.length end      
      typesetter.state.cursorY = typesetter.state.cursorY - height
    end
  });
  SILE.process(content)
  SILE.typesetter:pushHbox({ 
    outputYourself= function (self, typesetter, line)
      if (type(typesetter.state.cursorY)) == "table" then typesetter.state.cursorY  =typesetter.state.cursorY.length end      
      typesetter.state.cursorY = typesetter.state.cursorY + height
    end
  });

end);
