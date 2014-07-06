
SILE.registerCommand("color", function(options, content)
  local color = options.color or "black"
  color = SILE.colorparser(color)
  SILE.typesetter:pushHbox({ 
    outputYourself= function (self, typesetter, line)
      SILE.outputter:setColor(color)
    end
  });
  SILE.process(content)
  SILE.typesetter:pushHbox({ 
    outputYourself= function (self, typesetter, line)
      SILE.outputter:setColor({ r = 0, g =0, b = 0})
    end
  });
end, "Changes the active ink color to the color <color>.");
