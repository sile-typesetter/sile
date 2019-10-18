SILE.registerCommand("raise", function (options, content)
  local height = options.height or 0
  height = SILE.parseComplexFrameDimension(height)
  SILE.typesetter:pushHbox({
      outputYourself = function (_, typesetter, _)
        typesetter.frame:advancePageDirection(-height)
      end
    })
  SILE.process(content)
  SILE.typesetter:pushHbox({
      outputYourself = function (_, typesetter, _)
        if (type(typesetter.state.cursorY)) == "table" then
          typesetter.state.cursorY = typesetter.state.cursorY.length
        end
        typesetter.frame:advancePageDirection(height)
      end
    })
end, "Raises the contents of the command by the amount specified in the <height> option")

SILE.registerCommand("lower", function (options, content)
  SILE.call("raise", { height = "-" .. options.height }, content)
end, "Lowers the contents of the command by the amount specified in the <height> option")
