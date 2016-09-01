
SILE.registerCommand("raise", function(options, content)
  local height = options.height or 0
  height = SILE.parseComplexFrameDimension(height,"h")
  SILE.typesetter:pushHbox({
    outputYourself= function (self, typesetter, line)
      typesetter.frame:advancePageDirection(-height)
    end
  })
  SILE.process(content)
  SILE.typesetter:pushHbox({
    outputYourself= function (self, typesetter, line)
      if (type(typesetter.state.cursorY)) == "table" then typesetter.state.cursorY  =typesetter.state.cursorY.length end
      typesetter.frame:advancePageDirection(height)
    end
  })
end, "Raises the contents of the command by the amount specified in the <height> option")

SILE.registerCommand("lower", function (options, content)
  SILE.Commands["raise"]({height = "-"..options.height}, content)
end, "Lowers the contents of the command by the amount specified in the <height> option")
