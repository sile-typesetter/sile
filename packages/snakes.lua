local snakeGlue = SILE.nodefactory.newGlue({})
snakeGlue.width = SILE.length.parse("0pt plus 100000pt")
snakeGlue.outputYourself =  function (self,typesetter, line)
  local scaledWidth = self.width.length
  if line.ratio and line.ratio < 0 and self.width.shrink > 0 then
    scaledWidth = scaledWidth + self.width.shrink * line.ratio
  elseif line.ratio and line.ratio > 0 and self.width.stretch > 0 then
    scaledWidth = scaledWidth + self.width.stretch * line.ratio
  end
  if scaledWidth <= 12 then return end
  SILE.outputter.drawImage("packages/snake.png", typesetter.frame.state.cursorX, typesetter.frame.state.cursorY-12, scaledWidth,12);
  typesetter.frame:advanceWritingDirection(scaledWidth)
end

SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
SILE.settings.set("document.parindent", SILE.nodefactory.zeroGlue)
SILE.settings.set("document.spaceskip", SILE.length.parse("1spc"))
SILE.settings.set("document.rskip", snakeGlue)